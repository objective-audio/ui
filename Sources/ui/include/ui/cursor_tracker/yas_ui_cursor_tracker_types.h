#pragma once

#include <memory>
#include <ostream>
#include <string>

namespace yas::ui {
class event;
class cursor_event;
class collider;

enum class cursor_tracker_phase {
    entered,
    moved,
    leaved,
};

struct cursor_tracker_context final {
    cursor_tracker_phase phase;
    std::shared_ptr<ui::event> const &event;
    ui::cursor_event const &cursor_event;
    std::size_t collider_idx;
    std::shared_ptr<ui::collider> const &collider;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::cursor_tracker_phase const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::cursor_tracker_phase const &);
