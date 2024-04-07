//
//  yas_ui_action_group.cpp
//

#include "yas_ui_action_group.h"

using namespace yas;
using namespace yas::ui;

action_group::action_group() {
}

std::shared_ptr<action_group> action_group::make_shared() {
    return std::shared_ptr<action_group>(new action_group{});
}
