//
//  yas_ui_layout_actions.cpp
//

#include "yas_each_index.h"
#include "yas_ui_layout_actions.h"
#include "yas_ui_renderer.h"

using namespace yas;

ui::continuous_action ui::make_action(layout_action::args args) {
    auto target = args.target;
    ui::continuous_action action{std::move(args.continuous_action)};
    action.set_target(target);

    action.set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target.set_value((args.end_value - args.start_value) * (float)value + args.start_value);
            }
        }
    });

    return action;
}

struct ui::layout_interporator::impl : base::impl {
    args _args;
    ui::transform_f _value_transformer;

    impl(args &&args) : _args(std::move(args)) {
    }

    ~impl() {
        if (auto renderer = _args.renderer.lock()) {
            for (auto const &guide_pair : _args.layout_guide_pairs) {
                renderer.erase_action(guide_pair.destination);
            }
        }
    }

    void prepare(ui::layout_interporator &interporator) {
        _observers.reserve(_args.layout_guide_pairs.size());

        for (auto &guide_pair : _args.layout_guide_pairs) {
            auto &src_guide = guide_pair.source;
            auto &dst_guide = guide_pair.destination;

            dst_guide.set_value(src_guide.value());

            auto observer = src_guide.subject().make_observer(
                ui::layout_guide::method::value_changed,
                [weak_interporator = to_weak(interporator), weak_dst_guide = to_weak(dst_guide)](auto const &context) {
                    if (auto interporator = weak_interporator.lock()) {
                        auto const &args = interporator.impl_ptr<impl>()->_args;
                        if (auto renderer = args.renderer.lock()) {
                            if (auto dst_guide = weak_dst_guide.lock()) {
                                renderer.erase_action(dst_guide);

                                auto action = ui::make_action({.target = dst_guide,
                                                               .start_value = dst_guide.value(),
                                                               .end_value = context.value.new_value,
                                                               .continuous_action = {.duration = args.duration}});
                                action.set_value_transformer(interporator.value_transformer());
                                renderer.insert_action(std::move(action));
                            }
                        }
                    }
                });

            _observers.emplace_back(std::move(observer));
        }
    }

   private:
    std::vector<ui::layout_guide::observer_t> _observers;
};

ui::layout_interporator::layout_interporator(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout_interporator::layout_interporator(std::nullptr_t) : base(nullptr) {
}

void ui::layout_interporator::set_value_transformer(ui::transform_f transform) {
    impl_ptr<impl>()->_value_transformer = transform;
}

ui::transform_f const &ui::layout_interporator::value_transformer() const {
    return impl_ptr<impl>()->_value_transformer;
}