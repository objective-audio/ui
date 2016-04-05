//
//  yas_ui_action.h
//

#pragma once

#include <simd/simd.h>
#include <chrono>
#include <vector>
#include "yas_base.h"
#include "yas_protocol.h"
#include "yas_ui_transformer.h"

namespace yas {
namespace ui {
    class node;

    using time_point_t = std::chrono::time_point<std::chrono::system_clock>;
    using duration_t = std::chrono::duration<double>;
    using action_time_update_f = std::function<bool(time_point_t const &)>;
    using action_value_update_f = std::function<void(double const)>;
    using action_completion_f = std::function<void(void)>;

    struct updatable_action : public protocol {
        struct impl : protocol::impl {
            virtual bool update(time_point_t const &time) = 0;
        };

        explicit updatable_action(std::shared_ptr<impl> &&);

        bool update(time_point_t const &time);
    };

    struct action_args {
        time_point_t start_time = std::chrono::system_clock::now();
        double delay = 0.0;
    };

    class action : public base {
        using super_class = base;

       public:
        action();
        action(action_args);
        action(std::nullptr_t);

        ui::node target() const;
        time_point_t const &start_time() const;
        double delay() const;
        action_time_update_f const &time_updater() const;
        action_completion_f const &completion_handler() const;

        void set_target(ui::node const &);
        void set_time_updater(action_time_update_f);
        void set_completion_handler(action_completion_f);

        updatable_action updatable();

        class impl;

       protected:
        action(std::shared_ptr<impl> &&);
    };

    struct continuous_action_args {
        double duration = 0.3;
        std::size_t loop_count = 1;

        action_args action;
    };

    class continuous_action : public action {
        using super_class = action;

       public:
        continuous_action();
        continuous_action(continuous_action_args args);
        continuous_action(std::nullptr_t);

        double duration() const;
        action_value_update_f const &value_updater() const;
        action_transform_f const &value_transformer() const;
        std::size_t loop_count() const;

        void set_value_updater(action_value_update_f);
        void set_value_transformer(action_transform_f);

        class impl;
    };

    struct translate_action_args {
        simd::float2 start_position = 0.0f;
        simd::float2 end_position = 0.0f;

        continuous_action_args continuous_action;
    };

    struct rotate_action_args {
        float start_angle = 0.0f;
        float end_angle = 0.0f;
        bool is_shortest = false;

        continuous_action_args continuous_action;
    };

    struct scale_action_args {
        simd::float2 start_scale = 1.0f;
        simd::float2 end_scale = 1.0f;

        continuous_action_args continuous_action;
    };

    struct color_action_args {
        simd::float4 start_color = 1.0f;
        simd::float4 end_color = 1.0f;

        continuous_action_args continuous_action;
    };

    continuous_action make_action(translate_action_args);
    continuous_action make_action(rotate_action_args);
    continuous_action make_action(scale_action_args);
    continuous_action make_action(color_action_args);

    class parallel_action : public action {
        using super_class = action;

       public:
        parallel_action();
        parallel_action(action_args);
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
