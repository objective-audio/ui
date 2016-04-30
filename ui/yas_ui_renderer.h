//
//  yas_ui_renderer.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include "yas_base.h"
#include "yas_observing.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class view_renderable;
    class event_manager;
    enum class renderer_method;

    class renderer : public base {
       public:
        class impl;

        renderer(std::nullptr_t);

        id<MTLDevice> device() const;

        ui::uint_size const &view_size() const;
        ui::uint_size const &drawable_size() const;
        simd::float4x4 const &projection_matrix() const;
        id<MTLBuffer> current_constant_buffer() const;

        uint32_t constant_buffer_offset() const;
        void set_constant_buffer_offset(uint32_t const);

        ui::view_renderable view_renderable();

        subject<renderer, renderer_method> &subject();

        ui::event_manager &event_manager();

       protected:
        renderer(std::shared_ptr<impl> &&);
    };

    class node;
    class action;
    class collision_detector;

    class node_renderer : public renderer {
       public:
        class impl;

        node_renderer(id<MTLDevice> const);
        node_renderer(std::nullptr_t);

        ui::node const &root_node() const;

        std::vector<ui::action> actions() const;
        void insert_action(ui::action action);
        void erase_action(ui::action const &action);
        void erase_action(ui::node const &target);

        ui::collision_detector collision_detector();
    };
}
}

#include "yas_ui_renderer_impl.h"
