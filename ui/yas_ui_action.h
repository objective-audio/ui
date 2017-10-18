//
//  yas_ui_action.h
//

#pragma once

#include <chrono>
#include <unordered_set>
#include <vector>
#include "yas_base.h"
#include "yas_protocol.h"
#include "yas_ui_transformer.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    using time_point_t = std::chrono::time_point<std::chrono::system_clock>;
    using duration_t = std::chrono::duration<double>;

    struct updatable_action : protocol {
        struct impl : protocol::impl {
            virtual bool update(time_point_t const &time) = 0;
        };

        explicit updatable_action(std::shared_ptr<impl> &&);
        updatable_action(std::nullptr_t);

        bool update(time_point_t const &time);
    };

    class action : public base {
       public:
        class impl;

        struct args {
            time_point_t begin_time = std::chrono::system_clock::now();
            double delay = 0.0;
        };

        using time_update_f = std::function<bool(time_point_t const &)>;
        using value_update_f = std::function<void(double const)>;
        using completion_f = std::function<void(void)>;

        action();
        explicit action(args);
        action(std::nullptr_t);

        base target() const;
        time_point_t const &begin_time() const;
        double delay() const;
        time_update_f const &time_updater() const;
        completion_f const &completion_handler() const;

        void set_target(weak<base> const &);
        void set_time_updater(time_update_f);
        void set_completion_handler(completion_f);

        ui::updatable_action &updatable();

       protected:
        action(std::shared_ptr<impl> &&);

       private:
        ui::updatable_action _updatable = nullptr;
    };
}
}

template <>
struct std::hash<yas::ui::action> {
    std::size_t operator()(yas::ui::action const &key) const {
        return std::hash<uintptr_t>()(key.identifier());
    }
};

namespace yas {
namespace ui {
    class continuous_action : public action {
       public:
        class impl;

        struct args {
            double duration = 0.3;
            std::size_t loop_count = 1;

            action::args action;
        };

        continuous_action();
        continuous_action(continuous_action::args args);
        continuous_action(std::nullptr_t);

        virtual ~continuous_action() final;

        double duration() const;
        value_update_f const &value_updater() const;
        transform_f const &value_transformer() const;
        std::size_t loop_count() const;

        void set_value_updater(value_update_f);
        void set_value_transformer(transform_f);
    };

    class parallel_action : public action {
       public:
        class impl;

        struct args {
            weak<base> target;
            std::unordered_set<action> actions;

            action::args action;
        };

        parallel_action();
        parallel_action(args);
        parallel_action(std::nullptr_t);

        virtual ~parallel_action() final;

        std::vector<action> actions() const;

        void insert_action(action);
        void erase_action(action const &);
    };

    parallel_action make_action_sequence(std::vector<action> actions, time_point_t const &begin_time);
}
}
