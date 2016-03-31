//
//  yas_ui_action.h
//

#pragma once

#include <simd/simd.h>
#include <chrono>
#include "yas_base.h"
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class node;
    using time_point_t = std::chrono::time_point<std::chrono::system_clock>;

    struct updatable_action : public protocol {
        struct impl : protocol::impl {
            virtual void update(time_point_t const &time) = 0;
            virtual void set_finish_handler(std::function<void(void)> &&) = 0;
        };

        explicit updatable_action(std::shared_ptr<impl> &&);

        void update(time_point_t const &time);
        void set_finish_handler(std::function<void(void)>);
    };

    enum class action_curve {
        linear,
        ease_in,
        ease_out,
        ease_in_out,
    };

    class action : public base {
        using super_class = base;

       public:
        using update_f = std::function<void(double const)>;

        action(std::nullptr_t);

        ui::node target() const;
        time_point_t const &start_time() const;
        double duration() const;
        action_curve curve() const;

        void set_target(ui::node);
        void set_start_time(time_point_t);
        void set_duration(double const &);
        void set_curve(action_curve const);

        updatable_action updatable();

       protected:
        class impl;

        action(std::shared_ptr<impl> &&);
    };

    class translate_action : public action {
        using super_class = action;

       public:
        translate_action();
        translate_action(std::nullptr_t);

        simd::float2 const &start_position() const;
        simd::float2 const &end_position() const;

        void set_start_position(simd::float2);
        void set_end_position(simd::float2);

        class impl;
    };

    class rotate_action : public action {
        using super_class = action;

       public:
        rotate_action();
        rotate_action(std::nullptr_t);

        float start_angle() const;
        float end_angle() const;
        bool is_shortest() const;

        void set_start_angle(float const);
        void set_end_angle(float const);
        void set_shortest(bool const);

        class impl;
    };

    class scale_action : public action {
        using super_class = action;

       public:
        scale_action();
        scale_action(std::nullptr_t);

        simd::float2 const &start_scale() const;
        simd::float2 const &end_scale() const;

        void set_start_scale(simd::float2);
        void set_end_scale(simd::float2);

        class impl;
    };

    class color_action : public action {
        using super_class = action;

       public:
        color_action();
        color_action(std::nullptr_t);

        simd::float4 const &start_color() const;
        simd::float4 const &end_color() const;

        void set_start_color(simd::float4);
        void set_end_color(simd::float4);

        class impl;
    };
}

std::string to_string(ui::action_curve const);
}

template <>
struct std::hash<yas::ui::action> {
    std::size_t operator()(yas::ui::action const &key) const {
        return std::hash<uintptr_t>()(key.identifier());
    }
};
