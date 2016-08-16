//
//  yas_ui_justified_layout.cpp
//

#include <numeric>
#include "yas_each_index.h"
#include "yas_ui_justified_layout.h"

using namespace yas;

struct ui::justified_layout::impl : base::impl {
    args _args;

    impl(args &&args) : _args(std::move(args)) {
        if (!_args.first_source_guide) {
            throw "first_source_guide is null.";
        }

        if (!_args.second_source_guide) {
            throw "second_source_guide is null.";
        }

        if (_args.destination_guides.size() == 0) {
            throw "destination_guides is empty.";
        }

        if (_args.ratios.size() > 0 && _args.ratios.size() != _args.destination_guides.size() - 1) {
            throw "rations not equal to [destination_guides.size - 1].";
        }

        _setup_normalized_rates();
    }

    void prepare(ui::justified_layout &layout) {
        auto weak_layout = to_weak(layout);

        auto handler = [weak_layout](auto const &context) {
            if (auto layout = weak_layout.lock()) {
                layout.impl_ptr<impl>()->update_destination_values();
            }
        };

        _first_src_observer =
            _args.first_source_guide.subject().make_observer(ui::layout_guide::method::value_changed, handler);

        _second_src_observer =
            _args.second_source_guide.subject().make_observer(ui::layout_guide::method::value_changed, handler);

        update_destination_values();
    }

    void update_destination_values() {
        auto const count = _args.destination_guides.size();
        auto const first_value = _args.first_source_guide.value();
        auto const distance = _args.second_source_guide.value() - first_value;

        if (count == 1) {
            _args.destination_guides.at(0).set_value(first_value + distance * 0.5f);
        } else {
            for (auto const &idx : make_each(count)) {
                auto &dst_guide = _args.destination_guides.at(idx);
                auto &rate = _normalized_rates.at(idx);
                dst_guide.set_value(first_value + distance * rate);
            }
        }
    }

   private:
    ui::layout_guide::observer_t _first_src_observer;
    ui::layout_guide::observer_t _second_src_observer;
    std::vector<float> _normalized_rates;

    void _setup_normalized_rates() {
        auto const count = _args.destination_guides.size();

        _normalized_rates.clear();

        if (count > 1) {
            _normalized_rates.reserve(count);
            _normalized_rates.emplace_back(0.0f);

            if (_args.ratios.size() > 0) {
                auto const total = std::accumulate(_args.ratios.begin(), _args.ratios.end(), 0.0f);
                auto sum = 0.0f;
                for (auto const &ratio : _args.ratios) {
                    sum += ratio;
                    _normalized_rates.emplace_back(sum / total);
                }
            } else {
                auto const rate = 1.0f / static_cast<float>(count - 1);
                for (auto const &idx : make_each<std::size_t>(1, count)) {
                    _normalized_rates.emplace_back(rate * idx);
                }
            }

            if (count != _normalized_rates.size()) {
                throw "_normalized_rates.size is not equal to _args.destination_guides.size.";
            }
        }
    }
};

ui::justified_layout::justified_layout(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::justified_layout::justified_layout(std::nullptr_t) : base(nullptr) {
}

ui::justified_layout::~justified_layout() = default;

ui::layout_guide const &ui::justified_layout::first_source_guide() const {
    return impl_ptr<impl>()->_args.first_source_guide;
}

ui::layout_guide const &ui::justified_layout::second_source_guide() const {
    return impl_ptr<impl>()->_args.second_source_guide;
}
std::vector<ui::layout_guide> const &ui::justified_layout::destination_guides() const {
    return impl_ptr<impl>()->_args.destination_guides;
}

std::vector<float> const &ui::justified_layout::ratios() const {
    return impl_ptr<impl>()->_args.ratios;
}
