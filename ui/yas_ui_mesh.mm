//
//  yas_ui_mesh.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_encode_info.h"
#include "yas_ui_mesh.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

#pragma mark - ui::mesh_data::impl

struct ui::mesh_data::impl : base::impl, metal_object::impl, renderable_mesh_data::impl {
    impl(std::size_t const vertex_count, std::size_t const index_count)
        : _vertex_count(vertex_count), _vertices(vertex_count), _index_count(index_count), _indices(index_count) {
    }

    ui::setup_metal_result setup(id<MTLDevice> const device) override {
        if (![_device.object() isEqual:device]) {
            _device.set_object(device);
            _vertex_buffer.set_object(nil);
            _index_buffer.set_object(nil);
        }

        if (!_vertex_buffer) {
            auto vertex_length = _vertices.size() * sizeof(ui::vertex2d_t) * dynamic_buffer_count();

            _vertex_buffer.move_object(
                [device newBufferWithLength:vertex_length options:MTLResourceOptionCPUCacheModeDefault]);

            if (!_vertex_buffer) {
                return ui::setup_metal_result{ui::setup_metal_error::create_vertex_buffer_failed};
            }
        }

        if (!_index_buffer) {
            auto index_length = _indices.size() * sizeof(UInt16) * dynamic_buffer_count();

            _index_buffer.move_object(
                [device newBufferWithLength:index_length options:MTLResourceOptionCPUCacheModeDefault]);

            if (!_index_buffer) {
                return ui::setup_metal_result{ui::setup_metal_error::create_index_buffer_failed};
            }
        }

        return ui::setup_metal_result{nullptr};
    }

    void update_render_buffer_if_needed() override {
        if (_needs_update_render_buffer) {
            _dynamic_buffer_index = (_dynamic_buffer_index + 1) % dynamic_buffer_count();

            auto vertex_ptr = (ui::vertex2d_t *)[_vertex_buffer.object() contents];
            auto index_ptr = (UInt16 *)[_index_buffer.object() contents];

            memcpy(&vertex_ptr[_vertices.size() * _dynamic_buffer_index], _vertices.data(),
                   _vertex_count * sizeof(ui::vertex2d_t));
            memcpy(&index_ptr[_indices.size() * _dynamic_buffer_index], _indices.data(), _index_count * sizeof(UInt16));

            _needs_update_render_buffer = false;
        }
    }

    std::size_t vertex_buffer_offset() override {
        return 0;
    }

    std::size_t index_buffer_offset() override {
        return 0;
    }

    id<MTLBuffer> vertexBuffer() override {
        return _vertex_buffer.object();
    }

    id<MTLBuffer> indexBuffer() override {
        return _index_buffer.object();
    }

    virtual void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<UInt16> &)> const &func) {
        if (_needs_update_render_buffer) {
            func(_vertices, _indices);
        } else {
            throw "write failed.";
        }
    }

    virtual std::size_t dynamic_buffer_count() {
        return 1;
    }

    bool _needs_update_render_buffer = true;
    std::size_t _dynamic_buffer_index = 0;
    std::size_t _vertex_count;
    std::size_t _index_count;

    objc_ptr<id<MTLBuffer>> _vertex_buffer;
    objc_ptr<id<MTLBuffer>> _index_buffer;
    std::vector<ui::vertex2d_t> _vertices;
    std::vector<UInt16> _indices;

   private:
    objc_ptr<id<MTLDevice>> _device;
};

#pragma mark - ui::mesh_data

ui::mesh_data::mesh_data(std::size_t const vertex_count, std::size_t const index_count)
    : super_class(std::make_shared<impl>(vertex_count, index_count)) {
}

ui::mesh_data::mesh_data(std::shared_ptr<impl> &&impl) : super_class(std::move(impl)) {
}

ui::mesh_data::mesh_data(std::nullptr_t) : super_class(nullptr) {
}

const ui::vertex2d_t *ui::mesh_data::vertices() const {
    return impl_ptr<impl>()->_vertices.data();
}

std::size_t ui::mesh_data::vertex_count() const {
    return impl_ptr<impl>()->_vertex_count;
}

const UInt16 *ui::mesh_data::indices() const {
    return impl_ptr<impl>()->_indices.data();
}

std::size_t ui::mesh_data::index_count() const {
    return impl_ptr<impl>()->_index_count;
}

void ui::mesh_data::write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<UInt16> &)> const &func) {
    impl_ptr<impl>()->write(func);
}

ui::metal_object ui::mesh_data::metal() {
    return ui::metal_object{impl_ptr<ui::metal_object::impl>()};
}

ui::renderable_mesh_data ui::mesh_data::renderable() {
    return ui::renderable_mesh_data{impl_ptr<ui::renderable_mesh_data::impl>()};
}

#pragma mark - dynamic_mesh_data::impl

struct ui::dynamic_mesh_data::impl : ui::mesh_data::impl {
    using super_class = ui::mesh_data::impl;

    impl(std::size_t const vertex_count, std::size_t const index_count) : super_class(vertex_count, index_count) {
        _needs_update_render_buffer = false;
    }

    void set_vertex_count(std::size_t const count) {
        if (_vertices.size() < count) {
            throw std::string(__PRETTY_FUNCTION__) + " : out of range";
        }

        _vertex_count = count;
    }

    void set_index_count(std::size_t const count) {
        if (_indices.size() < count) {
            throw std::string(__PRETTY_FUNCTION__) + " : out of range";
        }

        _index_count = count;
    }

    std::size_t vertex_buffer_offset() override {
        return _vertices.size() * _dynamic_buffer_index * sizeof(ui::vertex2d_t);
    }

    std::size_t index_buffer_offset() override {
        return _indices.size() * _dynamic_buffer_index * sizeof(UInt16);
    }

    void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<UInt16> &)> const &func) override {
        func(_vertices, _indices);

        _needs_update_render_buffer = true;
    }

    std::size_t dynamic_buffer_count() override {
        return 2;
    }
};

#pragma mark - dynamic_mesh_data

ui::dynamic_mesh_data::dynamic_mesh_data(std::size_t const vertex_count, std::size_t const index_count)
    : super_class(std::make_shared<impl>(vertex_count, index_count)) {
}

ui::dynamic_mesh_data::dynamic_mesh_data(std::nullptr_t) : super_class(nullptr) {
}

void ui::dynamic_mesh_data::set_vertex_count(std::size_t const count) {
    impl_ptr<impl>()->set_vertex_count(count);
}

void ui::dynamic_mesh_data::set_index_count(std::size_t const count) {
    impl_ptr<impl>()->set_index_count(count);
}

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

    void render(ui::renderer &renderer, id<MTLRenderCommandEncoder> const encoder,
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

ui::mesh::mesh() : super_class(std::make_shared<impl>()) {
}

ui::mesh::mesh(std::nullptr_t) : super_class(nullptr) {
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

void ui::mesh::set_data(ui::mesh_data data) {
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
