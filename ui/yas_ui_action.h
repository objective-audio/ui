//
//  yas_ui_action.h
//

#pragma once

#include <simd/simd.h>
#include <chrono>
#include <vector>
#include "yas_base.h"
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class node;
    using time_point_t = std::chrono::time_point<std::chrono::system_clock>;
    using duration_t = std::chrono::duration<double>;
    using action_update_f = std::function<bool(time_point_t const &)>;
    using action_finish_f = std::function<void(void)>;
    using action_transform_f = std::function<float(float const)>;
    using action_completion_f = std::function<void(void)>;

    struct updatable_action : public protocol {
        struct impl : protocol::impl {
            virtual bool update(time_point_t const &time) = 0;
        };

        explicit updatable_action(std::shared_ptr<impl> &&);

        bool update(time_point_t const &time);
    };

    action_transform_f const &ease_in_transformer();
    action_transform_f const &ease_out_transformer();
    action_transform_f const &ease_in_out_transformer();

    class action : public base {
        using super_class = base;

       public:
        action();
        action(std::nullptr_t);

        ui::node target() const;
        time_point_t const &start_time() const;
        double delay() const;
        action_update_f const &update_handler() const;
        action_completion_f const &completion_handler() const;

        void set_target(ui::node);
        void set_start_time(time_point_t);
        void set_delay(double const);
        void set_update_handler(action_update_f);
        void set_completion_handler(action_completion_f);

        updatable_action updatable();

       protected:
        class impl;

        action(std::shared_ptr<impl> &&);
    };

    class one_shot_action : public action {
        using super_class = action;

       public:
        one_shot_action(std::nullptr_t);

        double duration() const;
        action_transform_f const &value_transformer() const;

        void set_duration(double const &);
        void set_value_transformer(action_transform_f);

        class impl;

       protected:
        one_shot_action(std::shared_ptr<impl> &&);
    };

    class translate_action : public one_shot_action {
        using super_class = one_shot_action;

       public:
        translate_action();
        translate_action(std::nullptr_t);

        simd::float2 const &start_position() const;
        simd::float2 const &end_position() const;

        void set_start_position(simd::float2);
        void set_end_position(simd::float2);

        class impl;
    };

    class rotate_action : public one_shot_action {
        using super_class = one_shot_action;

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

    class scale_action : public one_shot_action {
        using super_class = one_shot_action;

       public:
        scale_action();
        scale_action(std::nullptr_t);

        simd::float2 const &start_scale() const;
        simd::float2 const &end_scale() const;

        void set_start_scale(simd::float2);
        void set_end_scale(simd::float2);

        class impl;
    };

    class color_action : public one_shot_action {
        using super_class = one_shot_action;

       public:
        color_action();
        color_action(std::nullptr_t);

        simd::float4 const &start_color() const;
        simd::float4 const &end_color() const;

        void set_start_color(simd::float4);
        void set_end_color(simd::float4);

        class impl;
    };

    class parallel_action : public action {
        using super_class = action;

       public:
        parallel_action();
        parallel_action(std::nullptr_t);

        std::vector<action> actions() const;

        void insert_action(action);
        void erase_action(action const &);

        class impl;
    };

    parallel_action make_action_sequence(std::vector<action> actions, time_point_t const &start_time);
}
}

template <>
struct std::hash<yas::ui::action> {
    std::size_t operator()(yas::ui::action const &key) const {
        return std::hash<uintptr_t>()(key.identifier());
    }
};
