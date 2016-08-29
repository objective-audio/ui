//
//  yas_ui_justified_layout.cpp
//

#include <numeric>
#include "yas_each_index.h"
#include "yas_ui_justified_layout.h"
#include "yas_ui_layout.h"

using namespace yas;

ui::layout ui::make_justified_layout(jusitified_layout_args args) {
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
            for (auto const &idx : make_each<std::size_t>(1, count)) {
                normalized_rates.emplace_back(rate * idx);
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
            for (auto const &idx : make_each(count)) {
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
