//
//  yas_ui_mesh_data.mm
//

#include <bitset>
#include "yas_objc_ptr.h"
#include "yas_ui_mesh_data.h"

using namespace yas;

#pragma mark - ui::mesh_data::impl

struct ui::mesh_data::impl : base::impl, metal_object::impl, renderable_mesh_data::impl {
    impl(std::size_t const vertex_count, std::size_t const index_count)
        : _vertex_count(vertex_count), _vertices(vertex_count), _index_count(index_count), _indices(index_count) {
        _update_reasons.set();
    }

    ui::setup_metal_result metal_setup(id<MTLDevice> const device) override {
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
            auto index_length = _indices.size() * sizeof(ui::index2d_t) * dynamic_buffer_count();

            _index_buffer.move_object(
                [device newBufferWithLength:index_length options:MTLResourceOptionCPUCacheModeDefault]);

            if (!_index_buffer) {
                return ui::setup_metal_result{ui::setup_metal_error::create_index_buffer_failed};
            }
        }

        return ui::setup_metal_result{nullptr};
    }

    void update_render_buffer_if_needed() override {
        if (!_update_reasons.any()) {
            return;
        }

        _dynamic_buffer_index = (_dynamic_buffer_index + 1) % dynamic_buffer_count();

        auto vertex_ptr = (ui::vertex2d_t *)[_vertex_buffer.object() contents];
        auto index_ptr = (ui::index2d_t *)[_index_buffer.object() contents];

        memcpy(&vertex_ptr[_vertices.size() * _dynamic_buffer_index], _vertices.data(),
               _vertices.size() * sizeof(ui::vertex2d_t));
        memcpy(&index_ptr[_indices.size() * _dynamic_buffer_index], _indices.data(),
               _indices.size() * sizeof(ui::index2d_t));

        _update_reasons.reset();
    }

    std::size_t vertex_buffer_byte_offset() override {
        return 0;
    }

    std::size_t index_buffer_byte_offset() override {
        return 0;
    }

    id<MTLBuffer> vertexBuffer() override {
        return _vertex_buffer.object();
    }

    id<MTLBuffer> indexBuffer() override {
        return _index_buffer.object();
    }

    bool needs_update_for_render() override {
        return _update_reasons.any();
    }

    virtual void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &func) {
        if (_update_reasons.any()) {
            func(_vertices, _indices);
        } else {
            throw "write failed.";
        }
    }

    virtual std::size_t dynamic_buffer_count() {
        return 1;
    }

    void _set_needs_update(ui::mesh_data_update_reason const reason) {
        _update_reasons.set(static_cast<ui::mesh_data_update_reason_t>(reason));
    }

    std::size_t _dynamic_buffer_index = 0;
    std::size_t _vertex_count;
    std::size_t _index_count;

    objc_ptr<id<MTLBuffer>> _vertex_buffer;
    objc_ptr<id<MTLBuffer>> _index_buffer;
    std::vector<ui::vertex2d_t> _vertices;
    std::vector<ui::index2d_t> _indices;

    std::bitset<ui::mesh_data_update_reason_count> _update_reasons;

   private:
    objc_ptr<id<MTLDevice>> _device;
};

#pragma mark - ui::mesh_data

ui::mesh_data::mesh_data(std::size_t const vertex_count, std::size_t const index_count)
    : base(std::make_shared<impl>(vertex_count, index_count)) {
}

ui::mesh_data::mesh_data(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
}

ui::mesh_data::mesh_data(std::nullptr_t) : base(nullptr) {
}

const ui::vertex2d_t *ui::mesh_data::vertices() const {
    return impl_ptr<impl>()->_vertices.data();
}

std::size_t ui::mesh_data::vertex_count() const {
    return impl_ptr<impl>()->_vertex_count;
}

const ui::index2d_t *ui::mesh_data::indices() const {
    return impl_ptr<impl>()->_indices.data();
}

std::size_t ui::mesh_data::index_count() const {
    return impl_ptr<impl>()->_index_count;
}

void ui::mesh_data::write(
    std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &func) {
    impl_ptr<impl>()->write(func);
}

ui::metal_object &ui::mesh_data::metal() {
    if (!_metal_object) {
        _metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return _metal_object;
}

ui::renderable_mesh_data &ui::mesh_data::renderable() {
    if (!_renderable) {
        _renderable = ui::renderable_mesh_data{impl_ptr<ui::renderable_mesh_data::impl>()};
    }
    return _renderable;
}

#pragma mark - dynamic_mesh_data::impl

struct ui::dynamic_mesh_data::impl : ui::mesh_data::impl {
    impl(std::size_t const vertex_count, std::size_t const index_count) : mesh_data::impl(vertex_count, index_count) {
        _update_reasons.reset();
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

    std::size_t vertex_buffer_byte_offset() override {
        return _vertices.size() * _dynamic_buffer_index * sizeof(ui::vertex2d_t);
    }

    std::size_t index_buffer_byte_offset() override {
        return _indices.size() * _dynamic_buffer_index * sizeof(ui::index2d_t);
    }

    void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &func) override {
        func(_vertices, _indices);

        _set_needs_update(ui::mesh_data_update_reason::data);
    }

    std::size_t dynamic_buffer_count() override {
        return 2;
    }
};

#pragma mark - dynamic_mesh_data

ui::dynamic_mesh_data::dynamic_mesh_data(std::size_t const vertex_count, std::size_t const index_count)
    : mesh_data(std::make_shared<impl>(vertex_count, index_count)) {
}

ui::dynamic_mesh_data::dynamic_mesh_data(std::nullptr_t) : mesh_data(nullptr) {
}

std::size_t ui::dynamic_mesh_data::max_vertex_count() const {
    return impl_ptr<impl>()->_vertices.size();
}

std::size_t ui::dynamic_mesh_data::max_index_count() const {
    return impl_ptr<impl>()->_indices.size();
}

void ui::dynamic_mesh_data::set_vertex_count(std::size_t const count) {
    impl_ptr<impl>()->set_vertex_count(count);
}

void ui::dynamic_mesh_data::set_index_count(std::size_t const count) {
    impl_ptr<impl>()->set_index_count(count);
}
