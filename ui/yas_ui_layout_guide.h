//
//  yas_ui_layout_guide.h
//

#pragma once

#include "yas_base.h"
#include "yas_observing.h"
#include "yas_ui_types.h"
#include "yas_flow.h"

namespace yas::ui {
class layout_guide : public base {
   public:
    class impl;

    struct change_context {
        float const &new_value;
        layout_guide const &layout_guide;
    };

    enum class method {
        value_changed,
    };

    using subject_t = subject<method, change_context>;
    using observer_t = observer<method, change_context>;
    using value_changed_f = std::function<void(change_context const &)>;

    layout_guide();
    explicit layout_guide(float const);
    layout_guide(std::nullptr_t);

    virtual ~layout_guide() final;

    void set_value(float const);
    float const &value() const;

    void set_value_changed_handler(value_changed_f);

    subject_t &subject();

    void push_notify_caller();
    void pop_notify_caller();
    
    using flow_t = flow::node<float, std::pair<opt_t<float>, bool>, float>;
    
    flow_t begin_flow();
    flow::receivable<float> receivable();
};

class layout_guide_point : public base {
   public:
    class impl;

    struct change_context {
        ui::point const &old_value;
        ui::point const &new_value;
        layout_guide_point const &layout_guide_point;
    };

    using value_changed_f = std::function<void(change_context const &)>;

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

    void set_value_changed_handler(value_changed_f);

    void push_notify_caller();
    void pop_notify_caller();
};

class layout_guide_range : public base {
   public:
    class impl;

    struct change_context {
        ui::range const &old_value;
        ui::range const &new_value;
        layout_guide_range const &layout_guide_range;
    };

    using value_changed_f = std::function<void(change_context const &)>;

    layout_guide_range();
    explicit layout_guide_range(ui::range);
    layout_guide_range(std::nullptr_t);

    virtual ~layout_guide_range() final;

    layout_guide &min();
    layout_guide &max();
    layout_guide &length();
    layout_guide const &min() const;
    layout_guide const &max() const;
    layout_guide const &length() const;

    void set_range(ui::range);
    ui::range range() const;

    void set_value_changed_handler(value_changed_f);

    void push_notify_caller();
    void pop_notify_caller();
};

class layout_guide_rect : public base {
   public:
    class impl;

    struct change_context {
        ui::region const &old_value;
        ui::region const &new_value;
        layout_guide_rect const &layout_guide_rect;
    };

    using value_changed_f = std::function<void(change_context const &)>;

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
    layout_guide &width();
    layout_guide &height();
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

    void set_value_changed_handler(value_changed_f);

    void push_notify_caller();
    void pop_notify_caller();
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
}
