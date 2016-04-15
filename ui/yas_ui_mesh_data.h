//
//  yas_ui_mesh_data.h
//

#pragma once

#include <vector>
#include "yas_base.h"
#include "yas_ui_mesh_protocol.h"
#include "yas_ui_metal_protocol.h"
#include "yas_ui_shared_types.h"

namespace yas {
namespace ui {
    class mesh_data : public base {
        using super_class = base;

       public:
        mesh_data(std::size_t const vertex_count, std::size_t const index_count);
        mesh_data(std::nullptr_t);

        const ui::vertex2d_t *vertices() const;
        std::size_t vertex_count() const;
        const UInt16 *indices() const;
        std::size_t index_count() const;

        void write(std::function<void(std::vector<ui::vertex2d_t> &, std::vector<UInt16> &)> const &);

        ui::metal_object metal();
        ui::renderable_mesh_data renderable();

       protected:
        class impl;

        mesh_data(std::shared_ptr<impl> &&);
    };

    class dynamic_mesh_data : public mesh_data {
        using super_class = mesh_data;

       public:
        dynamic_mesh_data(std::size_t const max_vertex_count, std::size_t const max_index_count);
        dynamic_mesh_data(std::nullptr_t);

        void set_vertex_count(std::size_t const);
        void set_index_count(std::size_t const);

       private:
        class impl;
    };
}
}