//
//  yas_ui_static_mesh_data.mm
//

#include "yas_ui_static_mesh_data.h"

#include <ui/metal/yas_ui_metal_buffer.h>
#include <ui/metal/yas_ui_metal_system.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - vertex2d_t

template <>
static_mesh_data<vertex2d_t>::static_mesh_data(std::size_t const count) : _raw(count) {
    this->_updates.flags.set();
}

template <>
const vertex2d_t *static_mesh_data<vertex2d_t>::raw_data() const {
    return this->_raw.data();
}

template <>
std::size_t static_mesh_data<vertex2d_t>::count() const {
    return this->_raw.size();
}

template <>
void static_mesh_data<vertex2d_t>::write_once(std::function<void(std::vector<vertex2d_t> &)> const &handler) {
    if (this->_updates.flags.any()) {
        handler(this->_raw);
    } else {
        throw std::runtime_error("write failed.");
    }
}

template <>
std::size_t static_mesh_data<vertex2d_t>::byte_offset() {
    return 0;
}

template <>
id<MTLBuffer> static_mesh_data<vertex2d_t>::mtlBuffer() {
    if (this->_mtl_buffer) {
        return this->_mtl_buffer->rawBuffer();
    } else {
        return nil;
    }
}

template <>
mesh_data_updates_t const &static_mesh_data<vertex2d_t>::updates() {
    return this->_updates;
}

template <>
void static_mesh_data<vertex2d_t>::update_render_buffer() {
    if (this->_updates.test(mesh_data_update_reason::render_buffer)) {
        if (this->_mtl_buffer) {
            this->_mtl_buffer->template write<vertex2d_t>(this->_raw, 0);
        }

        this->_updates.reset(mesh_data_update_reason::render_buffer);
    }
}

template <>
void static_mesh_data<vertex2d_t>::clear_updates() {
    this->_updates.flags.reset();
}

template <>
setup_metal_result static_mesh_data<vertex2d_t>::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    if (this->_metal_system != system) {
        this->_metal_system = system;
        this->_mtl_buffer = nullptr;
    }

    if (!this->_mtl_buffer) {
        auto const vertex_length = this->_raw.size() * sizeof(vertex2d_t);

        this->_mtl_buffer = system->make_metal_buffer(vertex_length);

        if (!this->_mtl_buffer) {
            return setup_metal_result{setup_metal_error::create_vertex_buffer_failed};
        }
    }

    return setup_metal_result{nullptr};
}

template <>
std::shared_ptr<static_mesh_data<vertex2d_t>> static_mesh_data<vertex2d_t>::make_shared(std::size_t const count) {
    return std::shared_ptr<static_mesh_data>(new static_mesh_data{count});
}

#pragma mark - index2d_t

template <>
static_mesh_data<index2d_t>::static_mesh_data(std::size_t const count) : _raw(count) {
    this->_updates.flags.set();
}

template <>
const index2d_t *static_mesh_data<index2d_t>::raw_data() const {
    return this->_raw.data();
}

template <>
std::size_t static_mesh_data<index2d_t>::count() const {
    return this->_raw.size();
}

template <>
void static_mesh_data<index2d_t>::write_once(std::function<void(std::vector<index2d_t> &)> const &handler) {
    if (this->_updates.flags.any()) {
        handler(_raw);
    } else {
        throw std::runtime_error("write failed.");
    }
}

template <>
std::size_t static_mesh_data<index2d_t>::byte_offset() {
    return 0;
}

template <>
id<MTLBuffer> static_mesh_data<index2d_t>::mtlBuffer() {
    if (this->_mtl_buffer) {
        return this->_mtl_buffer->rawBuffer();
    } else {
        return nil;
    }
}

template <>
mesh_data_updates_t const &static_mesh_data<index2d_t>::updates() {
    return this->_updates;
}

template <>
void static_mesh_data<index2d_t>::update_render_buffer() {
    if (this->_updates.test(mesh_data_update_reason::render_buffer)) {
        if (this->_mtl_buffer) {
            this->_mtl_buffer->template write<index2d_t>(this->_raw, 0);
        }

        this->_updates.reset(mesh_data_update_reason::render_buffer);
    }
}

template <>
void static_mesh_data<index2d_t>::clear_updates() {
    this->_updates.flags.reset();
}

template <>
setup_metal_result static_mesh_data<index2d_t>::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    if (this->_metal_system != system) {
        this->_metal_system = system;
        this->_mtl_buffer = nullptr;
    }

    if (!this->_mtl_buffer) {
        auto const vertex_length = this->_raw.size() * sizeof(index2d_t);

        this->_mtl_buffer = system->make_metal_buffer(vertex_length);

        if (!this->_mtl_buffer) {
            return setup_metal_result{setup_metal_error::create_vertex_buffer_failed};
        }
    }

    return setup_metal_result{nullptr};
}

template <>
std::shared_ptr<static_mesh_data<index2d_t>> static_mesh_data<index2d_t>::make_shared(std::size_t const count) {
    return std::shared_ptr<static_mesh_data>(new static_mesh_data{count});
}
