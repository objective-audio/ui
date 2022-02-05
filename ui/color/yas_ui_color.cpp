//
//  yas_ui_color.cpp
//

#include "yas_ui_color.h"

using namespace yas;
using namespace yas::ui;

bool color::operator==(color const &rhs) const {
    return this->rgb == rhs.rgb && this->alpha == rhs.alpha;
}

bool color::operator!=(color const &rhs) const {
    return this->rgb != rhs.rgb || this->alpha != rhs.alpha;
}

std::string yas::to_string(color const &color) {
    return "{" + to_string(color.rgb) + ", " + std::to_string(color.alpha) + "}";
}

std::ostream &operator<<(std::ostream &os, yas::ui::color const &color) {
    os << to_string(color);
    return os;
}
