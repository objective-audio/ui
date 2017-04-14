//
//  yas_ui_layout.cpp
//

#include <numeric>
#include "yas_ui_layout.h"
#include "yas_fast_each.h"

using namespace yas;

struct ui::layout::impl : base::impl {
    args _args;

    impl(args &&args) : _args(std::move(args)) {
    }

    void prepare(ui::layout &layout) {
        auto weak_layout = to_weak(layout);

        auto handler = [weak_layout](auto const &context) {
            if (auto layout = weak_layout.lock()) {
                layout.impl_ptr<impl>()->_update_destination_values();
            }
        };

        _guide_observers.reserve(_args.source_guides.size());

        for (auto &guide : _args.source_guides) {
            _guide_observers.emplace_back(
                guide.subject().make_observer(ui::layout_guide::method::value_changed, handler));
        }

        _update_destination_values();
    }

   private:
    std::vector<ui::layout_guide::observer_t> _guide_observers;

    void _update_destination_values() {
        if (_args.handler) {
            _args.handler(_args.source_guides, _args.destination_guides);
        }
    }
};

ui::layout::layout(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout::layout(std::nullptr_t) : base(nullptr) {
}

ui::layout::~layout() = default;

std::vector<ui::layout_guide> const &ui::layout::source_guides() const {
    return impl_ptr<impl>()->_args.source_guides;
}

std::vector<ui::layout_guide> const &ui::layout::destination_guides() const {
    return impl_ptr<impl>()->_args.destination_guides;
}

#pragma mark - fixed_layout

ui::layout ui::make_layout(fixed_layout::args args) {
    if (!args.source_guide || !args.destination_guide) {
        throw "argument is null.";
    }

    auto handler = [distance = std::move(args.distance)](auto const &src_guides, auto &dst_guides) {
        dst_guides.at(0).set_value(src_guides.at(0).value() + distance);
    };

    return ui::layout{{.source_guides = {std::move(args.source_guide)},
                       .destination_guides = {std::move(args.destination_guide)},
                       .handler = std::move(handler)}};
}

#pragma mark - jusitified_layout

ui::layout ui::make_layout(justified_layout::args args) {
    if (!args.first_source_guide) {
        throw "first_source_guide is null.";
    }

    if (!args.second_source_guide) {
        throw "second_source_guide is null.";
    }

    if (args.destination_guides.size() == 0) {
        throw "destination_guides is empty.";
    }

    if (args.ratios.size() > 0 && args.ratios.size() != args.destination_guides.size() - 1) {
        throw "rations not equal to [destination_guides.size - 1].";
    }

    auto const count = args.destination_guides.size();
    std::vector<float> normalized_rates;

    if (count > 1) {
        normalized_rates.reserve(count);
        normalized_rates.emplace_back(0.0f);

        if (args.ratios.size() > 0) {
            auto const total = std::accumulate(args.ratios.begin(), args.ratios.end(), 0.0f);
            auto sum = 0.0f;
            for (auto const &ratio : args.ratios) {
                sum += ratio;
                normalized_rates.emplace_back(sum / total);
            }
        } else {
            auto const rate = 1.0f / static_cast<float>(count - 1);
            auto each = fast_each<std::size_t>(1, count);
            while (yas_each_next(each)) {
                normalized_rates.emplace_back(rate * yas_each_index(each));
            }
        }

        if (count != normalized_rates.size()) {
            throw "_normalized_rates.size is not equal to _args.destination_guides.size.";
        }
    }

    auto handler = [normalized_rates = std::move(normalized_rates)](auto const &src_guides, auto &dst_guides) {
        auto const count = dst_guides.size();
        auto const first_value = src_guides.at(0).value();
        auto const distance = src_guides.at(1).value() - first_value;

        if (count == 1) {
            dst_guides.at(0).set_value(first_value + distance * 0.5f);
        } else {
            auto each = make_fast_each(count);
            while (yas_each_next(each)) {
                auto const &idx = yas_each_index(each);
                auto &dst_guide = dst_guides.at(idx);
                auto &rate = normalized_rates.at(idx);
                dst_guide.set_value(first_value + distance * rate);
            }
        }
    };

    return ui::layout{{.source_guides = {std::move(args.first_source_guide), std::move(args.second_source_guide)},
                       .destination_guides = std::move(args.destination_guides),
                       .handler = std::move(handler)}};
}

#pragma mark - other layouts

ui::layout ui::make_layout(min_layout::args args) {
    if (args.source_guides.size() == 0) {
        throw "source_guides is empty.";
    }

    if (!args.destination_guide) {
        throw "destination_guide is null.";
    }

    auto handler = [](auto const &src_guides, auto &dst_guides) {
        std::experimental::optional<float> value;

        for (auto const &src_guide : src_guides) {
            if (value) {
                value = std::min(src_guide.value(), *value);
            } else {
                value = src_guide.value();
            }
        }

        dst_guides.at(0).set_value(*value);
    };

    return ui::layout{{.source_guides = std::move(args.source_guides),
                       .destination_guides = {std::move(args.destination_guide)},
                       .handler = std::move(handler)}};
}

ui::layout ui::make_layout(max_layout::args args) {
    if (args.source_guides.size() == 0) {
        throw "source_guides is empty.";
    }

    if (!args.destination_guide) {
        throw "destination_guide is null.";
    }

    auto handler = [](auto const &src_guides, auto &dst_guides) {
        std::experimental::optional<float> value;

        for (auto const &src_guide : src_guides) {
            if (value) {
                value = std::max(src_guide.value(), *value);
            } else {
                value = src_guide.value();
            }
        }

        dst_guides.at(0).set_value(*value);
    };

    return ui::layout{{.source_guides = std::move(args.source_guides),
                       .destination_guides = {std::move(args.destination_guide)},
                       .handler = std::move(handler)}};
}
