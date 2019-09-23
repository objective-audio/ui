//
//  yas_ui_layout_guide.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include "yas_ui_action.h"
#include "yas_ui_ptr.h"
#include "yas_ui_types.h"

namespace yas::ui {
struct layout_guide final : chaining::receiver<float>, action_target {
    virtual ~layout_guide();

    void set_value(float const);
    float const &value() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    using chain_t = chaining::chain<float, float, true>;

    [[nodiscard]] chain_t chain() const;

    void receive_value(float const &) override;

    [[nodiscard]] static std::shared_ptr<layout_guide> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide> make_shared(float const);

   private:
    chaining::value::holder_ptr<float> _value;
    layout_guide_wptr _weak_ptr;
    chaining::notifier_ptr<bool> _wait_sender;

    explicit layout_guide(float const);

    layout_guide(layout_guide const &) = delete;
    layout_guide(layout_guide &&) = delete;
    layout_guide &operator=(layout_guide const &) = delete;
    layout_guide &operator=(layout_guide &&) = delete;

    void _prepare(std::shared_ptr<layout_guide> &);
};

struct layout_guide_point final : chaining::receiver<ui::point> {
    virtual ~layout_guide_point();

    ui::layout_guide_ptr &x();
    ui::layout_guide_ptr &y();
    ui::layout_guide_ptr const &x() const;
    ui::layout_guide_ptr const &y() const;

    void set_point(ui::point);
    ui::point point() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    using chain_t = chaining::chain<ui::point, float, true>;

    chain_t chain() const;

    void receive_value(ui::point const &) override;

    [[nodiscard]] static std::shared_ptr<layout_guide_point> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_point> make_shared(ui::point);

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    explicit layout_guide_point(ui::point &&);

    layout_guide_point(layout_guide_point const &) = delete;
    layout_guide_point(layout_guide_point &&) = delete;
    layout_guide_point &operator=(layout_guide_point const &) = delete;
    layout_guide_point &operator=(layout_guide_point &&) = delete;
};

struct layout_guide_range : chaining::receiver<ui::range> {
    virtual ~layout_guide_range() final;

    layout_guide_ptr &min();
    layout_guide_ptr &max();
    layout_guide_ptr const &min() const;
    layout_guide_ptr const &max() const;
    layout_guide_ptr const &length() const;

    void set_range(ui::range const &);
    ui::range range() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    using chain_t = chaining::chain<ui::range, float, true>;

    chain_t chain() const;

    void receive_value(ui::range const &) override;

    [[nodiscard]] static std::shared_ptr<layout_guide_range> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_range> make_shared(ui::range);

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    explicit layout_guide_range(ui::range &&);

    layout_guide_range(layout_guide_range const &) = delete;
    layout_guide_range(layout_guide_range &&) = delete;
    layout_guide_range &operator=(layout_guide_range const &) = delete;
    layout_guide_range &operator=(layout_guide_range &&) = delete;

    void _prepare(std::shared_ptr<layout_guide_range> &range);
};

struct layout_guide_rect final : chaining::receiver<ui::region> {
    struct ranges_args {
        ui::range horizontal_range;
        ui::range vertical_range;
    };

    virtual ~layout_guide_rect();

    layout_guide_range_ptr &horizontal_range();
    layout_guide_range_ptr &vertical_range();
    layout_guide_range_ptr const &horizontal_range() const;
    layout_guide_range_ptr const &vertical_range() const;

    layout_guide_ptr &left();
    layout_guide_ptr &right();
    layout_guide_ptr &bottom();
    layout_guide_ptr &top();
    layout_guide_ptr const &left() const;
    layout_guide_ptr const &right() const;
    layout_guide_ptr const &bottom() const;
    layout_guide_ptr const &top() const;
    layout_guide_ptr const &width() const;
    layout_guide_ptr const &height() const;

    void set_horizontal_range(ui::range);
    void set_vertical_range(ui::range);
    void set_ranges(ranges_args);
    void set_region(ui::region const &);

    ui::region region() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    using chain_t = chaining::chain<ui::region, float, true>;

    chain_t chain() const;

    void receive_value(ui::region const &) override;

    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared();
    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared(ranges_args);
    [[nodiscard]] static std::shared_ptr<layout_guide_rect> make_shared(ui::region);

   private:
    class impl;

    std::unique_ptr<impl> _impl;

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
