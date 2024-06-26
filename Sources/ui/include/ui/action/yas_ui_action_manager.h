//
//  yas_ui_action_manager.h
//

#pragma once

#include <ui/renderer/yas_ui_renderer_dependency.h>

#include <memory>

#include "yas_ui_action.h"

namespace yas::ui {
struct action_manager final : action_manager_for_renderer {
    [[nodiscard]] std::vector<std::shared_ptr<ui::action>> actions() const;
    void insert_action(std::shared_ptr<ui::action> const &);
    void erase_action(std::shared_ptr<ui::action> const &);
    void erase_action(std::shared_ptr<ui::action_group> const &);

    static std::shared_ptr<action_manager> make_shared();

   private:
    std::shared_ptr<ui::parallel_action> const _parallel_action;

    action_manager();

    void update(time_point_t const &) override;
};
}  // namespace yas::ui
