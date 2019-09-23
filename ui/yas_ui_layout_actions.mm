//
//  yas_ui_layout_actions.cpp
//

#include "yas_ui_layout_actions.h"
#include <cpp_utils/yas_each_index.h>
#include "yas_ui_renderer.h"

using namespace yas;

std::shared_ptr<ui::continuous_action> ui::make_action(layout_action::args args) {
    auto target = args.target;
    auto action = ui::continuous_action::make_shared(std::move(args.continuous_action));
    action->set_target(target);

    action->set_value_updater([args = std::move(args), weak_action = to_weak(action)](double const value) {
        if (auto action = weak_action.lock()) {
            if (auto target = args.target.lock()) {
                target->set_value((args.end_value - args.begin_value) * (float)value + args.begin_value);
            }
        }
    });

    return action;
}

ui::layout_animator::layout_animator(args args) : _args(std::move(args)) {
}

ui::layout_animator::~layout_animator() {
    if (auto renderer = this->_args.renderer.lock()) {
        for (auto const &guide_pair : this->_args.layout_guide_pairs) {
            renderer->erase_action(guide_pair.destination);
        }
    }
}

void ui::layout_animator::set_value_transformer(ui::transform_f transform) {
    this->_value_transformer = transform;
}

ui::transform_f const &ui::layout_animator::value_transformer() const {
    return this->_value_transformer;
}

void ui::layout_animator::_prepare(ui::layout_animator_ptr const &animator) {
    this->_observers.reserve(this->_args.layout_guide_pairs.size());

    for (auto &guide_pair : this->_args.layout_guide_pairs) {
        auto &src_guide = guide_pair.source;
        auto &dst_guide = guide_pair.destination;

        dst_guide->set_value(src_guide->value());

        auto weak_animator = to_weak(animator);
        auto weak_dst_guide = to_weak(dst_guide);

        auto observer = src_guide->chain()
                            .guard([weak_animator, weak_dst_guide](float const &) {
                                return !weak_animator.expired() && !weak_dst_guide.expired();
                            })
                            .perform([weak_animator, weak_dst_guide](float const &value) {
                                auto animator = weak_animator.lock();
                                auto const &args = animator->_args;
                                if (auto renderer = args.renderer.lock()) {
                                    auto dst_guide = weak_dst_guide.lock();

                                    renderer->erase_action(dst_guide);

                                    auto action = ui::make_action({.target = dst_guide,
                                                                   .begin_value = dst_guide->value(),
                                                                   .end_value = value,
                                                                   .continuous_action = {.duration = args.duration}});
                                    action->set_value_transformer(animator->value_transformer());
                                    renderer->insert_action(std::move(action));
                                }
                            })
                            .end();

        this->_observers.emplace_back(std::move(observer));
    }
}

ui::layout_animator_ptr ui::layout_animator::make_shared(args args) {
    auto shared = std::shared_ptr<layout_animator>(new layout_animator{std::move(args)});
    shared->_prepare(shared);
    return shared;
}
