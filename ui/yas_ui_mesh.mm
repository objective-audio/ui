//
//  yas_ui_mesh.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_encode_info.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

#pragma mark - ui::mesh::impl

struct ui::mesh::impl : base::impl, renderable_mesh::impl, metal_object::impl {
    impl() = default;

    ui::setup_metal_result setup(id<MTLDevice> const device) override {
        if (_mesh_data) {
            return _mesh_data.metal().setup(device);
        }
        return ui::setup_metal_result{nullptr};
    }

    simd::float4x4 const &matrix() const override {
        return _matrix;
    }

    void set_matrix(simd::float4x4 &&matrix) override {
        _matrix = std::move(matrix);
    }

    void render(ui::renderer_base &renderer, id<MTLRenderCommandEncoder> const encoder,
                ui::encode_info const &encode_info) override {
        if (!_mesh_data) {
            return;
        }

        _mesh_data.renderable().update_render_buffer_if_needed();

        auto const index_count = _mesh_data.index_count();

        if (index_count == 0) {
            return;
        }

        if (_color.x == 0.0f && _color.y == 0.0f && _color.z == 0.0f && _color.w == 0.0f) {
            return;
        }

        auto vertex_buffer_offset = _mesh_data.renderable().vertex_buffer_offset();
        auto index_buffer_offset = _mesh_data.renderable().index_buffer_offset();
        auto constant_buffer_offset = renderer.constant_buffer_offset();
        auto currentConstantBuffer = renderer.current_constant_buffer();

        auto constant_ptr = (uint8_t *)[currentConstantBuffer contents];
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

        [encoder setVertexBuffer:_mesh_data.renderable().vertexBuffer() offset:vertex_buffer_offset atIndex:0];
        [encoder setVertexBuffer:currentConstantBuffer offset:constant_buffer_offset atIndex:1];

        constant_buffer_offset += sizeof(uniforms2d_t);

        [encoder drawIndexedPrimitives:to_mtl_primitive_type(_primitive_type)
                            indexCount:index_count
                             indexType:MTLIndexTypeUInt16
                           indexBuffer:_mesh_data.renderable().indexBuffer()
                     indexBufferOffset:index_buffer_offset];

        renderer.set_constant_buffer_offset(constant_buffer_offset);
    }

    ui::mesh_data _mesh_data = nullptr;
    ui::texture _texture = nullptr;
    ui::primitive_type _primitive_type = ui::primitive_type::triangle;
    bool _dynamic;
    simd::float4 _color = 1.0f;

   private:
    simd::float4x4 _matrix = matrix_identity_float4x4;
};

#pragma mark - ui::mesh

ui::mesh::mesh() : base(std::make_shared<impl>()) {
}

ui::mesh::mesh(std::nullptr_t) : base(nullptr) {
}

ui::mesh_data const &ui::mesh::data() const {
    return impl_ptr<impl>()->_mesh_data;
}

ui::texture const &ui::mesh::texture() const {
    return impl_ptr<impl>()->_texture;
}

simd::float4 const &ui::mesh::color() const {
    return impl_ptr<impl>()->_color;
}

ui::primitive_type const &ui::mesh::primitive_type() const {
    return impl_ptr<impl>()->_primitive_type;
}

void ui::mesh::set_mesh_data(ui::mesh_data data) {
    impl_ptr<impl>()->_mesh_data = std::move(data);
}

void ui::mesh::set_texture(ui::texture texture) {
    impl_ptr<impl>()->_texture = std::move(texture);
}

void ui::mesh::set_color(simd::float4 const color) {
    impl_ptr<impl>()->_color = color;
}

void ui::mesh::set_primitive_type(ui::primitive_type const type) {
    impl_ptr<impl>()->_primitive_type = type;
}

#pragma mark - protocol

ui::metal_object ui::mesh::metal() {
    return ui::metal_object{impl_ptr<ui::metal_object::impl>()};
}

ui::renderable_mesh ui::mesh::renderable() {
    return ui::renderable_mesh{impl_ptr<ui::renderable_mesh::impl>()};
}
