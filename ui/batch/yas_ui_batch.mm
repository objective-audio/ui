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
using namespace yas::ui;

batch::batch() {
}

batch::~batch() = default;

std::vector<std::shared_ptr<mesh>> const &batch::meshes() {
    return this->_render_meshes;
}

void batch::begin_render_meshes_building(batch_building_type const type) {
    if (type == batch_building_type::rebuild) {
        this->clear_render_meshes();
    }

    this->_building_type = type;
}

void batch::commit_render_meshes_building() {
    if (!to_bool(this->_building_type)) {
        throw std::runtime_error("don't commit if batch_building_type is none.");
    }

    for (auto &mesh_info : this->_render_mesh_infos) {
        if (this->_building_type == batch_building_type::rebuild) {
            auto render_mesh_data = dynamic_mesh_data::make_shared(
                {.vertex_count = mesh_info.vertex_count, .index_count = mesh_info.index_count});
            mesh_info.render_mesh->set_mesh_data(render_mesh_data);
            mesh_info.mesh_data = std::move(render_mesh_data);
        } else if (this->_building_type == batch_building_type::overwrite) {
            mesh_info.vertex_idx = 0;
            mesh_info.index_idx = 0;
        }

        for (auto const &src_mesh : mesh_info.src_meshes) {
            auto const src_mesh_renderable = renderable_mesh::cast(src_mesh);
            if (src_mesh_renderable->pre_render()) {
                src_mesh_renderable->batch_render(mesh_info, this->_building_type);
            }
        }
    }

    if (this->_building_type == batch_building_type::rebuild) {
        std::vector<std::shared_ptr<mesh>> render_meshes;
        render_meshes.reserve(this->_render_mesh_infos.size());
        for (batch_render_mesh_info const &mesh_info : this->_render_mesh_infos) {
            auto const &render_mesh = mesh_info.render_mesh;
            auto const &mesh_data = render_mesh->mesh_data();
            if (mesh_data && mesh_data->data_exists()) {
                render_meshes.push_back(render_mesh);
            }
        }
        this->_render_meshes = std::move(render_meshes);
    }

    if (auto &metal_system = this->_metal_system) {
        for (auto const &mesh : this->_render_meshes) {
            if (auto ul = unless(metal_object::cast(mesh)->metal_setup(metal_system))) {
                throw std::runtime_error("render_meshes setup failed.");
            };
        }
    }

    this->_building_type = batch_building_type::none;
}

void batch::clear_render_meshes() {
    this->_render_meshes.clear();
    this->_render_mesh_infos.clear();
}

void batch::append_mesh(std::shared_ptr<mesh> const &mesh) {
    if (this->_building_type == batch_building_type::rebuild) {
        batch_render_mesh_info &mesh_info = this->_find_or_make_mesh_info(mesh->texture());

        auto const renderable_mesh = renderable_mesh::cast(mesh);
        mesh_info.vertex_count += renderable_mesh->render_vertex_count();
        mesh_info.index_count += renderable_mesh->render_index_count();

        mesh_info.src_meshes.push_back(mesh);
    }
}

setup_metal_result batch::metal_setup(std::shared_ptr<metal_system> const &system) {
    if (this->_metal_system != system) {
        this->_metal_system = system;
    }

    return setup_metal_result{nullptr};
}

batch_render_mesh_info &batch::_find_or_make_mesh_info(std::shared_ptr<texture> const &texture) {
    for (auto &info : this->_render_mesh_infos) {
        if (info.render_mesh->texture() == texture) {
            return info;
        }
    }

    return this->_add_mesh_info(texture);
}

batch_render_mesh_info &batch::_add_mesh_info(std::shared_ptr<texture> const &texture) {
    this->_render_mesh_infos.emplace_back(batch_render_mesh_info{});
    auto &info = this->_render_mesh_infos.back();
    info.render_mesh->set_texture(texture);
    info.render_mesh->set_use_mesh_color(true);
    return info;
}

std::shared_ptr<batch> batch::make_shared() {
    return std::shared_ptr<batch>(new batch{});
}
