//
//  yas_ui_chaining_utils.h
//

#pragma once

#include <functional>
#include <numeric>
#include <tuple>
#include <cpp_utils/yas_fast_each.h>

namespace yas::ui {
std::function<std::vector<float>(std::tuple<float, float, std::size_t> const &)> justify(
    std::function<float(std::size_t const &)> const &ratio_handler);
std::function<std::vector<float>(std::tuple<float, float, std::size_t> const &)> justify(
    std::vector<float> const &ratios);

template <int N>
auto justify(std::array<float, N> const &ratios);

template <int N = 0>
auto justify();
}  // namespace yas::ui

#include "yas_ui_chaining_utils_private.h"
