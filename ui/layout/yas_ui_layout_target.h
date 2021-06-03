//
//  yas_ui_layout_target.h
//

#pragma once

#include <ui/yas_ui_types.h>

namespace yas::ui {
struct layout_value_target {
    virtual ~layout_value_target() = default;

    virtual void set_layout_value(float const) = 0;
};

struct layout_point_target {
    virtual ~layout_point_target() = default;

    virtual void set_layout_point(point const &) = 0;
};

struct layout_range_target {
    virtual ~layout_range_target() = default;

    virtual void set_layout_range(range const &) = 0;
};

struct layout_region_target {
    virtual ~layout_region_target() = default;

    virtual void set_layout_region(region const &) = 0;
};
}  // namespace yas::ui
