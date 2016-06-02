//
//  yas_ui_mesh.mm
//

#include "yas_each_index.h"
#include "yas_objc_ptr.h"
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
    impl() = default;

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
        if (_is_skip_render()) {
            return 0;
        }

        return _mesh_data.vertex_count();
    }

    std::size_t render_index_count() override {
        if (_is_skip_render()) {
            return 0;
        }

        return _mesh_data.index_count();
    }

    bool needs_update_for_render() override {
        if (_needs_update_for_render) {
            return true;
        } else if (_mesh_data) {
            return _mesh_data.renderable().needs_update_for_render();
        }

        return false;
    }

    void metal_render(ui::renderer_base &renderer, id<MTLRenderCommandEncoder> const encoder,
                      ui::metal_encode_info const &encode_info) override {
        if (!_ready_render()) {
            return;
        }

        auto const vertex_buffer_byte_offset = _mesh_data.renderable().vertex_buffer_byte_offset();
        auto const index_buffer_byte_offset = _mesh_data.renderable().index_buffer_byte_offset();
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

        [encoder setVertexBuffer:_mesh_data.renderable().vertexBuffer() offset:vertex_buffer_byte_offset atIndex:0];
        [encoder setVertexBuffer:currentConstantBuffer offset:constant_buffer_offset atIndex:1];

        constant_buffer_offset += sizeof(uniforms2d_t);

        [encoder drawIndexedPrimitives:to_mtl_primitive_type(_primitive_type)
                            indexCount:_mesh_data.index_count()
                             indexType:MTLIndexTypeUInt32
                           indexBuffer:_mesh_data.renderable().indexBuffer()
                     indexBufferOffset:index_buffer_byte_offset];

        renderer.set_constant_buffer_offset(constant_buffer_offset);
    }

    void batch_render(ui::batch_render_mesh_info &mesh_info) override {
        if (!_ready_render()) {
            return;
        }

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

        mesh_info.vertex_idx += _mesh_data.vertex_count();
        mesh_info.index_idx += _mesh_data.index_count();
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
            _needs_update_for_render = true;
        }
    }

    void set_texture(ui::texture &&texture) {
        if (!is_same(_texture, texture)) {
            _texture = std::move(texture);
            _set_needs_update_for_render();
        }
    }

    void set_primitive_type(ui::primitive_type const type) {
        if (_primitive_type != type) {
            _primitive_type = type;
            _set_needs_update_for_render();
        }
    }

    void set_color(simd::float4 &&color) {
        if (_color[0] != color[0] || _color[1] != color[1] || _color[2] != color[2] || _color[3] != color[3]) {
            _color = std::move(color);
            _set_needs_update_for_render();
        }
    }

    void set_use_mesh_color(bool const use) {
        if (_use_mesh_color != use) {
            _use_mesh_color = use;
            _set_needs_update_for_render();
        }
    }

   private:
    ui::mesh_data _mesh_data = nullptr;
    ui::texture _texture = nullptr;
    ui::primitive_type _primitive_type = ui::primitive_type::triangle;
    simd::float4 _color = 1.0f;
    bool _use_mesh_color = false;

    bool _needs_update_for_render = true;

    simd::float4x4 _matrix = matrix_identity_float4x4;

    void _set_needs_update_for_render() {
        if (_mesh_data) {
            _needs_update_for_render = true;
        }
    }

    bool _is_skip_render() {
        if (!_mesh_data || _mesh_data.index_count() == 0) {
            return true;
        }

        if (!_use_mesh_color && yas::is_equal(_color, simd::float4{0.0f})) {
            return true;
        }

        return false;
    }

    bool _ready_render() {
        _needs_update_for_render = false;

        if (_mesh_data) {
            _mesh_data.renderable().update_render_buffer_if_needed();
        } else {
            return false;
        }

        if (_is_skip_render()) {
            return false;
        }

        return true;
    }
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
