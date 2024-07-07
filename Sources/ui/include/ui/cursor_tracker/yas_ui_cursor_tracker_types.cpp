#include "yas_ui_cursor_tracker_types.h"

using namespace yas;
using namespace yas::ui;

std::string yas::to_string(cursor_tracker_phase const &phase) {
    switch (phase) {
        case cursor_tracker_phase::entered:
            return "entered";
        case cursor_tracker_phase::moved:
            return "moved";
        case cursor_tracker_phase::leaved:
            return "leaved";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::cursor_tracker_phase const &phase) {
    os << to_string(phase);
    return os;
}
