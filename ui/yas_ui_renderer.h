//
//  yas_ui_renderer.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <vector>
#include "yas_base.h"
#include "yas_ui_renderer_protocol.h"

namespace yas {
template <typename T, typename K>
class subject;

namespace ui {
    class view_renderable;
    class event_manager;
    class uint_size;
    class node;
    class action;
    class collision_detector;
    class metal_system;
    enum class system_type;
    enum class renderer_method;

    class renderer : public base {
       public:
        class impl;

        renderer();
        explicit renderer(id<MTLDevice> const);
        renderer(std::nullptr_t);

        ui::uint_size const &view_size() const;
        ui::uint_size const &drawable_size() const;
        double scale_factor() const;
        simd::float4x4 const &projection_matrix() const;

        ui::system_type system_type() const;
        ui::metal_system const &metal_system() const;
        ui::metal_system &metal_system();

        ui::node const &root_node() const;
        ui::node &root_node();

        ui::view_renderable &view_renderable();

        subject<ui::renderer, ui::renderer_method> &subject();

        ui::event_manager &event_manager();

        std::vector<ui::action> actions() const;
        void insert_action(ui::action);
        void erase_action(ui::action const &);
        void erase_action(ui::node const &target);

        ui::collision_detector const &collision_detector() const;
        ui::collision_detector &collision_detector();

       private:
        ui::view_renderable _view_renderable = nullptr;

        explicit renderer(std::shared_ptr<impl> &&);
    };
}
}
