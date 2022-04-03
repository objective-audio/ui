//
//  yas_ui_touch_tracker_types.cpp
//

#include "yas_ui_touch_tracker_types.h"

using namespace yas;
using namespace yas::ui;

std::string yas::to_string(touch_tracker_phase const &phase) {
    switch (phase) {
        case touch_tracker_phase::began:
            return "began";
        case touch_tracker_phase::entered:
            return "entered";
        case touch_tracker_phase::moved:
            return "moved";
        case touch_tracker_phase::leaved:
            return "leaved";
        case touch_tracker_phase::ended:
            return "ended";
        case touch_tracker_phase::canceled:
            return "canceled";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::touch_tracker_phase const &method) {
    os << to_string(method);
    return os;
}
