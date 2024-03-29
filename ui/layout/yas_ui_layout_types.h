//
//  yas_ui_layout_types.h
//

#pragma once

#include <ostream>
#include <string>

namespace yas::ui {
enum class layout_direction {
    vertical,
    horizontal,
};

enum class layout_order {
    ascending,
    descending,
};

enum class layout_alignment {
    min,
    mid,
    max,
};

struct layout_borders final {
    float left = 0.0f;
    float right = 0.0f;
    float bottom = 0.0f;
    float top = 0.0f;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::layout_direction const &);
std::string to_string(ui::layout_order const &);
std::string to_string(ui::layout_alignment const &);
std::string to_string(ui::layout_borders const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &os, yas::ui::layout_direction const &);
std::ostream &operator<<(std::ostream &os, yas::ui::layout_order const &);
std::ostream &operator<<(std::ostream &os, yas::ui::layout_alignment const &);
std::ostream &operator<<(std::ostream &os, yas::ui::layout_borders const &);

bool operator==(yas::ui::layout_borders const &lhs, yas::ui::layout_borders const &rhs);
bool operator!=(yas::ui::layout_borders const &lhs, yas::ui::layout_borders const &rhs);
