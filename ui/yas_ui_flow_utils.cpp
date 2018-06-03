//
//  yas_ui_flow_utils.cpp
//

#include "yas_ui_flow_utils.h"

using namespace yas;

std::function<std::vector<float>(std::tuple<float, float, std::size_t> const &)> ui::justify(
    std::function<float(std::size_t const &)> const &ratio_handler) {
    return [ratio_handler](std::tuple<float, float, std::size_t> const &tuple) {
        float sum = 0.0f;
        float total = 0.0f;

        std::size_t const &count = std::get<2>(tuple);
        std::vector<float> ratios;
        ratios.reserve(count);

        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            float const ratio = ratio_handler(yas_each_index(each));
            ratios.emplace_back(ratio);
            total += ratio;
        }

        float const first_value = std::get<0>(tuple);
        float const distance = std::get<1>(tuple) - first_value;

        std::vector<float> out_values;
        out_values.reserve(count + 1);

        each = make_fast_each(count + 1);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            if (idx == 0) {
                if (count == 0) {
                    out_values.emplace_back(first_value + distance * 0.5f);
                } else {
                    out_values.emplace_back(first_value);
                }
            } else {
                sum += ratios.at(idx - 1);
                out_values.emplace_back(first_value + distance * (sum / total));
            }
        }

        return out_values;
    };
}

std::function<std::vector<float>(std::tuple<float, float, std::size_t> const &)> ui::justify(
    std::vector<float> const &ratios) {
    return ui::justify([ratios](std::size_t const &idx) {
        if (idx < ratios.size()) {
            return ratios.at(idx);
        } else {
            return 0.0f;
        }
    });
}
