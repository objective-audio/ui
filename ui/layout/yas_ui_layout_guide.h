//
//  yas_ui_layout_guide.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_action_dependency.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct layout_guide final : action_target {
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
};

struct layout_guide_point final {
    virtual ~layout_guide_point();

    [[nodiscard]] ui::layout_guide_ptr &x();
    [[nodiscard]] ui::layout_guide_ptr &y();
    [[nodiscard]] ui::layout_guide_ptr const &x() const;
    [[nodiscard]] ui::layout_guide_ptr const &y() const;

    void set_point(ui::point);
    [[nodiscard]] ui::point point() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::point>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_guide_point> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_point> make_shared(ui::point);

   private:
    layout_guide_ptr _x_guide;
    layout_guide_ptr _y_guide;

    explicit layout_guide_point(ui::point &&);

    layout_guide_point(layout_guide_point const &) = delete;
    layout_guide_point(layout_guide_point &&) = delete;
    layout_guide_point &operator=(layout_guide_point const &) = delete;
    layout_guide_point &operator=(layout_guide_point &&) = delete;
};

struct layout_guide_range {
    virtual ~layout_guide_range() final;

    [[nodiscard]] layout_guide_ptr &min();
    [[nodiscard]] layout_guide_ptr &max();
    [[nodiscard]] layout_guide_ptr const &min() const;
    [[nodiscard]] layout_guide_ptr const &max() const;
    [[nodiscard]] layout_guide_ptr const &length() const;

    void set_range(ui::range const &);
    [[nodiscard]] ui::range range() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::range>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_guide_range> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_range> make_shared(ui::range);

   private:
    layout_guide_ptr _min_guide;
    layout_guide_ptr _max_guide;
    layout_guide_ptr _length_guide;
    observing::cancellable_ptr _min_canceller;
    observing::cancellable_ptr _max_canceller;

    explicit layout_guide_range(ui::range &&);

    layout_guide_range(layout_guide_range const &) = delete;
    layout_guide_range(layout_guide_range &&) = delete;
    layout_guide_range &operator=(layout_guide_range const &) = delete;
    layout_guide_range &operator=(layout_guide_range &&) = delete;
};

struct layout_guide_rect final {
    struct ranges_args final {
        ui::range horizontal_range;
        ui::range vertical_range;
    };

    virtual ~layout_guide_rect();

    [[nodiscard]] layout_guide_range_ptr &horizontal_range();
    [[nodiscard]] layout_guide_range_ptr &vertical_range();
    [[nodiscard]] layout_guide_range_ptr const &horizontal_range() const;
    [[nodiscard]] layout_guide_range_ptr const &vertical_range() const;

    [[nodiscard]] layout_guide_ptr &left();
    [[nodiscard]] layout_guide_ptr &right();
    [[nodiscard]] layout_guide_ptr &bottom();
    [[nodiscard]] layout_guide_ptr &top();
    [[nodiscard]] layout_guide_ptr const &left() const;
    [[nodiscard]] layout_guide_ptr const &right() const;
    [[nodiscard]] layout_guide_ptr const &bottom() const;
    [[nodiscard]] layout_guide_ptr const &top() const;
    [[nodiscard]] layout_guide_ptr const &width() const;
    [[nodiscard]] layout_guide_ptr const &height() const;

    void set_horizontal_range(ui::range);
    void set_vertical_range(ui::range);
    void set_ranges(ranges_args);
    void set_region(ui::region const &);

    [[nodiscard]] ui::region region() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::region>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared(ranges_args);
    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared(ui::region);

   private:
    layout_guide_range_ptr _vertical_range;
    layout_guide_range_ptr _horizontal_range;

    explicit layout_guide_rect(ranges_args);
    explicit layout_guide_rect(ui::region);

    layout_guide_rect(layout_guide_rect const &) = delete;
    layout_guide_rect(layout_guide_rect &&) = delete;
    layout_guide_rect &operator=(layout_guide_rect const &) = delete;
    layout_guide_rect &operator=(layout_guide_rect &&) = delete;
};

struct layout_guide_pair {
    ui::layout_guide_ptr source;
    ui::layout_guide_ptr destination;
};

struct layout_guide_point_pair {
    ui::layout_guide_point_ptr source;
    ui::layout_guide_point_ptr destination;
};

struct layout_guide_range_pair {
    ui::layout_guide_range_ptr source;
    ui::layout_guide_range_ptr destination;
};

struct layout_guide_rect_pair {
    ui::layout_guide_rect_ptr source;
    ui::layout_guide_rect_ptr destination;
};

std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_point_pair);
std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_range_pair);
std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_rect_pair);
}  // namespace yas::ui
