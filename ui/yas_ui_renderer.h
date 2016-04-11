//
//  yas_ui_renderer.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include "yas_base.h"
#include "yas_observing.h"

namespace yas {
namespace ui {
    struct view_renderable;

    class renderer : public base {
        using super_class = base;

       public:
        renderer(std::nullptr_t);

        simd::float4x4 const &projection_matrix() const;
        id<MTLBuffer> current_constant_buffer() const;

        UInt32 constant_buffer_offset() const;
        void set_constant_buffer_offset(UInt32 const);

        ui::view_renderable view_renderable();
        subject<renderer> &subject();

        class impl;

       protected:
        renderer(std::shared_ptr<impl> &&);
    };

    class node;
    class action;

    class node_renderer : public renderer {
        using super_class = renderer;

       public:
        node_renderer(id<MTLDevice> const);
        node_renderer(std::nullptr_t);

        ui::node const &root_node() const;

        std::vector<ui::action> actions() const;
        void insert_action(ui::action action);
        void erase_action(ui::action const &action);
        void erase_action(ui::node const &target);

        class impl;
    };
}
}

#include "yas_ui_renderer_impl.h"
