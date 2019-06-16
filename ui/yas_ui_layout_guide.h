//
//  yas_ui_layout_guide.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_base.h>
#include "yas_ui_types.h"

namespace yas::ui {
struct layout_guide : base, chaining::receiver<float> {
    class impl;

    layout_guide();
    explicit layout_guide(float const);
    layout_guide(std::nullptr_t);

    virtual ~layout_guide() final;

    void set_value(float const);
    float const &value() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    using chain_t = chaining::chain<float, float, true>;

    [[nodiscard]] chain_t chain() const;
    [[nodiscard]] chaining::receivable<float> receivable() override;

   private:
    chaining::receivable<float> _receivable = nullptr;
};

struct layout_guide_point : base, chaining::receiver<ui::point> {
    class impl;

    layout_guide_point();
    explicit layout_guide_point(ui::point);
    layout_guide_point(std::nullptr_t);

    virtual ~layout_guide_point() final;

    ui::layout_guide &x();
    ui::layout_guide &y();
    ui::layout_guide const &x() const;
    ui::layout_guide const &y() const;

    void set_point(ui::point);
    ui::point point() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    using chain_t = chaining::chain<ui::point, float, true>;

    chain_t chain() const;
    chaining::receivable<ui::point> receivable();

   private:
    chaining::receivable<ui::point> _receivable = nullptr;
};

class layout_guide_range : public base {
   public:
    class impl;

    layout_guide_range();
    explicit layout_guide_range(ui::range);
    layout_guide_range(std::nullptr_t);

    virtual ~layout_guide_range() final;

    layout_guide &min();
    layout_guide &max();
    layout_guide const &min() const;
    layout_guide const &max() const;
    layout_guide const &length() const;

    void set_range(ui::range);
    ui::range range() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    using chain_t = chaining::chain<ui::range, float, true>;

    chain_t chain() const;
    chaining::perform_receiver<ui::range> &receiver();
};

class layout_guide_rect : public base {
   public:
    class impl;

    struct ranges_args {
        ui::range horizontal_range;
        ui::range vertical_range;
    };

    layout_guide_rect();
    explicit layout_guide_rect(ranges_args);
    explicit layout_guide_rect(ui::region);
    layout_guide_rect(std::nullptr_t);

    virtual ~layout_guide_rect() final;

    layout_guide_range &horizontal_range();
    layout_guide_range &vertical_range();
    layout_guide_range const &horizontal_range() const;
    layout_guide_range const &vertical_range() const;

    layout_guide &left();
    layout_guide &right();
    layout_guide &bottom();
    layout_guide &top();
    layout_guide const &left() const;
    layout_guide const &right() const;
    layout_guide const &bottom() const;
    layout_guide const &top() const;
    layout_guide const &width() const;
    layout_guide const &height() const;

    void set_horizontal_range(ui::range);
    void set_vertical_range(ui::range);
    void set_ranges(ranges_args);
    void set_region(ui::region);

    ui::region region() const;

    void push_notify_waiting();
    void pop_notify_waiting();

    using chain_t = chaining::chain<ui::region, float, true>;

    chain_t chain() const;
    chaining::perform_receiver<ui::region> &receiver();
};

struct layout_guide_pair {
    ui::layout_guide source;
    ui::layout_guide destination;
};

struct layout_guide_point_pair {
    ui::layout_guide_point source;
    ui::layout_guide_point destination;
};

struct layout_guide_range_pair {
    ui::layout_guide_range source;
    ui::layout_guide_range destination;
};

struct layout_guide_rect_pair {
    ui::layout_guide_rect source;
    ui::layout_guide_rect destination;
};

std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_point_pair);
std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_range_pair);
std::vector<ui::layout_guide_pair> make_layout_guide_pairs(layout_guide_rect_pair);
}  // namespace yas::ui
