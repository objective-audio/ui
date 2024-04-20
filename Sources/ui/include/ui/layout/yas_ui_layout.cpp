//
//  yas_ui_layout.cpp
//

#include "yas_ui_layout.h"

#include "yas_ui_layout_dependency.h"
#include "yas_ui_layout_guide.h"

using namespace yas;
using namespace yas::ui;

#pragma mark - value source

observing::syncable ui::layout(std::shared_ptr<layout_value_source> const &src_guide,
                               std::shared_ptr<layout_value_target> const &dst_target,
                               std::function<float(float const &)> &&convert) {
    return src_guide->observe_layout_value(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](float const &value) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_value(convert(value));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_value_source> const &src_guide,
                               std::shared_ptr<layout_point_target> const &dst_target,
                               std::function<ui::point(float const &)> &&convert) {
    return src_guide->observe_layout_value(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](float const &value) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_point(convert(value));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_value_source> const &src_guide,
                               std::shared_ptr<layout_range_target> const &dst_target,
                               std::function<ui::range(float const &)> &&convert) {
    return src_guide->observe_layout_value(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](float const &value) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_range(convert(value));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_value_source> const &src_guide,
                               std::shared_ptr<layout_region_target> const &dst_target,
                               std::function<ui::region(float const &)> &&convert) {
    return src_guide->observe_layout_value(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](float const &value) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_region(convert(value));
            }
        });
}

#pragma mark - point source

observing::syncable ui::layout(std::shared_ptr<layout_point_source> const &src_guide,
                               std::shared_ptr<layout_value_target> const &dst_target,
                               std::function<float(ui::point const &)> &&convert) {
    return src_guide->observe_layout_point(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::point const &point) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_value(convert(point));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_point_source> const &src_guide,
                               std::shared_ptr<layout_point_target> const &dst_target,
                               std::function<ui::point(ui::point const &)> &&convert) {
    return src_guide->observe_layout_point(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::point const &point) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_point(convert(point));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_point_source> const &src_guide,
                               std::shared_ptr<layout_range_target> const &dst_target,
                               std::function<ui::range(ui::point const &)> &&convert) {
    return src_guide->observe_layout_point(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::point const &point) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_range(convert(point));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_point_source> const &src_guide,
                               std::shared_ptr<layout_region_target> const &dst_target,
                               std::function<ui::region(ui::point const &)> &&convert) {
    return src_guide->observe_layout_point(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::point const &point) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_region(convert(point));
            }
        });
}

#pragma mark - range source

observing::syncable ui::layout(std::shared_ptr<layout_range_source> const &src_guide,
                               std::shared_ptr<layout_value_target> const &dst_target,
                               std::function<float(ui::range const &)> &&convert) {
    return src_guide->observe_layout_range(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::range const &range) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_value(convert(range));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_range_source> const &src_guide,
                               std::shared_ptr<layout_point_target> const &dst_target,
                               std::function<ui::point(ui::range const &)> &&convert) {
    return src_guide->observe_layout_range(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::range const &range) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_point(convert(range));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_range_source> const &src_guide,
                               std::shared_ptr<layout_range_target> const &dst_target,
                               std::function<ui::range(ui::range const &)> &&convert) {
    return src_guide->observe_layout_range(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::range const &range) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_range(convert(range));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_range_source> const &src_guide,
                               std::shared_ptr<layout_region_target> const &dst_target,
                               std::function<ui::region(ui::range const &)> &&convert) {
    return src_guide->observe_layout_range(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::range const &range) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_region(convert(range));
            }
        });
}

#pragma mark - region source

observing::syncable ui::layout(std::shared_ptr<layout_region_source> const &src_guide,
                               std::shared_ptr<layout_value_target> const &dst_target,
                               std::function<float(ui::region const &)> &&convert) {
    return src_guide->observe_layout_region(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::region const &region) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_value(convert(region));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_region_source> const &src_guide,
                               std::shared_ptr<layout_point_target> const &dst_target,
                               std::function<ui::point(ui::region const &)> &&convert) {
    return src_guide->observe_layout_region(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::region const &region) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_point(convert(region));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_region_source> const &src_guide,
                               std::shared_ptr<layout_range_target> const &dst_target,
                               std::function<ui::range(ui::region const &)> &&convert) {
    return src_guide->observe_layout_region(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::region const &region) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_range(convert(region));
            }
        });
}

observing::syncable ui::layout(std::shared_ptr<layout_region_source> const &src_guide,
                               std::shared_ptr<layout_region_target> const &dst_target,
                               std::function<ui::region(ui::region const &)> &&convert) {
    return src_guide->observe_layout_region(
        [weak_target = to_weak(dst_target), convert = std::move(convert)](ui::region const &region) {
            if (auto const target = weak_target.lock()) {
                target->set_layout_region(convert(region));
            }
        });
}
