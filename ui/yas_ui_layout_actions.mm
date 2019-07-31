//
//  yas_ui_layout_actions.cpp
//

#include "yas_ui_layout_actions.h"
#include <cpp_utils/yas_each_index.h>
#include "yas_ui_renderer.h"

using namespace yas;

ui::continuous_action ui::make_action(layout_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_value((args.end_value - args.begin_value) * (float)value + args.begin_value);
            }
        }
    });

    return action;
}

struct ui::layout_animator::impl : base::impl {
    args _args;
    ui::transform_f _value_transformer;

    impl(args &&args) : _args(std::move(args)) {
    }

    ~impl() {
        if (auto renderer = this->_args.renderer.lock()) {
            for (auto const &guide_pair : this->_args.layout_guide_pairs) {
                renderer.erase_action(guide_pair.destination);
            }
        }
    }

    void prepare(ui::layout_animator &interporator) {
        this->_observers.reserve(this->_args.layout_guide_pairs.size());

        for (auto &guide_pair : this->_args.layout_guide_pairs) {
            auto &src_guide = guide_pair.source;
            auto &dst_guide = guide_pair.destination;

            dst_guide.set_value(src_guide.value());

            auto weak_interporator = to_weak(interporator);
            auto weak_dst_guide = to_weak(dst_guide);

            auto observer = src_guide.chain()
                                .guard([weak_interporator, weak_dst_guide](float const &) {
                                    return weak_interporator && weak_dst_guide;
                                })
                                .perform([weak_interporator, weak_dst_guide](float const &value) {
                                    auto interporator = weak_interporator.lock();
                                    auto const &args = interporator.impl_ptr<impl>()->_args;
                                    if (auto renderer = args.renderer.lock()) {
                                        auto dst_guide = weak_dst_guide.lock();

                                        renderer.erase_action(dst_guide);

                                        auto action =
                                            ui::make_action({.target = dst_guide,
                                                             .begin_value = dst_guide.value(),
                                                             .end_value = value,
                                                             .continuous_action = {.duration = args.duration}});
                                        action.set_value_transformer(interporator.value_transformer());
                                        renderer.insert_action(std::move(action));
                                    }
                                })
                                .end();

            this->_observers.emplace_back(std::move(observer));
        }
    }

   private:
    std::vector<chaining::any_observer_ptr> _observers;
};

ui::layout_animator::layout_animator(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout_animator::layout_animator(std::nullptr_t) : base(nullptr) {
}

void ui::layout_animator::set_value_transformer(ui::transform_f transform) {
    impl_ptr<impl>()->_value_transformer = transform;
}

ui::transform_f const &ui::layout_animator::value_transformer() const {
    return impl_ptr<impl>()->_value_transformer;
}
