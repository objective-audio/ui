//
//  yas_ui_mesh.mm
//

#include "yas_each_index.h"
#include "yas_objc_ptr.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_batch_render_mesh_info.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

#pragma mark - ui::mesh::impl

struct ui::mesh::impl : base::impl, renderable_mesh::impl, metal_object::impl {
    impl() {
        _updates.flags.set();
    }

    ui::setup_metal_result metal_setup(id<MTLDevice> const device) override {
        if (_mesh_data) {
            return _mesh_data.metal().metal_setup(device);
        }
        return ui::setup_metal_result{nullptr};
    }

    simd::float4x4 const &matrix() override {
        return _matrix;
    }

    void set_matrix(simd::float4x4 &&matrix) override {
        _matrix = std::move(matrix);
    }

    std::size_t render_vertex_count() override {
        if (is_rendering_color_exists()) {
            return _mesh_data.vertex_count();
        }
        return 0;
    }

    std::size_t render_index_count() override {
        if (is_rendering_color_exists()) {
            return _mesh_data.index_count();
        }
        return 0;
    }

    ui::mesh_updates_t const &updates() override {
        return _updates;
    }

    void metal_render(ui::renderer_base &renderer, id<MTLRenderCommandEncoder> const encoder,
                      ui::metal_encode_info const &encode_info) override {
        if (!_ready_render()) {
            return;
        }

        auto &renderable_mesh_data = _mesh_data.renderable();
        auto const vertex_buffer_byte_offset = renderable_mesh_data.vertex_buffer_byte_offset();
        auto const index_buffer_byte_offset = renderable_mesh_data.index_buffer_byte_offset();
        auto constant_buffer_offset = renderer.constant_buffer_offset();
        auto currentConstantBuffer = renderer.currentConstantBuffer();

        auto constant_ptr = (uint8_t *)[currentConstantBuffer contents];
        auto uniforms_ptr = (uniforms2d_t *)(&constant_ptr[constant_buffer_offset]);
        uniforms_ptr->matrix = _matrix;
        uniforms_ptr->color = _color;
        uniforms_ptr->use_mesh_color = _use_mesh_color;

        if (_texture) {
            [encoder setFragmentBuffer:currentConstantBuffer offset:constant_buffer_offset atIndex:0];
            [encoder setRenderPipelineState:encode_info.pipelineState()];
            [encoder setFragmentTexture:_texture.mtlTexture() atIndex:0];
            [encoder setFragmentSamplerState:_texture.sampler() atIndex:0];
        } else {
            [encoder setRenderPipelineState:encode_info.pipelineStateWithoutTexture()];
        }

        [encoder setVertexBuffer:renderable_mesh_data.vertexBuffer() offset:vertex_buffer_byte_offset atIndex:0];
        [encoder setVertexBuffer:currentConstantBuffer offset:constant_buffer_offset atIndex:1];

        constant_buffer_offset += sizeof(uniforms2d_t);

        [encoder drawIndexedPrimitives:to_mtl_primitive_type(_primitive_type)
                            indexCount:_mesh_data.index_count()
                             indexType:MTLIndexTypeUInt32
                           indexBuffer:renderable_mesh_data.indexBuffer()
                     indexBufferOffset:index_buffer_byte_offset];

        renderer.set_constant_buffer_offset(constant_buffer_offset);
    }

    void batch_render(ui::batch_render_mesh_info &mesh_info, ui::batch_building_type const building_type) override {
        if (!_ready_render()) {
            return;
        }

        ui::mesh_data_updates_t mesh_data_updates;
        if (_mesh_data) {
            mesh_data_updates = _mesh_data.renderable().updates();
        }

        if (_needs_write_for_batch_render(_updates, mesh_data_updates, building_type)) {
            mesh_info.mesh_data.write([
                    &src_mesh_data = _mesh_data,
                    &matrix = _matrix,
                    &color = _color,
                    is_use_mesh_color = _use_mesh_color,
                    &mesh_info
            ](auto &vertices, auto &indices) {
                auto const dst_index_offset = static_cast<index2d_t>(mesh_info.index_idx);
                auto const dst_vertex_offset = static_cast<index2d_t>(mesh_info.vertex_idx);

                auto *dst_indices = &indices[dst_index_offset];
                auto const *src_indices = src_mesh_data.indices();

                for (auto const &idx : make_each(src_mesh_data.index_count())) {
                    dst_indices[idx] = src_indices[idx] + dst_vertex_offset;
                }

                auto *dst_vertices = &vertices[dst_vertex_offset];
                auto const *src_vertices = src_mesh_data.vertices();

                for (auto const &idx : make_each(src_mesh_data.vertex_count())) {
                    auto &dst_vertex = dst_vertices[idx];
                    auto &src_vertex = src_vertices[idx];
                    auto pos = matrix * simd::float4{src_vertex.position[0], src_vertex.position[1], 0.0f, 1.0f};
                    dst_vertex.position = simd::float2{pos.x, pos.y};
                    dst_vertex.tex_coord = src_vertex.tex_coord;
                    dst_vertex.color = is_use_mesh_color ? src_vertex.color : color;
                }
            });
        }

        mesh_info.vertex_idx += _mesh_data.vertex_count();
        mesh_info.index_idx += _mesh_data.index_count();
    }

    void clear_updates() override {
        _updates.flags.reset();

        if (_mesh_data) {
            _mesh_data.renderable().clear_updates();
        }
    }

    ui::mesh_data &mesh_data() {
        return _mesh_data;
    }

    ui::texture &texture() {
        return _texture;
    }

    ui::primitive_type &primitive_type() {
        return _primitive_type;
    }

    simd::float4 &color() {
        return _color;
    }

    bool is_use_mesh_color() {
        return _use_mesh_color;
    }

    void set_mesh_data(ui::mesh_data &&mesh_data) {
        if (!is_same(_mesh_data, mesh_data)) {
            _mesh_data = std::move(mesh_data);

            if (_is_color_exists()) {
                _updates.set(ui::mesh_update_reason::mesh_data);
            }
        }
    }

    void set_texture(ui::texture &&texture) {
        if (!is_same(_texture, texture)) {
            _texture = std::move(texture);

            if (is_rendering_color_exists()) {
                _updates.set(ui::mesh_update_reason::texture);
            }
        }
    }

    void set_primitive_type(ui::primitive_type const type) {
        if (_primitive_type != type) {
            _primitive_type = type;

            if (is_rendering_color_exists()) {
                _updates.set(ui::mesh_update_reason::primitive_type);
            }
        }
    }

    void set_color(simd::float4 &&color) {
        if (!yas::is_equal(_color, color)) {
            _color = std::move(color);

            if (_is_mesh_data_exists() && !_use_mesh_color) {
                _updates.set(ui::mesh_update_reason::color);
            }
        }
    }

    void set_use_mesh_color(bool const use) {
        if (_use_mesh_color != use) {
            _use_mesh_color = use;

            if (_is_mesh_data_exists()) {
                _updates.set(ui::mesh_update_reason::use_mesh_color);
            }
        }
    }

    bool is_rendering_color_exists() override {
        return _is_mesh_data_exists() && _is_color_exists();
    }

   private:
    bool _is_mesh_data_exists() {
        return _mesh_data && _mesh_data.index_count() > 0;
    }

    bool _is_color_exists() {
        if (!_use_mesh_color) {
            static simd::float4 const _clear_color = 0.0f;
            if (yas::is_equal(_color, _clear_color)) {
                return false;
            }
        }
        return true;
    }

    bool _ready_render() {
        if (_mesh_data) {
            _mesh_data.renderable().update_render_buffer_if_needed();

            return is_rendering_color_exists();
        }

        return false;
    }

    bool _needs_write_for_batch_render(ui::mesh_updates_t const &mesh_updates,
                                       ui::mesh_data_updates_t const &mesh_data_updates,
                                       ui::batch_building_type const &building_type) {
        if (building_type == ui::batch_building_type::rebuild) {
            return true;
        }

        if (building_type == ui::batch_building_type::overwrite) {
            static mesh_updates_t const _mesh_overwrite_updates = {ui::mesh_update_reason::color,
                                                                   ui::mesh_update_reason::use_mesh_color};
            static mesh_data_updates_t const _mesh_data_overwrite_updates = {ui::mesh_data_update_reason::data};

            if (mesh_updates.and_test(_mesh_overwrite_updates) ||
                mesh_data_updates.and_test(_mesh_data_overwrite_updates)) {
                return true;
            }
        }

        return false;
    }

    ui::mesh_data _mesh_data = nullptr;
    ui::texture _texture = nullptr;
    ui::primitive_type _primitive_type = ui::primitive_type::triangle;
    simd::float4 _color = 1.0f;
    bool _use_mesh_color = false;

    simd::float4x4 _matrix = matrix_identity_float4x4;

    mesh_updates_t _updates;
};

#pragma mark - ui::mesh

ui::mesh::mesh() : base(std::make_shared<impl>()) {
}

ui::mesh::mesh(std::nullptr_t) : base(nullptr) {
}

ui::mesh_data const &ui::mesh::mesh_data() const {
    return impl_ptr<impl>()->mesh_data();
}

ui::texture const &ui::mesh::texture() const {
    return impl_ptr<impl>()->texture();
}

simd::float4 const &ui::mesh::color() const {
    return impl_ptr<impl>()->color();
}

bool ui::mesh::is_use_mesh_color() const {
    return impl_ptr<impl>()->is_use_mesh_color();
}

ui::primitive_type const &ui::mesh::primitive_type() const {
    return impl_ptr<impl>()->primitive_type();
}

void ui::mesh::set_mesh_data(ui::mesh_data data) {
    impl_ptr<impl>()->set_mesh_data(std::move(data));
}

void ui::mesh::set_texture(ui::texture texture) {
    impl_ptr<impl>()->set_texture(std::move(texture));
}

void ui::mesh::set_color(simd::float4 color) {
    impl_ptr<impl>()->set_color(std::move(color));
}

void ui::mesh::set_use_mesh_color(bool const use) {
    impl_ptr<impl>()->set_use_mesh_color(use);
}

void ui::mesh::set_primitive_type(ui::primitive_type const type) {
    impl_ptr<impl>()->set_primitive_type(type);
}

ui::mesh_data &ui::mesh::mesh_data() {
    return impl_ptr<impl>()->mesh_data();
}

ui::texture &ui::mesh::texture() {
    return impl_ptr<impl>()->texture();
}

#pragma mark - protocol

ui::metal_object &ui::mesh::metal() {
    if (!_metal_object) {
        _metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return _metal_object;
}

ui::renderable_mesh &ui::mesh::renderable() {
    if (!_renderable) {
        _renderable = ui::renderable_mesh{impl_ptr<ui::renderable_mesh::impl>()};
    }
    return _renderable;
}
