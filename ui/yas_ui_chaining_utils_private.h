//
//  yas_ui_chaining_utils_private.h
//

#pragma once

namespace yas::ui {
template <int N>
std::array<float, N + 1> justify(float const begin, float const end, std::array<float, N> const &ratios) {
    static_assert(N >= 0, "justify N must be greater than or equal 0.");

    std::array<float, N + 1> out_values;

    float sum = 0.0f;
    float const total = std::accumulate(ratios.begin(), ratios.end(), 0.0f);
    float const distance = end - begin;

    auto each = make_fast_each(N + 1);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        if (idx == 0) {
            if (N == 0) {
                out_values.at(idx) = begin + distance * 0.5f;
            } else {
                out_values.at(idx) = begin;
            }
        } else {
            sum += ratios.at(idx - 1);
            out_values.at(idx) = begin + distance * (sum / total);
        }
    }

    return out_values;
}

template <int N>
auto justify(float const begin, float const end) {
    static_assert(N >= 0, "justify N must be greater than or equal 2.");

    std::array<float, N> ratios;
    auto each = make_fast_each(N);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        ratios.at(idx) = 1.0f;
    }
    return justify<N>(begin, end, ratios);
}
}  // namespace yas::ui
