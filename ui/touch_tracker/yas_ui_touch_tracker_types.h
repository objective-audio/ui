//
//  yas_ui_touch_tracker_types.h
//

#pragma once

#include <memory>
#include <string>

namespace yas::ui {
class event;
class touch_event;
class collider;

enum class touch_tracker_phase {
    began,
    entered,
    moved,
    leaved,
    ended,
    canceled,
};

struct touch_tracker_context final {
    touch_tracker_phase phase;
    std::shared_ptr<ui::event> const &event;
    ui::touch_event const &touch_event;
    std::size_t collider_idx;
    std::shared_ptr<ui::collider> const &collider;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::touch_tracker_phase const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::touch_tracker_phase const &);
