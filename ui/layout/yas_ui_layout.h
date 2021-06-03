//
//  yas_ui_layout.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
observing::syncable layout(std::shared_ptr<layout_value_source> const &src_guide,
                           std::shared_ptr<layout_value_target> const &dst_target,
                           std::function<float(float const &)> &&);
observing::syncable layout(std::shared_ptr<layout_point_source> const &src_guide,
                           std::shared_ptr<layout_point_target> const &dst_target,
                           std::function<ui::point(ui::point const &)> &&);
observing::syncable layout(std::shared_ptr<layout_region_source> const &src_guide,
                           std::shared_ptr<layout_region_target> const &dst_target,
                           std::function<ui::region(ui::region const &)> &&);
}  // namespace yas::ui
