//
//  yas_ui_standard.h
//

#pragma once

#include <ui/common/yas_ui_types.h>

namespace yas::ui {
struct standard final {
    std::shared_ptr<ui::view_look> const &view_look() const;
    std::shared_ptr<ui::metal_system> const &metal_system() const;
    std::shared_ptr<ui::node> const &root_node() const;
    std::shared_ptr<ui::detector> const &detector() const;
    std::shared_ptr<ui::event_manager> const &event_manager() const;
    std::shared_ptr<ui::action_manager> const &action_manager() const;
    std::shared_ptr<ui::renderer> const &renderer() const;

    static std::shared_ptr<standard> make_shared(std::shared_ptr<ui::view_look> const &,
                                                 std::shared_ptr<ui::metal_system> const &);

   private:
    std::shared_ptr<ui::view_look> const _view_look;
    std::shared_ptr<ui::metal_system> const _metal_system;
    std::shared_ptr<ui::node> const _root_node;
    std::shared_ptr<ui::detector> const _detector;
    std::shared_ptr<ui::event_manager> const _event_manager;
    std::shared_ptr<ui::action_manager> const _action_manager;
    std::shared_ptr<ui::renderer> const _renderer;

    standard(std::shared_ptr<ui::view_look> const &, std::shared_ptr<ui::metal_system> const &);
};
}  // namespace yas::ui
