//
//  yas_ui_renderer.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <vector>
#include "yas_base.h"

namespace yas {
template <typename T, typename K>
class subject;

namespace ui {
    class view_renderable;
    class event_manager;
    class uint_size;
    enum class renderer_method;

    class renderer_base : public base {
       public:
        class impl;

        renderer_base(std::nullptr_t);

        id<MTLDevice> device() const;

        ui::uint_size const &view_size() const;
        ui::uint_size const &drawable_size() const;
        double scale_factor() const;
        simd::float4x4 const &projection_matrix() const;
        id<MTLBuffer> current_constant_buffer() const;

        uint32_t constant_buffer_offset() const;
        void set_constant_buffer_offset(uint32_t const);

        ui::view_renderable view_renderable();

        subject<ui::renderer_base, ui::renderer_method> &subject();

        ui::event_manager &event_manager();

       protected:
        renderer_base(std::shared_ptr<impl> &&);
    };

    class node;
    class action;
    class collision_detector;

    class renderer : public renderer_base {
       public:
        class impl;

        explicit renderer(id<MTLDevice> const);
        renderer(std::nullptr_t);

        ui::node const &root_node() const;
        ui::node &root_node();

        std::vector<ui::action> actions() const;
        void insert_action(ui::action action);
        void erase_action(ui::action const &action);
        void erase_action(ui::node const &target);

        ui::collision_detector const &collision_detector() const;
        ui::collision_detector &collision_detector();
    };
}
}

#include "yas_ui_renderer_impl.h"
