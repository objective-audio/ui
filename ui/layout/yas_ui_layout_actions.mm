//
//  yas_ui_layout_actions.cpp
//

#include "yas_ui_layout_actions.h"
#include <cpp_utils/yas_each_index.h>
#include "yas_ui_renderer.h"

using namespace yas;
using namespace yas::ui;

std::shared_ptr<action> ui::make_action(layout_action::args args) {
    args.action.target = args.target;
    args.continuous_action.action = std::move(args.action);

    args.continuous_action.value_updater = [args = std::move(args)](double const value) {
        if (auto target = args.target.lock()) {
            target->set_value((args.end_value - args.begin_value) * (float)value + args.begin_value);
        }
    };

    return action::make_continuous(std::move(args.continuous_action));
}

layout_animator::layout_animator(args args) : _args(std::move(args)) {
    for (auto &guide_pair : this->_args.layout_guide_pairs) {
        auto &src_guide = guide_pair.source;
        auto &dst_guide = guide_pair.destination;

        dst_guide->set_value(src_guide->value());

        auto weak_dst_guide = to_weak(dst_guide);

        src_guide
            ->observe([this, weak_dst_guide](float const &value) {
                auto const &args = this->_args;
                auto renderer = args.renderer.lock();
                auto dst_guide = weak_dst_guide.lock();

                if (renderer && dst_guide) {
                    renderer->erase_action(dst_guide);

                    auto action = make_action({.target = dst_guide,
                                               .begin_value = dst_guide->value(),
                                               .end_value = value,
                                               .continuous_action = {.duration = args.duration,
                                                                     .value_transformer = this->value_transformer()}});
                    renderer->insert_action(action);
                }
            })
            .end()
            ->add_to(this->_pool);
    }
}

layout_animator::~layout_animator() {
    if (auto renderer = this->_args.renderer.lock()) {
        for (auto const &guide_pair : this->_args.layout_guide_pairs) {
            renderer->erase_action(guide_pair.destination);
        }
    }
}

void layout_animator::set_value_transformer(transform_f transform) {
    this->_value_transformer = transform;
}

transform_f const &layout_animator::value_transformer() const {
    return this->_value_transformer;
}

layout_animator_ptr layout_animator::make_shared(args args) {
    return std::shared_ptr<layout_animator>(new layout_animator{std::move(args)});
}
