//
//  yas_ui_layout_guide.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_action_dependency.h>
#include <ui/yas_ui_layout_dependency.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct layout_value_guide final : layout_value_target, layout_value_source {
    void set_value(float const);
    float const &value() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<float>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_value_guide> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_value_guide> make_shared(float const);

   private:
    observing::value::holder_ptr<float> _value;
    observing::value::holder_ptr<int32_t> const _wait_count = observing::value::holder<int32_t>::make_shared(0);
    std::optional<float> _pushed_value;

    explicit layout_value_guide(float const);

    layout_value_guide(layout_value_guide const &) = delete;
    layout_value_guide(layout_value_guide &&) = delete;
    layout_value_guide &operator=(layout_value_guide const &) = delete;
    layout_value_guide &operator=(layout_value_guide &&) = delete;

    void set_layout_value(float const) override;
    observing::syncable observe_layout_value(std::function<void(float const &)> &&) override;
};

struct layout_point_guide final : layout_point_target, layout_point_source {
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &x() const;
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &y() const;

    void set_point(ui::point &&);
    void set_point(ui::point const &);
    [[nodiscard]] ui::point point() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::point>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_point_guide> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_point_guide> make_shared(ui::point);

   private:
    std::shared_ptr<layout_value_guide> _x_guide;
    std::shared_ptr<layout_value_guide> _y_guide;

    explicit layout_point_guide(ui::point &&);

    layout_point_guide(layout_point_guide const &) = delete;
    layout_point_guide(layout_point_guide &&) = delete;
    layout_point_guide &operator=(layout_point_guide const &) = delete;
    layout_point_guide &operator=(layout_point_guide &&) = delete;

    void set_layout_point(ui::point const &) override;
    observing::syncable observe_layout_point(std::function<void(ui::point const &)> &&) override;
    std::shared_ptr<layout_value_source> layout_x_value_source() override;
    std::shared_ptr<layout_value_source> layout_y_value_source() override;
};

struct layout_range_guide final : layout_range_target, layout_range_source {
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &min() const;
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &max() const;
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &length() const;

    void set_range(ui::range const &);
    [[nodiscard]] ui::range range() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::range>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_range_guide> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_range_guide> make_shared(ui::range);

   private:
    std::shared_ptr<layout_value_guide> _min_guide;
    std::shared_ptr<layout_value_guide> _max_guide;
    std::shared_ptr<layout_value_guide> _length_guide;
    observing::cancellable_ptr _min_canceller;
    observing::cancellable_ptr _max_canceller;

    explicit layout_range_guide(ui::range &&);

    layout_range_guide(layout_range_guide const &) = delete;
    layout_range_guide(layout_range_guide &&) = delete;
    layout_range_guide &operator=(layout_range_guide const &) = delete;
    layout_range_guide &operator=(layout_range_guide &&) = delete;

    void set_layout_range(ui::range const &) override;
    observing::syncable observe_layout_range(std::function<void(ui::range const &)> &&) override;
    std::shared_ptr<layout_value_source> layout_min_value_source() override;
    std::shared_ptr<layout_value_source> layout_max_value_source() override;
    std::shared_ptr<layout_value_source> layout_length_value_source() override;
};

struct layout_region_guide final : layout_region_target, layout_region_source {
    [[nodiscard]] std::shared_ptr<layout_range_guide> const &horizontal_range() const;
    [[nodiscard]] std::shared_ptr<layout_range_guide> const &vertical_range() const;

    [[nodiscard]] std::shared_ptr<layout_value_guide> const &left() const;
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &right() const;
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &bottom() const;
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &top() const;
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &width() const;
    [[nodiscard]] std::shared_ptr<layout_value_guide> const &height() const;

    void set_horizontal_range(ui::range &&);
    void set_horizontal_range(ui::range const &);
    void set_vertical_range(ui::range &&);
    void set_vertical_range(ui::range const &);
    void set_ranges(region_ranges_args &&);
    void set_region(ui::region const &);

    [[nodiscard]] ui::region region() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    [[nodiscard]] observing::syncable observe(observing::caller<ui::region>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<layout_region_guide> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_region_guide> make_shared(region_ranges_args);
    [[nodiscard]] static std::shared_ptr<layout_region_guide> make_shared(ui::region);

   private:
    std::shared_ptr<layout_range_guide> _vertical_range;
    std::shared_ptr<layout_range_guide> _horizontal_range;

    explicit layout_region_guide(region_ranges_args);
    explicit layout_region_guide(ui::region);

    layout_region_guide(layout_region_guide const &) = delete;
    layout_region_guide(layout_region_guide &&) = delete;
    layout_region_guide &operator=(layout_region_guide const &) = delete;
    layout_region_guide &operator=(layout_region_guide &&) = delete;

    void set_layout_region(ui::region const &) override;
    observing::syncable observe_layout_region(std::function<void(ui::region const &)> &&) override;
    std::shared_ptr<layout_range_source> layout_horizontal_range_source() override;
    std::shared_ptr<layout_range_source> layout_vertical_range_source() override;
};

struct layout_value_guide_pair final {
    std::shared_ptr<layout_value_guide> source;
    std::shared_ptr<layout_value_guide> destination;
};

struct layout_point_guide_pair final {
    std::shared_ptr<layout_point_guide> source;
    std::shared_ptr<layout_point_guide> destination;
};

struct layout_range_guide_pair final {
    std::shared_ptr<layout_range_guide> source;
    std::shared_ptr<layout_range_guide> destination;
};

struct layout_region_guide_pair final {
    std::shared_ptr<layout_region_guide> source;
    std::shared_ptr<layout_region_guide> destination;
};

std::vector<ui::layout_value_guide_pair> make_layout_guide_pairs(layout_point_guide_pair);
std::vector<ui::layout_value_guide_pair> make_layout_guide_pairs(layout_range_guide_pair);
std::vector<ui::layout_value_guide_pair> make_layout_guide_pairs(layout_region_guide_pair);
}  // namespace yas::ui
