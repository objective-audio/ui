//
//  yas_ui_mesh_data.mm
//

#include "yas_ui_mesh_data.h"
#include <ui/yas_ui_metal_system.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - mesh_data

mesh_data::mesh_data(mesh_data_args &&args)
    : _vertex_count(args.vertex_count),
      _vertices(args.vertex_count),
      _index_count(args.index_count),
      _indices(args.index_count) {
    this->_updates.flags.set();
}

const vertex2d_t *mesh_data::vertices() const {
    return this->_vertices.data();
}

std::size_t mesh_data::vertex_count() const {
    return this->_vertex_count;
}

const index2d_t *mesh_data::indices() const {
    return this->_indices.data();
}

std::size_t mesh_data::index_count() const {
    return this->_index_count;
}

bool mesh_data::data_exists() const {
    return this->_vertex_count > 0 && this->_index_count > 0;
}

void mesh_data::write(std::function<void(std::vector<vertex2d_t> &, std::vector<index2d_t> &)> const &func) {
    if (this->_updates.flags.any()) {
        func(_vertices, _indices);
    } else {
        throw std::runtime_error("write failed.");
    }
}

std::size_t mesh_data::vertex_buffer_byte_offset() {
    return 0;
}

std::size_t mesh_data::index_buffer_byte_offset() {
    return 0;
}

id<MTLBuffer> mesh_data::vertexBuffer() {
    return this->_vertex_buffer->rawBuffer();
}

id<MTLBuffer> mesh_data::indexBuffer() {
    return this->_index_buffer->rawBuffer();
}

mesh_data_updates_t const &mesh_data::updates() {
    return this->_updates;
}

void mesh_data::update_render_buffer() {
    if (this->_updates.test(mesh_data_update_reason::render_buffer)) {
        this->_dynamic_buffer_index = (this->_dynamic_buffer_index + 1) % this->dynamic_buffer_count();

        if (this->_vertex_buffer && this->_index_buffer) {
            this->_vertex_buffer->write_from_vertices(this->_vertices, this->_dynamic_buffer_index);
            this->_index_buffer->write_from_indices(this->_indices, this->_dynamic_buffer_index);
        }

        this->_updates.reset(mesh_data_update_reason::render_buffer);
    }
}

void mesh_data::clear_updates() {
    this->_updates.flags.reset();
}

setup_metal_result mesh_data::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    if (this->_metal_system != system) {
        this->_metal_system = system;
        this->_vertex_buffer = nullptr;
        this->_index_buffer = nullptr;
    }

    if (!this->_vertex_buffer) {
        auto const vertex_length = this->_vertices.size() * sizeof(vertex2d_t) * this->dynamic_buffer_count();

        this->_vertex_buffer = system->make_metal_buffer(vertex_length);

        if (!this->_vertex_buffer) {
            return setup_metal_result{setup_metal_error::create_vertex_buffer_failed};
        }
    }

    if (!this->_index_buffer) {
        auto const index_length = this->_indices.size() * sizeof(index2d_t) * dynamic_buffer_count();

        this->_index_buffer = system->make_metal_buffer(index_length);

        if (!this->_index_buffer) {
            return setup_metal_result{setup_metal_error::create_index_buffer_failed};
        }
    }

    return setup_metal_result{nullptr};
}

std::size_t mesh_data::dynamic_buffer_count() {
    return 1;
}

std::shared_ptr<mesh_data> mesh_data::make_shared(mesh_data_args &&args) {
    return std::shared_ptr<mesh_data>(new mesh_data{std::move(args)});
}

#pragma mark - dynamic_mesh_data

dynamic_mesh_data::dynamic_mesh_data(mesh_data_args &&args) : mesh_data(std::move(args)) {
    this->_updates.flags.reset();
}

dynamic_mesh_data::~dynamic_mesh_data() = default;

std::size_t dynamic_mesh_data::vertex_buffer_byte_offset() {
    return this->_vertices.size() * this->_dynamic_buffer_index * sizeof(vertex2d_t);
}

std::size_t dynamic_mesh_data::index_buffer_byte_offset() {
    return this->_indices.size() * this->_dynamic_buffer_index * sizeof(index2d_t);
}

std::size_t dynamic_mesh_data::max_vertex_count() const {
    return this->_vertices.size();
}

std::size_t dynamic_mesh_data::max_index_count() const {
    return this->_indices.size();
}

void dynamic_mesh_data::set_vertex_count(std::size_t const count) {
    if (this->_vertices.size() < count) {
        throw std::string(__PRETTY_FUNCTION__) + " : out of range";
    }

    this->_vertex_count = count;

    this->_updates.set(mesh_data_update_reason::vertex_count);
}

void dynamic_mesh_data::set_index_count(std::size_t const count) {
    if (this->_indices.size() < count) {
        throw std::string(__PRETTY_FUNCTION__) + " : out of range";
    }

    this->_index_count = count;

    this->_updates.set(mesh_data_update_reason::index_count);
}

void dynamic_mesh_data::write(std::function<void(std::vector<vertex2d_t> &, std::vector<index2d_t> &)> const &func) {
    func(_vertices, _indices);

    this->_updates.set(mesh_data_update_reason::data);
    this->_updates.set(mesh_data_update_reason::render_buffer);
}

std::size_t dynamic_mesh_data::dynamic_buffer_count() {
    return 2;
}

std::shared_ptr<dynamic_mesh_data> dynamic_mesh_data::make_shared(mesh_data_args &&args) {
    return std::shared_ptr<dynamic_mesh_data>(new dynamic_mesh_data{std::move(args)});
}
