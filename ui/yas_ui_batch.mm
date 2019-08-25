//
//  yas_ui_batch.mm
//

#include "yas_ui_batch.h"
#include <cpp_utils/yas_stl_utils.h>
#include <cpp_utils/yas_to_bool.h>
#include <cpp_utils/yas_unless.h>
#include "yas_ui_batch_render_mesh_info.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_node.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::batch::impl : metal_object::impl {
    void append_mesh(ui::mesh_ptr const &mesh) {
        if (this->_building_type == ui::batch_building_type::rebuild) {
            ui::batch_render_mesh_info &mesh_info = this->_find_or_make_mesh_info(mesh->texture());

            auto const renderable_mesh = mesh->renderable();
            mesh_info.vertex_count += renderable_mesh->render_vertex_count();
            mesh_info.index_count += renderable_mesh->render_index_count();

            mesh_info.src_meshes.emplace_back(std::move(mesh));
        }
    }

    std::vector<ui::mesh_ptr> &meshes() {
        return this->_render_meshes;
    }

    void begin_render_meshes_building(ui::batch_building_type const building_type) {
        if (building_type == ui::batch_building_type::rebuild) {
            this->clear_render_meshes();
        }

        this->_building_type = building_type;
    }

    void commit_render_meshes_building() {
        if (!to_bool(this->_building_type)) {
            throw "don't commit if batch_building_type is none.";
        }

        for (auto &mesh_info : this->_render_mesh_infos) {
            if (this->_building_type == ui::batch_building_type::rebuild) {
                auto render_mesh_data = ui::dynamic_mesh_data::make_shared(
                    {.vertex_count = mesh_info.vertex_count, .index_count = mesh_info.index_count});
                mesh_info.render_mesh->set_mesh_data(render_mesh_data);
                mesh_info.mesh_data = std::move(render_mesh_data);
            } else if (this->_building_type == ui::batch_building_type::overwrite) {
                mesh_info.vertex_idx = 0;
                mesh_info.index_idx = 0;
            }

            for (auto const &src_mesh : mesh_info.src_meshes) {
                auto const src_mesh_renderable = src_mesh->renderable();
                if (src_mesh_renderable->pre_render()) {
                    src_mesh_renderable->batch_render(mesh_info, this->_building_type);
                }
            }
        }

        if (this->_building_type == ui::batch_building_type::rebuild) {
            this->_render_meshes = yas::to_vector<ui::mesh_ptr>(
                this->_render_mesh_infos, [](auto const &mesh_info) { return mesh_info.render_mesh; });
        }

        if (auto &metal_system = this->_metal_system) {
            for (auto const &mesh : this->_render_meshes) {
                if (auto ul = unless(mesh->metal().metal_setup(metal_system))) {
                    throw std::runtime_error("render_meshes setup failed.");
                };
            }
        }

        this->_building_type = ui::batch_building_type::none;
    }

    void clear_render_meshes() {
        this->_render_meshes.clear();
        this->_render_mesh_infos.clear();
    }

    ui::setup_metal_result metal_setup(ui::metal_system_ptr const &metal_system) override {
        if (this->_metal_system != metal_system) {
            this->_metal_system = metal_system;
        }

        return ui::setup_metal_result{nullptr};
    }

   private:
    std::vector<ui::batch_render_mesh_info> _render_mesh_infos;
    std::vector<ui::mesh_ptr> _render_meshes;
    ui::batch_building_type _building_type = ui::batch_building_type::none;
    ui::metal_system_ptr _metal_system = nullptr;

    ui::batch_render_mesh_info &_find_or_make_mesh_info(ui::texture_ptr const &texture) {
        for (auto &info : this->_render_mesh_infos) {
            if (info.render_mesh->texture() == texture) {
                return info;
            }
        }

        return this->_add_mesh_info(texture);
    }

    ui::batch_render_mesh_info &_add_mesh_info(ui::texture_ptr const &texture) {
        this->_render_mesh_infos.emplace_back(ui::batch_render_mesh_info{});
        auto &info = this->_render_mesh_infos.back();
        info.render_mesh->set_texture(texture);
        info.render_mesh->set_use_mesh_color(true);
        return info;
    }
};

ui::batch::batch() : _impl(std::make_shared<impl>()) {
}

ui::batch::~batch() = default;

std::vector<ui::mesh_ptr> const &ui::batch::meshes() {
    return this->_impl->meshes();
}

void ui::batch::begin_render_meshes_building(batch_building_type const type) {
    this->_impl->begin_render_meshes_building(type);
}

void ui::batch::commit_render_meshes_building() {
    this->_impl->commit_render_meshes_building();
}

void ui::batch::clear_render_meshes() {
    this->_impl->clear_render_meshes();
}

void ui::batch::append_mesh(ui::mesh_ptr const &mesh) {
    this->_impl->append_mesh(mesh);
}

std::shared_ptr<ui::renderable_batch> ui::batch::renderable() {
    return std::dynamic_pointer_cast<renderable_batch>(shared_from_this());
}

std::shared_ptr<ui::render_encodable> ui::batch::encodable() {
    return std::dynamic_pointer_cast<render_encodable>(shared_from_this());
}

ui::metal_object &ui::batch::metal() {
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{this->_impl};
    }
    return this->_metal_object;
}

ui::batch_ptr ui::batch::make_shared() {
    return std::shared_ptr<batch>(new batch{});
}
