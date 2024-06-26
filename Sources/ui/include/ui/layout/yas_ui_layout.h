//
//  yas_ui_layout.h
//

#pragma once

#include <ui/common/yas_ui_types.h>

#include <observing/umbrella.hpp>

namespace yas::ui {
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_value_source> const &src_guide,
                                         std::shared_ptr<layout_value_target> const &dst_target,
                                         std::function<float(float const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_value_source> const &src_guide,
                                         std::shared_ptr<layout_point_target> const &dst_target,
                                         std::function<ui::point(float const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_value_source> const &src_guide,
                                         std::shared_ptr<layout_range_target> const &dst_target,
                                         std::function<ui::range(float const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_value_source> const &src_guide,
                                         std::shared_ptr<layout_region_target> const &dst_target,
                                         std::function<ui::region(float const &)> &&);

[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_point_source> const &src_guide,
                                         std::shared_ptr<layout_value_target> const &dst_target,
                                         std::function<float(ui::point const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_point_source> const &src_guide,
                                         std::shared_ptr<layout_point_target> const &dst_target,
                                         std::function<ui::point(ui::point const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_point_source> const &src_guide,
                                         std::shared_ptr<layout_range_target> const &dst_target,
                                         std::function<ui::range(ui::point const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_point_source> const &src_guide,
                                         std::shared_ptr<layout_region_target> const &dst_target,
                                         std::function<ui::region(ui::point const &)> &&);

[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_range_source> const &src_guide,
                                         std::shared_ptr<layout_value_target> const &dst_target,
                                         std::function<float(ui::range const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_range_source> const &src_guide,
                                         std::shared_ptr<layout_point_target> const &dst_target,
                                         std::function<ui::point(ui::range const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_range_source> const &src_guide,
                                         std::shared_ptr<layout_range_target> const &dst_target,
                                         std::function<ui::range(ui::range const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_range_source> const &src_guide,
                                         std::shared_ptr<layout_region_target> const &dst_target,
                                         std::function<ui::region(ui::range const &)> &&);

[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_region_source> const &src_guide,
                                         std::shared_ptr<layout_value_target> const &dst_target,
                                         std::function<float(ui::region const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_region_source> const &src_guide,
                                         std::shared_ptr<layout_point_target> const &dst_target,
                                         std::function<ui::point(ui::region const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_region_source> const &src_guide,
                                         std::shared_ptr<layout_range_target> const &dst_target,
                                         std::function<ui::range(ui::region const &)> &&);
[[nodiscard]] observing::syncable layout(std::shared_ptr<layout_region_source> const &src_guide,
                                         std::shared_ptr<layout_region_target> const &dst_target,
                                         std::function<ui::region(ui::region const &)> &&);
}  // namespace yas::ui
