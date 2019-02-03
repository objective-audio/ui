//
//  yas_ui_layout_guide.cpp
//

#include "yas_ui_layout_guide.h"
#include <cpp_utils/yas_delaying_caller.h>

using namespace yas;

#pragma mark - ui::layout_guide::impl

struct ui::layout_guide::impl : base::impl {
    chaining::value::holder<float> _value;
    chaining::receiver<float> _receiver = nullptr;

    impl(float const value) : _value(value) {
    }

    void prepare(layout_guide &guide) {
        auto weak_guide = to_weak(cast<layout_guide>());

        this->_receiver = chaining::receiver<float>([weak_guide](float const &value) {
            if (auto guide = weak_guide.lock()) {
                guide.set_value(value);
            }
        });
    }

    void push_notify_waiting() {
        this->_wait_sender.notify(true);
    }

    void pop_notify_waiting() {
        this->_wait_sender.notify(false);
    }

    chain_t chain() {
        auto weak_guide = to_weak(cast<layout_guide>());

        auto old_cache = std::make_shared<std::optional<float>>();

        return this->_value.chain()
            .guard([weak_guide](float const &) { return !!weak_guide; })
            .pair(this->_wait_sender.chain().guard([count = int32_t(0)](bool const &is_wait) mutable {
                if (is_wait) {
                    ++count;
                    return (count == 1);
                } else {
                    --count;
                    if (count < 0) {
                        std::underflow_error("");
                    }
                    return (count == 0);
                }
            }))
            .to([cache = std::optional<float>(), old_cache, is_wait = false,
                 weak_guide](std::pair<std::optional<float>, std::optional<bool>> const &pair) mutable {
                bool is_continue = false;

                if (pair.first) {
                    // pointが来た場合はwaitしてなければフロー継続、waitしてればフロー中断
                    cache = *pair.first;
                    is_continue = !is_wait;
                } else if (pair.second) {
                    // waitフラグが来た場合
                    is_wait = *pair.second;

                    auto guide_impl = weak_guide.lock().impl_ptr<layout_guide::impl>();

                    if (is_wait) {
                        // wait開始ならキャッシュをクリアしてフロー中断
                        cache = std::nullopt;
                        is_continue = false;
                        *old_cache = guide_impl->_value.raw();
                    } else {
                        // wait終了ならキャッシュに値があればフロー継続
                        is_continue = !!cache;
                        if (!is_continue) {
                            *old_cache = std::nullopt;
                        }
                    }
                }

                return std::make_pair(cache, is_continue);
            })
            .guard([](auto const &pair) { return pair.second; })
            .guard([weak_guide, old_cache](auto const &pair) {
                auto guide_impl = weak_guide.lock().impl_ptr<ui::layout_guide::impl>();
                if (!*old_cache) {
                    return true;
                }
                float const old_value = **old_cache;
                *old_cache = std::nullopt;
                return old_value != *pair.first;
            })
            .to([](std::pair<std::optional<float>, bool> const &pair) { return *pair.first; });
    }

   private:
    chaining::notifier<bool> _wait_sender;
};

#pragma mark - ui::layout_guide

ui::layout_guide::layout_guide() : layout_guide(0.0f) {
}

ui::layout_guide::layout_guide(float const value) : base(std::make_shared<impl>(value)) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout_guide::layout_guide(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide::~layout_guide() = default;

void ui::layout_guide::set_value(float const value) {
    impl_ptr<impl>()->_value.set_value(value);
}

float const &ui::layout_guide::value() const {
    return impl_ptr<impl>()->_value.raw();
}

void ui::layout_guide::push_notify_waiting() {
    impl_ptr<impl>()->push_notify_waiting();
}

void ui::layout_guide::pop_notify_waiting() {
    impl_ptr<impl>()->pop_notify_waiting();
}

ui::layout_guide::chain_t ui::layout_guide::chain() const {
    return impl_ptr<impl>()->chain();
}

chaining::receiver<float> &ui::layout_guide::receiver() {
    return impl_ptr<impl>()->_receiver;
}

#pragma mark - ui::layout_guide_point::impl

struct ui::layout_guide_point::impl : base::impl {
    layout_guide _x_guide;
    layout_guide _y_guide;

    chaining::receiver<ui::point> _receiver = nullptr;

    impl(ui::point &&origin) : _x_guide(origin.x), _y_guide(origin.y) {
    }

    void prepare(ui::layout_guide_point &guide_point) {
        auto weak_guide_point = to_weak(guide_point);

        this->_receiver = chaining::receiver<ui::point>([weak_guide_point](ui::point const &point) {
            if (auto guide_point = weak_guide_point.lock()) {
                guide_point.set_point(point);
            }
        });
    }

    void set_point(ui::point &&point) {
        this->push_notify_waiting();

        this->_x_guide.set_value(std::move(point.x));
        this->_y_guide.set_value(std::move(point.y));

        this->pop_notify_waiting();
    }

    ui::point point() {
        return ui::point{_x_guide.value(), _y_guide.value()};
    }

    void push_notify_waiting() {
        this->_x_guide.push_notify_waiting();
        this->_y_guide.push_notify_waiting();
    }

    void pop_notify_waiting() {
        this->_x_guide.pop_notify_waiting();
        this->_y_guide.pop_notify_waiting();
    }

    chain_t chain() {
        auto cache = this->point();

        return this->_x_guide.chain()
            .pair(this->_y_guide.chain())
            .to([cache](std::pair<std::optional<float>, std::optional<float>> const &pair) mutable {
                if (pair.first) {
                    cache.x = *pair.first;
                }
                if (pair.second) {
                    cache.y = *pair.second;
                }
                return cache;
            });
    }
};

#pragma mark - ui::layout_guide_point

ui::layout_guide_point::layout_guide_point() : layout_guide_point(ui::point{}) {
}

ui::layout_guide_point::layout_guide_point(ui::point origin) : base(std::make_shared<impl>(std::move(origin))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout_guide_point::layout_guide_point(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide_point::~layout_guide_point() = default;

ui::layout_guide &ui::layout_guide_point::x() {
    return impl_ptr<impl>()->_x_guide;
}

ui::layout_guide &ui::layout_guide_point::y() {
    return impl_ptr<impl>()->_y_guide;
}

ui::layout_guide const &ui::layout_guide_point::x() const {
    return impl_ptr<impl>()->_x_guide;
}

ui::layout_guide const &ui::layout_guide_point::y() const {
    return impl_ptr<impl>()->_y_guide;
}

void ui::layout_guide_point::set_point(ui::point point) {
    impl_ptr<impl>()->set_point(std::move(point));
}

ui::point ui::layout_guide_point::point() const {
    return impl_ptr<impl>()->point();
}

void ui::layout_guide_point::push_notify_waiting() {
    impl_ptr<impl>()->push_notify_waiting();
}

void ui::layout_guide_point::pop_notify_waiting() {
    impl_ptr<impl>()->pop_notify_waiting();
}

ui::layout_guide_point::chain_t ui::layout_guide_point::chain() const {
    return impl_ptr<impl>()->chain();
}

chaining::receiver<ui::point> &ui::layout_guide_point::receiver() {
    return impl_ptr<impl>()->_receiver;
}

#pragma mark - ui::layout_guide_range::impl

struct ui::layout_guide_range::impl : base::impl {
    layout_guide _min_guide;
    layout_guide _max_guide;
    layout_guide _length_guide;
    chaining::any_observer _min_observer = nullptr;
    chaining::any_observer _max_observer = nullptr;

    chaining::receiver<ui::range> _receiver = nullptr;

    impl(ui::range &&range) : _min_guide(range.min()), _max_guide(range.max()), _length_guide(range.length) {
    }

    void prepare(ui::layout_guide_range &range) {
        auto weak_range = to_weak(range);

        this->_min_observer = this->_min_guide.chain()
                                  .guard([weak_range](float const &) { return !!weak_range; })
                                  .to([weak_range](float const &min) { return weak_range.lock().max().value() - min; })
                                  .receive(this->_length_guide.receiver())
                                  .end();

        this->_max_observer = this->_max_guide.chain()
                                  .guard([weak_range](float const &) { return !!weak_range; })
                                  .to([weak_range](float const &max) { return max - weak_range.lock().min().value(); })
                                  .receive(this->_length_guide.receiver())
                                  .end();

        this->_receiver = chaining::receiver<ui::range>{[weak_range](ui::range const &range) {
            if (auto guide_range = weak_range.lock()) {
                guide_range.set_range(range);
            }
        }};
    }

    void set_range(ui::range &&range) {
        this->push_notify_waiting();

        this->_min_guide.set_value(range.min());
        this->_max_guide.set_value(range.max());

        this->pop_notify_waiting();
    }

    ui::range range() {
        auto const &min = this->_min_guide.value();
        auto const &max = this->_max_guide.value();

        return ui::range{.location = min, .length = max - min};
    }

    void push_notify_waiting() {
        this->_min_guide.push_notify_waiting();
        this->_max_guide.push_notify_waiting();
        this->_length_guide.push_notify_waiting();
    }

    void pop_notify_waiting() {
        this->_min_guide.pop_notify_waiting();
        this->_max_guide.pop_notify_waiting();
        this->_length_guide.pop_notify_waiting();
    }

    chain_t chain() {
        ui::range const range = this->range();

        return this->_min_guide.chain()
            .pair(this->_max_guide.chain())
            .to([min_cache = range.min(),
                 max_cache = range.max()](std::pair<std::optional<float>, std::optional<float>> const &pair) mutable {
                if (pair.first) {
                    min_cache = *pair.first;
                }
                if (pair.second) {
                    max_cache = *pair.second;
                }
                return ui::range{min_cache, max_cache - min_cache};
            });
    }
};

#pragma mark - ui::layout_guide_range

ui::layout_guide_range::layout_guide_range() : layout_guide_range(ui::range{}) {
}

ui::layout_guide_range::layout_guide_range(ui::range range) : base(std::make_shared<impl>(std::move(range))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout_guide_range::layout_guide_range(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide_range::~layout_guide_range() = default;

ui::layout_guide &ui::layout_guide_range::min() {
    return impl_ptr<impl>()->_min_guide;
}

ui::layout_guide &ui::layout_guide_range::max() {
    return impl_ptr<impl>()->_max_guide;
}

ui::layout_guide const &ui::layout_guide_range::min() const {
    return impl_ptr<impl>()->_min_guide;
}

ui::layout_guide const &ui::layout_guide_range::max() const {
    return impl_ptr<impl>()->_max_guide;
}

ui::layout_guide const &ui::layout_guide_range::length() const {
    return impl_ptr<impl>()->_length_guide;
}

void ui::layout_guide_range::set_range(ui::range range) {
    impl_ptr<impl>()->set_range(std::move(range));
}

ui::range ui::layout_guide_range::range() const {
    return impl_ptr<impl>()->range();
}

void ui::layout_guide_range::push_notify_waiting() {
    impl_ptr<impl>()->push_notify_waiting();
}

void ui::layout_guide_range::pop_notify_waiting() {
    impl_ptr<impl>()->pop_notify_waiting();
}

ui::layout_guide_range::chain_t ui::layout_guide_range::chain() const {
    return impl_ptr<impl>()->chain();
}

chaining::receiver<ui::range> &ui::layout_guide_range::receiver() {
    return impl_ptr<impl>()->_receiver;
}

#pragma mark - ui::layout_guide_rect::impl

struct ui::layout_guide_rect::impl : base::impl {
    layout_guide_range _vertical_range;
    layout_guide_range _horizontal_range;

    chaining::receiver<ui::region> _receiver = nullptr;

    impl(ranges_args &&args)
        : _vertical_range(std::move(args.vertical_range)), _horizontal_range(std::move(args.horizontal_range)) {
    }

    void prepare(ui::layout_guide_rect &guide_rect) {
        auto weak_guide_rect = to_weak(guide_rect);
        this->_receiver = chaining::receiver<ui::region>{[weak_guide_rect](ui::region const &region) {
            if (auto guide_rect = weak_guide_rect.lock()) {
                guide_rect.set_region(region);
            }
        }};
    }

    void set_vertical_range(ui::range &&range) {
        this->_vertical_range.set_range(std::move(range));
    }

    void set_horizontal_range(ui::range &&range) {
        this->_horizontal_range.set_range(std::move(range));
    }

    void set_ranges(ranges_args &&args) {
        this->_vertical_range.push_notify_waiting();
        this->_horizontal_range.push_notify_waiting();

        this->set_vertical_range(std::move(args.vertical_range));
        this->set_horizontal_range(std::move(args.horizontal_range));

        this->_vertical_range.pop_notify_waiting();
        this->_horizontal_range.pop_notify_waiting();
    }

    void set_region(ui::region &&region) {
        this->set_ranges({.vertical_range = region.vertical_range(), .horizontal_range = region.horizontal_range()});
    }

    ui::region region() {
        auto h_range = this->_horizontal_range.range();
        auto v_range = this->_vertical_range.range();

        return ui::make_region(h_range, v_range);
    }

    void push_notify_waiting() {
        this->_vertical_range.push_notify_waiting();
        this->_horizontal_range.push_notify_waiting();
    }

    void pop_notify_waiting() {
        this->_vertical_range.pop_notify_waiting();
        this->_horizontal_range.pop_notify_waiting();
    }

    chain_t chain() {
        ui::region const region = this->region();

        return this->_vertical_range.chain()
            .pair(this->_horizontal_range.chain())
            .to([v_cache = region.vertical_range(), h_cache = region.horizontal_range()](
                    std::pair<std::optional<ui::range>, std::optional<ui::range>> const &pair) mutable {
                if (pair.first) {
                    v_cache = *pair.first;
                }
                if (pair.second) {
                    h_cache = *pair.second;
                }
                return ui::make_region(h_cache, v_cache);
            });
    }
};

#pragma mark - ui::layout_guide_rect

ui::layout_guide_rect::layout_guide_rect()
    : layout_guide_rect(ranges_args{.horizontal_range = {.v = 0.0f}, .vertical_range = {.v = 0.0f}}) {
}

ui::layout_guide_rect::layout_guide_rect(ranges_args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout_guide_rect::layout_guide_rect(ui::region region)
    : layout_guide_rect({.horizontal_range = region.horizontal_range(), .vertical_range = region.vertical_range()}) {
}

ui::layout_guide_rect::layout_guide_rect(std::nullptr_t) : base(nullptr) {
}

ui::layout_guide_rect::~layout_guide_rect() = default;

ui::layout_guide_range &ui::layout_guide_rect::horizontal_range() {
    return impl_ptr<impl>()->_horizontal_range;
}

ui::layout_guide_range &ui::layout_guide_rect::vertical_range() {
    return impl_ptr<impl>()->_vertical_range;
}

ui::layout_guide_range const &ui::layout_guide_rect::horizontal_range() const {
    return impl_ptr<impl>()->_horizontal_range;
}

ui::layout_guide_range const &ui::layout_guide_rect::vertical_range() const {
    return impl_ptr<impl>()->_vertical_range;
}

ui::layout_guide &ui::layout_guide_rect::left() {
    return this->horizontal_range().min();
}

ui::layout_guide &ui::layout_guide_rect::right() {
    return this->horizontal_range().max();
}

ui::layout_guide &ui::layout_guide_rect::bottom() {
    return this->vertical_range().min();
}

ui::layout_guide &ui::layout_guide_rect::top() {
    return this->vertical_range().max();
}

ui::layout_guide const &ui::layout_guide_rect::left() const {
    return this->horizontal_range().min();
}

ui::layout_guide const &ui::layout_guide_rect::right() const {
    return this->horizontal_range().max();
}

ui::layout_guide const &ui::layout_guide_rect::bottom() const {
    return this->vertical_range().min();
}

ui::layout_guide const &ui::layout_guide_rect::top() const {
    return this->vertical_range().max();
}

ui::layout_guide const &ui::layout_guide_rect::width() const {
    return this->horizontal_range().length();
}

ui::layout_guide const &ui::layout_guide_rect::height() const {
    return this->vertical_range().length();
}

void ui::layout_guide_rect::set_horizontal_range(ui::range range) {
    impl_ptr<impl>()->set_horizontal_range(std::move(range));
}

void ui::layout_guide_rect::set_vertical_range(ui::range range) {
    impl_ptr<impl>()->set_vertical_range(std::move(range));
}

void ui::layout_guide_rect::set_ranges(ranges_args args) {
    impl_ptr<impl>()->set_ranges(std::move(args));
}

void ui::layout_guide_rect::set_region(ui::region region) {
    impl_ptr<impl>()->set_region(std::move(region));
}

ui::region ui::layout_guide_rect::region() const {
    return impl_ptr<impl>()->region();
}

void ui::layout_guide_rect::push_notify_waiting() {
    impl_ptr<impl>()->push_notify_waiting();
}

void ui::layout_guide_rect::pop_notify_waiting() {
    impl_ptr<impl>()->pop_notify_waiting();
}

ui::layout_guide_rect::chain_t ui::layout_guide_rect::chain() const {
    return impl_ptr<impl>()->chain();
}

chaining::receiver<ui::region> &ui::layout_guide_rect::receiver() {
    return impl_ptr<impl>()->_receiver;
}

#pragma mark - layout_guide_pair

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_point_pair point_pair) {
    return {ui::layout_guide_pair{.source = point_pair.source.x(), .destination = point_pair.destination.x()},
            ui::layout_guide_pair{.source = point_pair.source.y(), .destination = point_pair.destination.y()}};
}

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_range_pair range_pair) {
    return {ui::layout_guide_pair{.source = range_pair.source.min(), .destination = range_pair.destination.min()},
            ui::layout_guide_pair{.source = range_pair.source.max(), .destination = range_pair.destination.max()}};
}

std::vector<ui::layout_guide_pair> ui::make_layout_guide_pairs(ui::layout_guide_rect_pair rect_pair) {
    return {ui::layout_guide_pair{.source = rect_pair.source.left(), .destination = rect_pair.destination.left()},
            ui::layout_guide_pair{.source = rect_pair.source.right(), .destination = rect_pair.destination.right()},
            ui::layout_guide_pair{.source = rect_pair.source.bottom(), .destination = rect_pair.destination.bottom()},
            ui::layout_guide_pair{.source = rect_pair.source.top(), .destination = rect_pair.destination.top()}};
}
