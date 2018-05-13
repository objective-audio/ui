//
//  yas_ui_layout_types.cpp
//

#include "yas_ui_layout_types.h"

using namespace yas;

#pragma mark - to_string

std::string yas::to_string(ui::layout_direction const &dir) {
    switch (dir) {
        case ui::layout_direction::horizontal:
            return "horizontal";
        case ui::layout_direction::vertical:
            return "vertical";
    }
}

std::string yas::to_string(ui::layout_order const &order) {
    switch (order) {
        case ui::layout_order::ascending:
            return "ascending";
        case ui::layout_order::descending:
            return "descending";
    }
}

std::string yas::to_string(ui::layout_alignment const &align) {
    switch (align) {
        case ui::layout_alignment::min:
            return "min";
        case ui::layout_alignment::mid:
            return "mid";
        case ui::layout_alignment::max:
            return "max";
    }
}

std::string yas::to_string(ui::layout_borders const &borders) {
    return "{left=" + std::to_string(borders.left) + ", right=" + std::to_string(borders.right) +
           ", bottom=" + std::to_string(borders.bottom) + ", top=" + std::to_string(borders.top) + "}";
}

#pragma mark - ostream

std::ostream &operator<<(std::ostream &os, yas::ui::layout_direction const &dir) {
    os << to_string(dir);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::layout_order const &order) {
    os << to_string(order);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::layout_alignment const &align) {
    os << to_string(align);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::layout_borders const &borders) {
    os << to_string(borders);
    return os;
}

#pragma mark - equation

bool operator==(yas::ui::layout_borders const &lhs, yas::ui::layout_borders const &rhs) {
    return lhs.left == rhs.left && lhs.right == rhs.right && lhs.bottom == rhs.bottom && lhs.top == rhs.top;
}

bool operator!=(yas::ui::layout_borders const &lhs, yas::ui::layout_borders const &rhs) {
    return lhs.left != rhs.left || lhs.right != rhs.right || lhs.bottom != rhs.bottom || lhs.top != rhs.top;
}
