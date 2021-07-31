//
//  yas_ui_action_group.h
//

#pragma once

#include <memory>

namespace yas::ui {
struct action_group final {
    [[nodiscard]] static std::shared_ptr<action_group> make_shared();

   private:
    action_group();
};
}  // namespace yas::ui
