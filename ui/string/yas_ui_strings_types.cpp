//
//  yas_ui_strings_types.cpp
//

#include "yas_ui_strings_types.h"

using namespace yas;
using namespace yas::ui;

bool strings_attribute::operator==(strings_attribute const &rhs) const {
    return this->range == rhs.range && this->color == rhs.color;
}

bool strings_attribute::operator!=(strings_attribute const &rhs) const {
    return !(*this == rhs);
}
