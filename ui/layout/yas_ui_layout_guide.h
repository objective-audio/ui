//
//  yas_ui_layout_guide.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_action_dependency.h>
#include <ui/yas_ui_layout_dependency.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct layout_guide final : action_target, layout_value_target, layout_value_source {
    virtual ~layout_guide();

    void set_value(float const);
    float const &value() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<float>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_guide> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide> make_shared(float const);

   private:
    observing::value::holder_ptr<float> _value;
    observing::value::holder_ptr<int32_t> const _wait_count = observing::value::holder<int32_t>::make_shared(0);
    std::optional<float> _pushed_value;

    explicit layout_guide(float const);

    layout_guide(layout_guide const &) = delete;
    layout_guide(layout_guide &&) = delete;
    layout_guide &operator=(layout_guide const &) = delete;
    layout_guide &operator=(layout_guide &&) = delete;

    void set_layout_value(float const) override;
    observing::syncable observe_layout_value(std::function<void(float const &)> &&) override;
};

struct layout_guide_point final : layout_point_target, layout_point_source {
    virtual ~layout_guide_point();

    [[nodiscard]] std::shared_ptr<layout_guide> &x();
    [[nodiscard]] std::shared_ptr<layout_guide> &y();
    [[nodiscard]] std::shared_ptr<layout_guide> const &x() const;
    [[nodiscard]] std::shared_ptr<layout_guide> const &y() const;

    void set_point(ui::point);
    [[nodiscard]] ui::point point() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::point>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_guide_point> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_point> make_shared(ui::point);

   private:
    std::shared_ptr<layout_guide> _x_guide;
    std::shared_ptr<layout_guide> _y_guide;

    explicit layout_guide_point(ui::point &&);

    layout_guide_point(layout_guide_point const &) = delete;
    layout_guide_point(layout_guide_point &&) = delete;
    layout_guide_point &operator=(layout_guide_point const &) = delete;
    layout_guide_point &operator=(layout_guide_point &&) = delete;

    void set_layout_point(ui::point const &) override;
    observing::syncable observe_layout_point(std::function<void(ui::point const &)> &&) override;
};

struct layout_guide_range final : layout_range_target, layout_range_source {
    virtual ~layout_guide_range();

    [[nodiscard]] std::shared_ptr<layout_guide> &min();
    [[nodiscard]] std::shared_ptr<layout_guide> &max();
    [[nodiscard]] std::shared_ptr<layout_guide> const &min() const;
    [[nodiscard]] std::shared_ptr<layout_guide> const &max() const;
    [[nodiscard]] std::shared_ptr<layout_guide> const &length() const;

    void set_range(ui::range const &);
    [[nodiscard]] ui::range range() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::range>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_guide_range> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_range> make_shared(ui::range);

   private:
    std::shared_ptr<layout_guide> _min_guide;
    std::shared_ptr<layout_guide> _max_guide;
    std::shared_ptr<layout_guide> _length_guide;
    observing::cancellable_ptr _min_canceller;
    observing::cancellable_ptr _max_canceller;

    explicit layout_guide_range(ui::range &&);

    layout_guide_range(layout_guide_range const &) = delete;
    layout_guide_range(layout_guide_range &&) = delete;
    layout_guide_range &operator=(layout_guide_range const &) = delete;
    layout_guide_range &operator=(layout_guide_range &&) = delete;

    void set_layout_range(ui::range const &) override;
    observing::syncable observe_layout_range(std::function<void(ui::range const &)> &&) override;
};

struct layout_guide_rect final : layout_region_target, layout_region_source {
    virtual ~layout_guide_rect();

    [[nodiscard]] std::shared_ptr<layout_guide_range> &horizontal_range();
    [[nodiscard]] std::shared_ptr<layout_guide_range> &vertical_range();
    [[nodiscard]] std::shared_ptr<layout_guide_range> const &horizontal_range() const;
    [[nodiscard]] std::shared_ptr<layout_guide_range> const &vertical_range() const;

    [[nodiscard]] std::shared_ptr<layout_guide> &left();
    [[nodiscard]] std::shared_ptr<layout_guide> &right();
    [[nodiscard]] std::shared_ptr<layout_guide> &bottom();
    [[nodiscard]] std::shared_ptr<layout_guide> &top();
    [[nodiscard]] std::shared_ptr<layout_guide> const &left() const;
    [[nodiscard]] std::shared_ptr<layout_guide> const &right() const;
    [[nodiscard]] std::shared_ptr<layout_guide> const &bottom() const;
    [[nodiscard]] std::shared_ptr<layout_guide> const &top() const;
    [[nodiscard]] std::shared_ptr<layout_guide> const &width() const;
    [[nodiscard]] std::shared_ptr<layout_guide> const &height() const;

    void set_horizontal_range(ui::range &&);
    void set_vertical_range(ui::range &&);
    void set_ranges(region_ranges_args &&);
    void set_region(ui::region const &);

    [[nodiscard]] ui::region region() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::region>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared(region_ranges_args);
    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared(ui::region);

   private:
    std::shared_ptr<layout_guide_range> _vertical_range;
    std::shared_ptr<layout_guide_range> _horizontal_range;

    explicit layout_guide_rect(region_ranges_args);
    explicit layout_guide_rect(ui::region);

    layout_guide_rect(layout_guide_rect const &) = delete;
    layout_guide_rect(layout_guide_rect &&) = delete;
    layout_guide_rect &operator=(layout_guide_rect const &) = delete;
    layout_guide_rect &operator=(layout_guide_rect &&) = delete;

    void set_layout_region(ui::region const &) override;
    observing::syncable observe_layout_region(std::function<void(ui::region const &)> &&) override;
};

struct layout_guide_pair {
    std::shared_ptr<layout_guide> source;
    std::shared_ptr<layout_guide> destination;
};

struct layout_guide_point_pair {
    std::shared_ptr<layout_guide_point> source;
    std::shared_ptr<layout_guide_point> destination;
};

struct layout_guide_range_pair {
    std::shared_ptr<layout_guide_range> source;
    std::shared_ptr<layout_guide_range> destination;
};

struct layout_guide_rect_pair {
    std::shared_ptr<layout_guide_rect> source;
    std::shared_ptr<layout_guide_rect> destination;
};

std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_point_pair);
std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_range_pair);
std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_rect_pair);
}  // namespace yas::ui
