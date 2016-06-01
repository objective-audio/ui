//
//  yas_ui_batch.mm
//

#include "yas_stl_utils.h"
#include "yas_ui_batch.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_batch_render_mesh_info.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_node.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::batch::impl : base::impl, renderable_batch::impl, render_encodable::impl {
    void push_back_mesh(ui::mesh &&mesh) override {
        ui::batch_render_mesh_info &mesh_info = _find_or_make_mesh_info(mesh.texture());

        auto renderable_mesh = mesh.renderable();
        mesh_info.vertex_count += renderable_mesh.render_vertex_count();
        mesh_info.index_count += renderable_mesh.render_index_count();

        mesh_info.src_meshes.emplace_back(std::move(mesh));
    }

    std::vector<ui::mesh> &meshes() override {
        return _render_meshes;
    }

    void commit() override {
        for (auto &mesh_info : _render_mesh_infos) {
            ui::dynamic_mesh_data render_mesh_data{mesh_info.vertex_count, mesh_info.index_count};
            mesh_info.render_mesh.set_mesh_data(render_mesh_data);
            mesh_info.mesh_data = std::move(render_mesh_data);

            for (auto &src_mesh : mesh_info.src_meshes) {
                src_mesh.renderable().batch_render(mesh_info);
            }
        }

        _render_meshes =
            yas::to_vector<ui::mesh>(_render_mesh_infos, [](auto const &mesh_info) { return mesh_info.render_mesh; });
        _render_mesh_infos.clear();
    }

    void clear() override {
        _render_meshes.clear();
        _render_mesh_infos.clear();
    }

   private:
    std::vector<ui::batch_render_mesh_info> _render_mesh_infos;
    std::vector<ui::mesh> _render_meshes;

    ui::batch_render_mesh_info &_find_or_make_mesh_info(ui::texture const &texture) {
        for (auto &info : _render_mesh_infos) {
            if (is_same(info.render_mesh.texture(), texture)) {
                return info;
            }
        }

        return _add_mesh_info(texture);
    }

    ui::batch_render_mesh_info &_add_mesh_info(ui::texture texture) {
        _render_mesh_infos.emplace_back(ui::batch_render_mesh_info{});
        auto &info = _render_mesh_infos.back();
        info.render_mesh.set_texture(texture);
        info.render_mesh.set_use_mesh_color(true);
        return info;
    }
};

ui::batch::batch() : base(std::make_shared<impl>()) {
}

ui::batch::batch(std::nullptr_t) : base(nullptr) {
}

ui::renderable_batch ui::batch::renderable() {
    return ui::renderable_batch{impl_ptr<ui::renderable_batch::impl>()};
}

ui::render_encodable ui::batch::encodable() {
    return ui::render_encodable{impl_ptr<ui::render_encodable::impl>()};
}
