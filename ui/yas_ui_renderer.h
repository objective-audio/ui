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
    enum class renderer_method;

    class renderer : public base {
       public:
        class impl;

        explicit renderer(id<MTLDevice> const);
        renderer(std::nullptr_t);

        id<MTLDevice> device() const;

        ui::uint_size const &view_size() const;
        ui::uint_size const &drawable_size() const;
        double scale_factor() const;
        simd::float4x4 const &projection_matrix() const;
        id<MTLBuffer> currentConstantBuffer() const;

        uint32_t constant_buffer_offset() const;
        void set_constant_buffer_offset(uint32_t const);

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

       protected:
        renderer(std::shared_ptr<impl> &&);

       private:
        ui::view_renderable _view_renderable = nullptr;
    };
}
}
