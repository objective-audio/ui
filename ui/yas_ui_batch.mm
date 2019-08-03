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

struct ui::batch::impl : base::impl, render_encodable::impl, metal_object::impl {
    void append_mesh(ui::mesh &&mesh) override {
        if (this->_building_type == ui::batch_building_type::rebuild) {
            ui::batch_render_mesh_info &mesh_info = this->_find_or_make_mesh_info(mesh.texture());

            auto &renderable_mesh = mesh.renderable();
            mesh_info.vertex_count += renderable_mesh.render_vertex_count();
            mesh_info.index_count += renderable_mesh.render_index_count();

            mesh_info.src_meshes.emplace_back(std::move(mesh));
        }
    }

    std::vector<ui::mesh> &meshes() {
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
                ui::dynamic_mesh_data render_mesh_data{
                    {.vertex_count = mesh_info.vertex_count, .index_count = mesh_info.index_count}};
                mesh_info.render_mesh.set_mesh_data(render_mesh_data);
                mesh_info.mesh_data = std::move(render_mesh_data);
            } else if (this->_building_type == ui::batch_building_type::overwrite) {
                mesh_info.vertex_idx = 0;
                mesh_info.index_idx = 0;
            }

            for (auto &src_mesh : mesh_info.src_meshes) {
                auto &src_mesh_renderable = src_mesh.renderable();
                if (src_mesh_renderable.pre_render()) {
                    src_mesh.renderable().batch_render(mesh_info, this->_building_type);
                }
            }
        }

        if (this->_building_type == ui::batch_building_type::rebuild) {
            this->_render_meshes = yas::to_vector<ui::mesh>(
                this->_render_mesh_infos, [](auto const &mesh_info) { return mesh_info.render_mesh; });
        }

        if (auto &metal_system = this->_metal_system) {
            for (auto &mesh : this->_render_meshes) {
                if (auto ul = unless(mesh.metal().metal_setup(metal_system))) {
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

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) override {
        if (!is_same(this->_metal_system, metal_system)) {
            this->_metal_system = metal_system;
        }

        return ui::setup_metal_result{nullptr};
    }

   private:
    std::vector<ui::batch_render_mesh_info> _render_mesh_infos;
    std::vector<ui::mesh> _render_meshes;
    ui::batch_building_type _building_type = ui::batch_building_type::none;
    ui::metal_system _metal_system = nullptr;

    ui::batch_render_mesh_info &_find_or_make_mesh_info(ui::texture const &texture) {
        for (auto &info : this->_render_mesh_infos) {
            if (is_same(info.render_mesh.texture(), texture)) {
                return info;
            }
        }

        return this->_add_mesh_info(texture);
    }

    ui::batch_render_mesh_info &_add_mesh_info(ui::texture texture) {
        this->_render_mesh_infos.emplace_back(ui::batch_render_mesh_info{});
        auto &info = this->_render_mesh_infos.back();
        info.render_mesh.set_texture(texture);
        info.render_mesh.set_use_mesh_color(true);
        return info;
    }
};

ui::batch::batch() : base(std::make_shared<impl>()) {
}

ui::batch::~batch() = default;

std::vector<ui::mesh> &ui::batch::meshes() {
    return impl_ptr<impl>()->meshes();
}

void ui::batch::begin_render_meshes_building(batch_building_type const type) {
    impl_ptr<impl>()->begin_render_meshes_building(type);
}

void ui::batch::commit_render_meshes_building() {
    impl_ptr<impl>()->commit_render_meshes_building();
}

void ui::batch::clear_render_meshes() {
    impl_ptr<impl>()->clear_render_meshes();
}

std::shared_ptr<ui::renderable_batch> ui::batch::renderable() {
    return std::dynamic_pointer_cast<renderable_batch>(shared_from_this());
}

ui::render_encodable &ui::batch::encodable() {
    if (!this->_encodable) {
        this->_encodable = ui::render_encodable{impl_ptr<ui::render_encodable::impl>()};
    }
    return this->_encodable;
}

ui::metal_object &ui::batch::metal() {
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return this->_metal_object;
}

std::unique_ptr<ui::batch> ui::batch::make_unique() {
    return std::unique_ptr<batch>(new batch{});
}
