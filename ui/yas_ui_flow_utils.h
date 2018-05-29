//
//  yas_ui_layout.h
//

#pragma once

#include <numeric>
#include "yas_fast_each.h"

namespace yas::ui {
template <int N>
auto justify(std::array<float, N> const &ratios) {
    static_assert(N >= 0, "justify N must be greater than or equal 0.");

    return [ratios](std::pair<float, float> const &pair) {
        std::array<float, N + 1> out_values;

        float sum = 0.0f;
        float const total = std::accumulate(ratios.begin(), ratios.end(), 0.0f);
        float const first_value = pair.first;
        float const distance = pair.second - first_value;

        auto each = make_fast_each(N + 1);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            if (idx == 0) {
                if (N == 0) {
                    out_values.at(idx) = first_value + distance * 0.5f;
                } else {
                    out_values.at(idx) = first_value;
                }
            } else {
                sum += ratios.at(idx - 1);
                out_values.at(idx) = first_value + distance * (sum / total);
            }
        }

        return out_values;
    };
}

template <int N = 0>
auto justify() {
    static_assert(N >= 0, "justify N must be greater than or equal 2.");

    std::array<float, N> ratios;
    auto each = make_fast_each(N);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        ratios.at(idx) = 1.0f;
    }
    return justify<N>(ratios);
}
}  // namespace yas::ui
