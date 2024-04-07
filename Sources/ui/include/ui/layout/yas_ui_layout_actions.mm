//
//  yas_ui_layout_actions.cpp
//

#include "yas_ui_layout_actions.h"

#include <cpp-utils/yas_each_index.h>
#include <ui/action/yas_ui_action_manager.h>

using namespace yas;
using namespace yas::ui;

std::shared_ptr<action> ui::make_action(layout_action_args &&args) {
    auto continuous_args = continuous_action_args{.duration = std::move(args.duration),
                                                  .loop_count = std::move(args.loop_count),
                                                  .value_transformer = std::move(args.value_transformer),
                                                  .group = args.group,
                                                  .begin_time = std::move(args.begin_time),
                                                  .delay = std::move(args.delay),
                                                  .completion = std::move(args.completion)};

    continuous_args.value_updater = [args = std::move(args)](double const value) {
        if (auto target = args.target.lock()) {
            target->set_layout_value((args.end_value - args.begin_value) * (float)value + args.begin_value);
        }
    };

    return action::make_continuous(std::move(continuous_args));
}

layout_animator::layout_animator(layout_animator_args &&args) : _args(std::move(args)) {
    for (auto const &guide_pair : this->_args.layout_guide_pairs) {
        auto const group = action_group::make_shared();
        this->_groups.push_back(group);

        auto const &src_guide = guide_pair.source;
        auto const &dst_guide = guide_pair.destination;

        dst_guide->set_value(src_guide->value());

        auto weak_dst_guide = to_weak(dst_guide);

        src_guide
            ->observe([this, weak_dst_guide, group](float const &value) {
                auto const &args = this->_args;
                std::shared_ptr<ui::action_manager> const action_manager = args.action_manager.lock();
                std::shared_ptr<ui::layout_value_guide> const dst_guide = weak_dst_guide.lock();

                if (action_manager && dst_guide) {
                    action_manager->erase_action(group);

                    auto action = make_action({.target = dst_guide,
                                               .group = group,
                                               .begin_value = dst_guide->value(),
                                               .end_value = value,
                                               .duration = args.duration,
                                               .value_transformer = this->value_transformer()});
                    action_manager->insert_action(action);
                }
            })
            .end()
            ->add_to(this->_pool);
    }
}

layout_animator::~layout_animator() {
    if (auto const action_manager = this->_args.action_manager.lock()) {
        for (auto const &group : this->_groups) {
            action_manager->erase_action(group);
        }
    }
}

void layout_animator::set_value_transformer(transform_f transform) {
    this->_value_transformer = transform;
}

transform_f const &layout_animator::value_transformer() const {
    return this->_value_transformer;
}

std::shared_ptr<layout_animator> layout_animator::make_shared(layout_animator_args &&args) {
    return std::shared_ptr<layout_animator>(new layout_animator{std::move(args)});
}
