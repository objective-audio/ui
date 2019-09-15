//
//  yas_ui_mesh_data.mm
//

#include "yas_ui_mesh_data.h"
#include <cpp_utils/yas_objc_ptr.h>
#include "yas_ui_metal_system.h"

using namespace yas;

#pragma mark - ui::mesh_data::impl

struct ui::mesh_data::impl {
    impl(mesh_data::args &&args)
        : _vertex_count(args.vertex_count),
          _vertices(args.vertex_count),
          _index_count(args.index_count),
          _indices(args.index_count) {
        this->_updates.flags.set();
    }

    ui::setup_metal_result metal_setup(ui::metal_system_ptr const &metal_system) {
        if (this->_metal_system != metal_system) {
            this->_metal_system = metal_system;
            this->_vertex_buffer.set_object(nil);
            this->_index_buffer.set_object(nil);
        }

        if (!this->_vertex_buffer) {
            auto const vertex_length = this->_vertices.size() * sizeof(ui::vertex2d_t) * this->dynamic_buffer_count();

            this->_vertex_buffer = this->_metal_system->makable()->make_mtl_buffer(vertex_length);

            if (!this->_vertex_buffer) {
                return ui::setup_metal_result{ui::setup_metal_error::create_vertex_buffer_failed};
            }
        }

        if (!this->_index_buffer) {
            auto const index_length = this->_indices.size() * sizeof(ui::index2d_t) * dynamic_buffer_count();

            this->_index_buffer = this->_metal_system->makable()->make_mtl_buffer(index_length);

            if (!this->_index_buffer) {
                return ui::setup_metal_result{ui::setup_metal_error::create_index_buffer_failed};
            }
        }

        return ui::setup_metal_result{nullptr};
    }

    void update_render_buffer() {
        if (this->_updates.test(ui::mesh_data_update_reason::render_buffer)) {
            this->_dynamic_buffer_index = (this->_dynamic_buffer_index + 1) % this->dynamic_buffer_count();

            auto vertex_ptr = static_cast<ui::vertex2d_t *>([this->_vertex_buffer.object() contents]);
            auto index_ptr = static_cast<ui::index2d_t *>([this->_index_buffer.object() contents]);

            memcpy(&vertex_ptr[this->_vertices.size() * this->_dynamic_buffer_index], this->_vertices.data(),
                   this->_vertices.size() * sizeof(ui::vertex2d_t));
            memcpy(&index_ptr[this->_indices.size() * this->_dynamic_buffer_index], this->_indices.data(),
                   this->_indices.size() * sizeof(ui::index2d_t));

            this->_updates.reset(ui::mesh_data_update_reason::render_buffer);
        }
    }

    virtual void clear_updates() {
        this->_updates.flags.reset();
    }

    virtual std::size_t vertex_buffer_byte_offset() {
        return 0;
    }

    virtual std::size_t index_buffer_byte_offset() {
        return 0;
    }

    virtual id<MTLBuffer> vertexBuffer() {
        return this->_vertex_buffer.object();
    }

    virtual id<MTLBuffer> indexBuffer() {
        return this->_index_buffer.object();
    }

    virtual mesh_data_updates_t const &updates() {
        return this->_updates;
    }

    virtual void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &func) {
        if (this->_updates.flags.any()) {
            func(_vertices, _indices);
        } else {
            throw "write failed.";
        }
    }

    virtual std::size_t dynamic_buffer_count() {
        return 1;
    }

    std::size_t _vertex_count;
    std::size_t _index_count;

    std::vector<ui::vertex2d_t> _vertices;
    std::vector<ui::index2d_t> _indices;

    ui::metal_system_ptr _metal_system = nullptr;

   protected:
    std::size_t _dynamic_buffer_index = 0;

    objc_ptr<id<MTLBuffer>> _vertex_buffer;
    objc_ptr<id<MTLBuffer>> _index_buffer;

    mesh_data_updates_t _updates;
};

#pragma mark - ui::mesh_data

ui::mesh_data::mesh_data(args &&args) : _impl(std::make_shared<impl>(std::move(args))) {
}

ui::mesh_data::mesh_data(std::shared_ptr<impl> &&impl) : _impl(std::move(impl)) {
}

const ui::vertex2d_t *ui::mesh_data::vertices() const {
    return this->_impl->_vertices.data();
}

std::size_t ui::mesh_data::vertex_count() const {
    return this->_impl->_vertex_count;
}

const ui::index2d_t *ui::mesh_data::indices() const {
    return this->_impl->_indices.data();
}

std::size_t ui::mesh_data::index_count() const {
    return this->_impl->_index_count;
}

void ui::mesh_data::write(
    std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &func) {
    this->_impl->write(func);
}

ui::metal_system_ptr const &ui::mesh_data::metal_system() {
    return this->_impl->_metal_system;
}

std::size_t ui::mesh_data::vertex_buffer_byte_offset() {
    return this->_impl->vertex_buffer_byte_offset();
}

std::size_t ui::mesh_data::index_buffer_byte_offset() {
    return this->_impl->index_buffer_byte_offset();
}

id<MTLBuffer> ui::mesh_data::vertexBuffer() {
    return this->_impl->vertexBuffer();
}

id<MTLBuffer> ui::mesh_data::indexBuffer() {
    return this->_impl->indexBuffer();
}

ui::mesh_data_updates_t const &ui::mesh_data::updates() {
    return this->_impl->updates();
}

void ui::mesh_data::update_render_buffer() {
    this->_impl->update_render_buffer();
}

void ui::mesh_data::clear_updates() {
    this->_impl->clear_updates();
}

ui::setup_metal_result ui::mesh_data::metal_setup(std::shared_ptr<ui::metal_system> const &system) {
    return this->_impl->metal_setup(system);
}

ui::mesh_data_ptr ui::mesh_data::make_shared(args args) {
    return std::shared_ptr<mesh_data>(new mesh_data{std::move(args)});
}

#pragma mark - dynamic_mesh_data::impl

struct ui::dynamic_mesh_data::impl : ui::mesh_data::impl {
    impl(mesh_data::args args) : mesh_data::impl(std::move(args)) {
        this->_updates.flags.reset();
    }

    void set_vertex_count(std::size_t const count) {
        if (this->_vertices.size() < count) {
            throw std::string(__PRETTY_FUNCTION__) + " : out of range";
        }

        this->_vertex_count = count;

        this->_updates.set(ui::mesh_data_update_reason::vertex_count);
    }

    void set_index_count(std::size_t const count) {
        if (this->_indices.size() < count) {
            throw std::string(__PRETTY_FUNCTION__) + " : out of range";
        }

        this->_index_count = count;

        this->_updates.set(ui::mesh_data_update_reason::index_count);
    }

    std::size_t vertex_buffer_byte_offset() override {
        return this->_vertices.size() * this->_dynamic_buffer_index * sizeof(ui::vertex2d_t);
    }

    std::size_t index_buffer_byte_offset() override {
        return this->_indices.size() * this->_dynamic_buffer_index * sizeof(ui::index2d_t);
    }

    void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &func) override {
        func(_vertices, _indices);

        this->_updates.set(ui::mesh_data_update_reason::data);
        this->_updates.set(ui::mesh_data_update_reason::render_buffer);
    }

    std::size_t dynamic_buffer_count() override {
        return 2;
    }
};

#pragma mark - dynamic_mesh_data

ui::dynamic_mesh_data::dynamic_mesh_data(mesh_data::args &&args) : mesh_data(std::make_shared<impl>(std::move(args))) {
}

ui::dynamic_mesh_data::~dynamic_mesh_data() = default;

std::size_t ui::dynamic_mesh_data::max_vertex_count() const {
    return this->_impl->_vertices.size();
}

std::size_t ui::dynamic_mesh_data::max_index_count() const {
    return this->_impl->_indices.size();
}

void ui::dynamic_mesh_data::set_vertex_count(std::size_t const count) {
    std::dynamic_pointer_cast<impl>(this->_impl)->set_vertex_count(count);
}

void ui::dynamic_mesh_data::set_index_count(std::size_t const count) {
    std::dynamic_pointer_cast<impl>(this->_impl)->set_index_count(count);
}

ui::dynamic_mesh_data_ptr ui::dynamic_mesh_data::make_shared(args args) {
    return std::shared_ptr<dynamic_mesh_data>(new dynamic_mesh_data{std::move(args)});
}
