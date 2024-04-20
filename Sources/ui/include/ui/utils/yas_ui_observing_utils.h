//
//  yas_ui_observing_utils.h
//

#pragma once

#include <cpp-utils/yas_fast_each.h>

#include <functional>
#include <numeric>
#include <tuple>

namespace yas::ui {
std::vector<float> justify(float const begin, float const end, std::size_t const count,
                           std::function<float(std::size_t const &)> const &ratio_handler);
std::vector<float> justify(float const begin, float const end, std::vector<float> const &ratios);

template <int N>
std::array<float, N + 1> justify(float const begin, float const end, std::array<float, N> const &ratios);

template <int N = 0>
auto justify(float const begin, float const end);
}  // namespace yas::ui

#include "yas_ui_observing_utils_private.h"
