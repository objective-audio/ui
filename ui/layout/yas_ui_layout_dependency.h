//
//  yas_ui_layout_dependency.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct layout_value_source {
    virtual ~layout_value_source() = default;

    [[nodiscard]] virtual observing::syncable observe_layout_value(std::function<void(float const &)> &&) = 0;
};

struct layout_point_source {
    virtual ~layout_point_source() = default;

    [[nodiscard]] virtual observing::syncable observe_layout_point(std::function<void(ui::point const &)> &&) = 0;
    [[nodiscard]] virtual std::shared_ptr<layout_value_source> layout_x_value_source() = 0;
    [[nodiscard]] virtual std::shared_ptr<layout_value_source> layout_y_value_source() = 0;
};

struct layout_range_source {
    virtual ~layout_range_source() = default;

    [[nodiscard]] virtual observing::syncable observe_layout_range(std::function<void(ui::range const &)> &&) = 0;
    [[nodiscard]] virtual std::shared_ptr<layout_value_source> layout_min_value_source() = 0;
    [[nodiscard]] virtual std::shared_ptr<layout_value_source> layout_max_value_source() = 0;
    [[nodiscard]] virtual std::shared_ptr<layout_value_source> layout_length_value_source() = 0;
};

struct layout_region_source {
    virtual ~layout_region_source() = default;

    [[nodiscard]] virtual observing::syncable observe_layout_region(std::function<void(ui::region const &)> &&) = 0;
    [[nodiscard]] virtual std::shared_ptr<layout_range_source> layout_horizontal_range_source() = 0;
    [[nodiscard]] virtual std::shared_ptr<layout_range_source> layout_vertical_range_source() = 0;
};

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
