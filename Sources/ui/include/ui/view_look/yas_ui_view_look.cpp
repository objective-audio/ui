//
//  yas_ui_view_look.cpp
//

#include "yas_ui_view_look.h"

#include <cpp-utils/yas_to_bool.h>
#include <ui/background/yas_ui_background.h>
#include <ui/common/yas_ui_matrix.h>
#include <ui/layout/yas_ui_layout_guide.h>

using namespace yas;
using namespace yas::ui;

view_look::view_look()
    : _view_size({.width = 0, .height = 0}),
      _drawable_size({.width = 0, .height = 0}),
      _scale_factor_notify(observing::value::holder<double>::make_shared(0.0f)),
      _safe_area_insets(region_insets::zero()),
      _appearance(observing::value::holder<ui::appearance>::make_shared(appearance::normal)),
      _background(ui::background::make_shared()),
      _projection_matrix(matrix_identity_float4x4),
      _view_layout_guide(layout_region_guide::make_shared()),
      _safe_area_layout_guide(layout_region_guide::make_shared()) {
}

void view_look::set_view_sizes(ui::uint_size const view_size, ui::uint_size const drawable_size,
                               region_insets const safe_area_insets) {
    auto const update_view_size_result = this->_update_view_size(view_size, drawable_size);
    auto const update_scale_result = this->_update_scale_factor();
    auto const update_safe_area_result = this->_update_safe_area_insets(safe_area_insets);

    if (to_bool(update_view_size_result) || to_bool(update_safe_area_result)) {
        this->_update_view_layout_guide();
        this->_update_safe_area_layout_guide();

        if (to_bool(update_scale_result)) {
            this->_scale_factor_notify->set_value(this->_scale_factor);
        }
    }
}

void view_look::set_safe_area_insets(region_insets const insets) {
    auto const update_result = this->_update_safe_area_insets(insets);

    if (to_bool(update_result)) {
        this->_update_safe_area_layout_guide();
    }
}

void view_look::set_appearance(ui::appearance const appearance) {
    this->_appearance->set_value(appearance);
}

uint_size const &view_look::view_size() const {
    return this->_view_size;
}

uint_size const &view_look::drawable_size() const {
    return this->_drawable_size;
}

double view_look::scale_factor() const {
    return this->_scale_factor;
}

simd::float4x4 const &view_look::projection_matrix() const {
    return this->_projection_matrix;
}

std::shared_ptr<layout_region_guide> const &view_look::view_layout_guide() const {
    return this->_view_layout_guide;
}

std::shared_ptr<layout_region_guide> const &view_look::safe_area_layout_guide() const {
    return this->_safe_area_layout_guide;
}

appearance view_look::appearance() const {
    return this->_appearance->value();
}

std::shared_ptr<ui::background> view_look::background() const {
    return this->_background;
}

observing::syncable view_look::observe_scale_factor(std::function<void(double const &)> &&handler) {
    return this->_scale_factor_notify->observe(std::move(handler));
}

observing::syncable view_look::observe_appearance(std::function<void(ui::appearance const &)> &&handler) {
    return this->_appearance->observe(std::move(handler));
}

simd::float4x4 const &view_look::matrix_as_parent() const {
    return this->projection_matrix();
}

std::shared_ptr<view_look> view_look::make_shared() {
    return std::shared_ptr<view_look>(new view_look{});
}

view_look::update_result view_look::_update_view_size(ui::uint_size const v_size, ui::uint_size const d_size) {
    auto const prev_view_size = this->_view_size;
    auto const prev_drawable_size = this->_drawable_size;

    float const half_width = v_size.width * 0.5f;
    float const half_height = v_size.height * 0.5f;

    this->_view_size = {static_cast<uint32_t>(v_size.width), static_cast<uint32_t>(v_size.height)};
    this->_drawable_size = {static_cast<uint32_t>(d_size.width), static_cast<uint32_t>(d_size.height)};

    if (this->_view_size == prev_view_size && this->_drawable_size == prev_drawable_size) {
        return update_result::no_change;
    } else {
        this->_projection_matrix = matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
        return update_result::changed;
    }
}

view_look::update_result view_look::_update_scale_factor() {
    auto const prev_scale_factor = this->_scale_factor;

    if (this->_view_size.width > 0 && this->_drawable_size.width > 0) {
        this->_scale_factor =
            static_cast<double>(this->_drawable_size.width) / static_cast<double>(this->_view_size.width);
    } else if (this->_view_size.height > 0 && this->_drawable_size.height > 0) {
        this->_scale_factor =
            static_cast<double>(this->_drawable_size.height) / static_cast<double>(this->_view_size.height);
    } else {
        this->_scale_factor = 0.0;
    }

    if (std::abs(this->_scale_factor - prev_scale_factor) < std::numeric_limits<double>::epsilon()) {
        return update_result::no_change;
    } else {
        return update_result::changed;
    }
}

view_look::update_result view_look::_update_safe_area_insets(ui::region_insets const insets) {
    auto const prev_insets = this->_safe_area_insets;

    this->_safe_area_insets = insets;

    if (this->_safe_area_insets == prev_insets) {
        return update_result::no_change;
    } else {
        return update_result::changed;
    }
}

void view_look::_update_view_layout_guide() {
    float const view_width = this->_view_size.width;
    float const view_height = this->_view_size.height;

    this->_view_layout_guide->set_region(
        {.origin = {-view_width * 0.5f, -view_height * 0.5f}, .size = {view_width, view_height}});
}

void view_look::_update_safe_area_layout_guide() {
    float const view_width = this->_view_size.width;
    float const view_height = this->_view_size.height;
    float const origin_x = -view_width * 0.5f + this->_safe_area_insets.left;
    float const origin_y = -view_height * 0.5f + this->_safe_area_insets.bottom;
    float const width = view_width - this->_safe_area_insets.left - this->_safe_area_insets.right;
    float const height = view_height - this->_safe_area_insets.bottom - this->_safe_area_insets.top;

    this->_safe_area_layout_guide->set_region({.origin = {origin_x, origin_y}, .size = {width, height}});
}
