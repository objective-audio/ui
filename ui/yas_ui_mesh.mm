//
//  yas_ui_mesh.mm
//

#include "yas_objc_container.h"
#include "yas_ui_encode_info.h"
#include "yas_ui_mesh.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

namespace yas {
namespace ui {
    static const UInt32 mesh_dynamic_buffer_count = 2;
}
}

#pragma mark - renderable_mesh

ui::renderable_mesh::renderable_mesh(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

simd::float4x4 const &ui::renderable_mesh::matrix() const {
    return impl_ptr<impl>()->matrix();
}

void ui::renderable_mesh::set_matrix(simd::float4x4 matrix) {
    impl_ptr<impl>()->set_matrix(std::move(matrix));
}

void ui::renderable_mesh::render(ui::renderer &renderer, id<MTLRenderCommandEncoder> const encoder,
                                 ui::encode_info const &encode_info) {
    impl_ptr<impl>()->render(renderer, encoder, encode_info);
}

#pragma mark - ui::mesh::impl

struct ui::mesh::impl : public base::impl, public renderable_mesh::impl, public metal_object::impl {
    impl(UInt32 const vertex_count, UInt32 const index_count, bool const dynamic)
        : _vertex_count(vertex_count),
          _vertices(vertex_count),
          _index_count(index_count),
          _indices(index_count),
          _dynamic(dynamic) {
    }

    ui::setup_metal_result setup(id<MTLDevice> const device) override {
        if (![_device.object() isEqual:device]) {
            _device.set_object(device);
            _vertex_buffer.set_object(nil);
            _index_buffer.set_object(nil);
        }

        if (!_vertex_buffer) {
            auto vertex_length = _vertices.size() * sizeof(ui::vertex2d_t);

            if (_dynamic) {
                vertex_length *= mesh_dynamic_buffer_count;
            }

            _vertex_buffer.move_object(
                [device newBufferWithLength:vertex_length options:MTLResourceOptionCPUCacheModeDefault]);

            if (!_vertex_buffer) {
                return ui::setup_metal_result{ui::setup_metal_error::create_vertex_buffer_failed};
            }
        }

        if (!_index_buffer) {
            auto index_length = _indices.size() * sizeof(UInt16);

            if (_dynamic) {
                index_length *= mesh_dynamic_buffer_count;
            }

            _index_buffer.move_object(
                [device newBufferWithLength:index_length options:MTLResourceOptionCPUCacheModeDefault]);

            if (!_index_buffer) {
                return ui::setup_metal_result{ui::setup_metal_error::create_index_buffer_failed};
            }
        }

        return ui::setup_metal_result{nullptr};
    }

    void set_needs_update_render_buffer() {
        if (_dynamic) {
            _needs_update_render_buffer = true;
        }
    }

    UInt32 vertex_count() {
        return _vertex_count;
    }

    void set_vertex_count(UInt32 const count) {
        if (!_dynamic) {
            throw std::string(__PRETTY_FUNCTION__) + " : mesh is constant";
        }

        if (_vertices.size() < count) {
            throw std::string(__PRETTY_FUNCTION__) + " : out of range";
        }

        _vertex_count = count;
    }

    UInt32 index_count() {
        return _index_count;
    }

    void set_index_count(UInt32 const count) {
        if (!_dynamic) {
            throw std::string(__PRETTY_FUNCTION__) + " : mesh is constant";
        }

        if (_indices.size() < count) {
            throw std::string(__PRETTY_FUNCTION__) + " : out of range";
        }

        _index_count = count;
    }

    simd::float4x4 const &matrix() const override {
        return _matrix;
    }

    void set_matrix(simd::float4x4 &&matrix) override {
        _matrix = std::move(matrix);
    }

    void render(ui::renderer &renderer, id<MTLRenderCommandEncoder> const encoder,
                ui::encode_info const &encode_info) override {
        if (_needs_update_render_buffer) {
            if (_dynamic) {
                _dynamic_buffer_index = (_dynamic_buffer_index + 1) % mesh_dynamic_buffer_count;
            }

            auto vertex_ptr = (ui::vertex2d_t *)[_vertex_buffer.object() contents];
            auto index_ptr = (UInt16 *)[_index_buffer.object() contents];

            memcpy(&vertex_ptr[_vertices.size() * _dynamic_buffer_index], _vertices.data(),
                   _vertex_count * sizeof(ui::vertex2d_t));
            memcpy(&index_ptr[_indices.size() * _dynamic_buffer_index], _indices.data(), _index_count * sizeof(UInt16));

            _needs_update_render_buffer = false;
        }

        if (_index_count == 0) {
            return;
        }

        if (_color.x == 0.0f && _color.y == 0.0f && _color.z == 0.0f && _color.w == 0.0f) {
            return;
        }

        auto vertex_buffer_offset = _vertices.size() * _dynamic_buffer_index * sizeof(ui::vertex2d_t);
        auto index_buffer_offset = _indices.size() * _dynamic_buffer_index * sizeof(UInt16);
        auto constant_buffer_offset = renderer.constant_buffer_offset();
        auto currentConstantBuffer = renderer.current_constant_buffer();

        auto constant_ptr = (UInt8 *)[currentConstantBuffer contents];
        auto uniforms_ptr = (uniforms2d_t *)(&constant_ptr[constant_buffer_offset]);
        uniforms_ptr->matrix = _matrix;
        uniforms_ptr->color = _color;

        if (_texture) {
            [encoder setFragmentBuffer:currentConstantBuffer offset:constant_buffer_offset atIndex:0];
            [encoder setRenderPipelineState:encode_info.pipelineState()];
            [encoder setFragmentTexture:_texture.mtlTexture() atIndex:0];
            [encoder setFragmentSamplerState:_texture.sampler() atIndex:0];
        } else {
            [encoder setRenderPipelineState:encode_info.pipelineStateWithoutTexture()];
        }

        [encoder setVertexBuffer:_vertex_buffer.object() offset:vertex_buffer_offset atIndex:0];
        [encoder setVertexBuffer:currentConstantBuffer offset:constant_buffer_offset atIndex:1];

        constant_buffer_offset += sizeof(uniforms2d_t);

        [encoder drawIndexedPrimitives:_primitive_type
                            indexCount:_index_count
                             indexType:MTLIndexTypeUInt16
                           indexBuffer:_index_buffer.object()
                     indexBufferOffset:index_buffer_offset];

        renderer.set_constant_buffer_offset(constant_buffer_offset);
    }

    ui::texture _texture = nullptr;
    MTLPrimitiveType _primitive_type = MTLPrimitiveTypeTriangle;
    bool _dynamic;
    simd::float4 _color = 1.0f;

    bool _needs_update_render_buffer = true;
    UInt32 _dynamic_buffer_index = 0;
    objc::container<id<MTLBuffer>> _vertex_buffer;
    objc::container<id<MTLBuffer>> _index_buffer;
    std::vector<ui::vertex2d_t> _vertices;
    std::vector<UInt16> _indices;

   private:
    simd::float4x4 _matrix = matrix_identity_float4x4;
    UInt32 _vertex_count;
    UInt32 _index_count;

    objc::container<id<MTLDevice>> _device;
};

#pragma mark - ui::mesh

ui::mesh::mesh(UInt32 const vertex_count, UInt32 const index_count, bool const dynamic)
    : super_class(std::make_shared<impl>(vertex_count, index_count, dynamic)) {
}

ui::mesh::mesh(std::nullptr_t) : super_class(nullptr) {
}

ui::texture const &ui::mesh::texture() const {
    return impl_ptr<impl>()->_texture;
}

simd::float4 const &ui::mesh::color() const {
    return impl_ptr<impl>()->_color;
}

const ui::vertex2d_t *ui::mesh::vertices() const {
    return impl_ptr<impl>()->_vertices.data();
}

UInt32 ui::mesh::vertex_count() const {
    return impl_ptr<impl>()->vertex_count();
}

const UInt16 *ui::mesh::indices() const {
    return impl_ptr<impl>()->_indices.data();
}

UInt32 ui::mesh::index_count() const {
    return impl_ptr<impl>()->index_count();
}

bool ui::mesh::is_dynamic() const {
    return impl_ptr<impl>()->_dynamic;
}

void ui::mesh::set_texture(ui::texture texture) {
    impl_ptr<impl>()->_texture = std::move(texture);
}

void ui::mesh::set_color(simd::float4 const color) {
    impl_ptr<impl>()->_color = color;
}

void ui::mesh::set_vertex_count(UInt32 const count) {
    impl_ptr<impl>()->set_vertex_count(count);
}

void ui::mesh::set_index_count(UInt32 const count) {
    impl_ptr<impl>()->set_index_count(count);
}

void ui::mesh::write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<UInt16> &)> const &func) {
    func(impl_ptr<impl>()->_vertices, impl_ptr<impl>()->_indices);

    impl_ptr<impl>()->_needs_update_render_buffer = true;
}

#pragma mark - protocol

ui::metal_object ui::mesh::metal() {
    return ui::metal_object{impl_ptr<ui::metal_object::impl>()};
}

ui::renderable_mesh ui::mesh::renderable() {
    return ui::renderable_mesh{impl_ptr<ui::renderable_mesh::impl>()};
}
