//
//  yas_ui_mesh_data.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_ui_mesh_data_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class mesh_data : public base {
       public:
        mesh_data(std::size_t const vertex_count, std::size_t const index_count);
        mesh_data(std::nullptr_t);

        const ui::vertex2d_t *vertices() const;
        std::size_t vertex_count() const;
        const ui::index2d_t *indices() const;
        std::size_t index_count() const;

        void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<ui::index2d_t> &)> const &);

        ui::metal_object &metal();
        ui::renderable_mesh_data &renderable();

       protected:
        class impl;

        mesh_data(std::shared_ptr<impl> &&);

       private:
        ui::metal_object _metal_object = nullptr;
        ui::renderable_mesh_data _renderable = nullptr;
    };

    class dynamic_mesh_data : public mesh_data {
        class impl;

       public:
        dynamic_mesh_data(std::size_t const max_vertex_count, std::size_t const max_index_count);
        dynamic_mesh_data(std::nullptr_t);

        std::size_t max_vertex_count() const;
        std::size_t max_index_count() const;

        void set_vertex_count(std::size_t const);
        void set_index_count(std::size_t const);
    };
}
}