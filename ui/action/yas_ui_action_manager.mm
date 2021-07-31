//
//  yas_ui_action_manager.cpp
//

#include "yas_ui_action_manager.h"

using namespace yas;
using namespace yas::ui;

action_manager::action_manager() : _parallel_action(ui::parallel_action::make_shared({})) {
}

std::vector<std::shared_ptr<action>> action_manager::actions() const {
    return this->_parallel_action->actions();
}

void action_manager::insert_action(std::shared_ptr<action> const &action) {
    this->_parallel_action->insert_action(action);
}

void action_manager::erase_action(std::shared_ptr<action> const &action) {
    this->_parallel_action->erase_action(action);
}

void action_manager::erase_action(std::shared_ptr<action_target> const &target) {
    for (auto const &action : this->_parallel_action->actions()) {
        if (action->target() == target) {
            this->_parallel_action->erase_action(action);
        }
    }
}

void action_manager::erase_action(std::shared_ptr<ui::action_group> const &group) {
    if (group == nullptr) {
        return;
    }

    for (auto const &action : this->_parallel_action->actions()) {
        if (action->group() == group) {
            this->_parallel_action->erase_action(action);
        }
    }
}

void action_manager::update(time_point_t const &time) {
    this->_parallel_action->raw_action()->update(time);
}

std::shared_ptr<action_manager> action_manager::make_shared() {
    return std::shared_ptr<action_manager>(new action_manager{});
}
