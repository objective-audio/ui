//
//  yas_ui_chaining_utils.cpp
//

#include "yas_ui_chaining_utils.h"

using namespace yas;

std::vector<float> ui::justify(float const begin, float const end, std::size_t const count,
                               std::function<float(std::size_t const &)> const &ratio_handler) {
    float sum = 0.0f;
    float total = 0.0f;

    std::vector<float> ratios;
    ratios.reserve(count);

    auto each = make_fast_each(count);
    while (yas_each_next(each)) {
        float const ratio = ratio_handler(yas_each_index(each));
        ratios.emplace_back(ratio);
        total += ratio;
    }

    float const distance = end - begin;

    std::vector<float> out_values;
    out_values.reserve(count + 1);

    each = make_fast_each(count + 1);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        if (idx == 0) {
            if (count == 0) {
                out_values.emplace_back(begin + distance * 0.5f);
            } else {
                out_values.emplace_back(begin);
            }
        } else {
            sum += ratios.at(idx - 1);
            out_values.emplace_back(begin + distance * (sum / total));
        }
    }

    return out_values;
}

std::vector<float> ui::justify(float const begin, float const end, std::vector<float> const &ratios) {
    return ui::justify(

        begin, end, ratios.size(), [ratios](std::size_t const &idx) {
            if (idx < ratios.size()) {
                return ratios.at(idx);
            } else {
                return 0.0f;
            }
        });
}
