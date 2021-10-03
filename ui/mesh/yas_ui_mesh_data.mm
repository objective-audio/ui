//
//  yas_ui_mesh_data.mm
//

#include <ui/yas_ui_mesh_data.h>
#include <ui/yas_ui_metal_buffer.h>
#include <ui/yas_ui_metal_system.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - mesh_data vertex2d_t

template <>
mesh_data<vertex2d_t>::mesh_data(std::size_t const count) : _count(count), _raw(count) {
    this->_updates.flags.set();
}

template <>
std::size_t mesh_data<vertex2d_t>::dynamic_buffer_count() {
    return 1;
}

template <>
const vertex2d_t *mesh_data<vertex2d_t>::raw_data() const {
    return this->_raw.data();
}

template <>
std::size_t mesh_data<vertex2d_t>::count() const {
    return this->_count;
}

template <>
bool mesh_data<vertex2d_t>::data_exists() const {
    return this->_count > 0;
}

template <>
void mesh_data<vertex2d_t>::write(std::function<void(std::vector<vertex2d_t> &)> const &func) {
    if (this->_updates.flags.any()) {
        func(_raw);
    } else {
        throw std::runtime_error("write failed.");
    }
}

template <>
std::size_t mesh_data<vertex2d_t>::byte_offset() {
    return 0;
}

template <>
id<MTLBuffer> mesh_data<vertex2d_t>::mtlBuffer() {
    if (this->_mtl_buffer) {
        return this->_mtl_buffer->rawBuffer();
    } else {
        return nil;
    }
}

template <>
mesh_data_updates_t const &mesh_data<vertex2d_t>::updates() {
    return this->_updates;
}

template <>
void mesh_data<vertex2d_t>::update_render_buffer() {
    if (this->_updates.test(mesh_data_update_reason::render_buffer)) {
        this->_dynamic_buffer_index = (this->_dynamic_buffer_index + 1) % this->dynamic_buffer_count();

        if (this->_mtl_buffer) {
            this->_mtl_buffer->template write<vertex2d_t>(this->_raw, this->_dynamic_buffer_index);
        }

        this->_updates.reset(mesh_data_update_reason::render_buffer);
    }
}

template <>
void mesh_data<vertex2d_t>::clear_updates() {
    this->_updates.flags.reset();
}

template <>
setup_metal_result mesh_data<vertex2d_t>::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    if (this->_metal_system != system) {
        this->_metal_system = system;
        this->_mtl_buffer = nullptr;
    }

    if (!this->_mtl_buffer) {
        auto const vertex_length = this->_raw.size() * sizeof(vertex2d_t) * this->dynamic_buffer_count();

        // make_gl_bufferにしたい
        this->_mtl_buffer = system->make_metal_buffer(vertex_length);

        if (!this->_mtl_buffer) {
            return setup_metal_result{setup_metal_error::create_vertex_buffer_failed};
        }
    }

    return setup_metal_result{nullptr};
}

template <>
std::shared_ptr<mesh_data<vertex2d_t>> mesh_data<vertex2d_t>::make_shared(std::size_t const count) {
    return std::shared_ptr<mesh_data>(new mesh_data{count});
}

#pragma mark - dynamic_mesh_data vertex2d_t

template <>
dynamic_mesh_data<vertex2d_t>::dynamic_mesh_data(std::size_t const count) : mesh_data<vertex2d_t>(count) {
    this->_updates.flags.reset();
}

template <>
std::size_t dynamic_mesh_data<vertex2d_t>::byte_offset() {
    return this->_raw.size() * this->_dynamic_buffer_index * sizeof(vertex2d_t);
}

template <>
std::size_t dynamic_mesh_data<vertex2d_t>::max_count() const {
    return this->_raw.size();
}

template <>
void dynamic_mesh_data<vertex2d_t>::set_count(std::size_t const count) {
    if (this->_raw.size() < count) {
        throw std::string(__PRETTY_FUNCTION__) + " : out of range";
    }

    this->_count = count;

    this->_updates.set(mesh_data_update_reason::data_count);
}

template <>
void dynamic_mesh_data<vertex2d_t>::write(std::function<void(std::vector<vertex2d_t> &)> const &handler) {
    handler(this->_raw);

    this->_updates.set(mesh_data_update_reason::data_content);
    this->_updates.set(mesh_data_update_reason::render_buffer);
}

template <>
std::size_t dynamic_mesh_data<vertex2d_t>::dynamic_buffer_count() {
    return 2;
}

template <>
std::shared_ptr<dynamic_mesh_data<vertex2d_t>> dynamic_mesh_data<vertex2d_t>::make_shared(std::size_t const count) {
    return std::shared_ptr<dynamic_mesh_data>(new dynamic_mesh_data{count});
}

#pragma mark - mesh_data index2d_t

template <>
mesh_data<index2d_t>::mesh_data(std::size_t const count) : _count(count), _raw(count) {
    this->_updates.flags.set();
}

template <>
std::size_t mesh_data<index2d_t>::dynamic_buffer_count() {
    return 1;
}

template <>
const index2d_t *mesh_data<index2d_t>::raw_data() const {
    return this->_raw.data();
}

template <>
std::size_t mesh_data<index2d_t>::count() const {
    return this->_count;
}

template <>
bool mesh_data<index2d_t>::data_exists() const {
    return this->_count > 0;
}

template <>
void mesh_data<index2d_t>::write(std::function<void(std::vector<index2d_t> &)> const &func) {
    if (this->_updates.flags.any()) {
        func(_raw);
    } else {
        throw std::runtime_error("write failed.");
    }
}

template <>
std::size_t mesh_data<index2d_t>::byte_offset() {
    return 0;
}

template <>
id<MTLBuffer> mesh_data<index2d_t>::mtlBuffer() {
    if (this->_mtl_buffer) {
        return this->_mtl_buffer->rawBuffer();
    } else {
        return nil;
    }
}

template <>
mesh_data_updates_t const &mesh_data<index2d_t>::updates() {
    return this->_updates;
}

template <>
void mesh_data<index2d_t>::update_render_buffer() {
    if (this->_updates.test(mesh_data_update_reason::render_buffer)) {
        this->_dynamic_buffer_index = (this->_dynamic_buffer_index + 1) % this->dynamic_buffer_count();

        if (this->_mtl_buffer) {
            this->_mtl_buffer->template write<index2d_t>(this->_raw, this->_dynamic_buffer_index);
        }

        this->_updates.reset(mesh_data_update_reason::render_buffer);
    }
}

template <>
void mesh_data<index2d_t>::clear_updates() {
    this->_updates.flags.reset();
}

template <>
setup_metal_result mesh_data<index2d_t>::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    if (this->_metal_system != system) {
        this->_metal_system = system;
        this->_mtl_buffer = nullptr;
    }

    if (!this->_mtl_buffer) {
        auto const vertex_length = this->_raw.size() * sizeof(index2d_t) * this->dynamic_buffer_count();

        // make_gl_bufferにしたい
        this->_mtl_buffer = system->make_metal_buffer(vertex_length);

        if (!this->_mtl_buffer) {
            return setup_metal_result{setup_metal_error::create_vertex_buffer_failed};
        }
    }

    return setup_metal_result{nullptr};
}

template <>
std::shared_ptr<mesh_data<index2d_t>> mesh_data<index2d_t>::make_shared(std::size_t const count) {
    return std::shared_ptr<mesh_data>(new mesh_data{count});
}

#pragma mark - dynamic_mesh_data index2d_t

template <>
dynamic_mesh_data<index2d_t>::dynamic_mesh_data(std::size_t const count) : mesh_data<index2d_t>(count) {
    this->_updates.flags.reset();
}

template <>
std::size_t dynamic_mesh_data<index2d_t>::byte_offset() {
    return this->_raw.size() * this->_dynamic_buffer_index * sizeof(index2d_t);
}

template <>
std::size_t dynamic_mesh_data<index2d_t>::max_count() const {
    return this->_raw.size();
}

template <>
void dynamic_mesh_data<index2d_t>::set_count(std::size_t const count) {
    if (this->_raw.size() < count) {
        throw std::string(__PRETTY_FUNCTION__) + " : out of range";
    }

    this->_count = count;

    this->_updates.set(mesh_data_update_reason::data_count);
}

template <>
void dynamic_mesh_data<index2d_t>::write(std::function<void(std::vector<index2d_t> &)> const &handler) {
    handler(this->_raw);

    this->_updates.set(mesh_data_update_reason::data_content);
    this->_updates.set(mesh_data_update_reason::render_buffer);
}

template <>
std::size_t dynamic_mesh_data<index2d_t>::dynamic_buffer_count() {
    return 2;
}

template <>
std::shared_ptr<dynamic_mesh_data<index2d_t>> dynamic_mesh_data<index2d_t>::make_shared(std::size_t const count) {
    return std::shared_ptr<dynamic_mesh_data>(new dynamic_mesh_data{count});
}
