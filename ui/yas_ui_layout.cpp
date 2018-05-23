//
//  yas_ui_layout.cpp
//

#include "yas_ui_layout.h"
#include <numeric>
#include "yas_fast_each.h"

using namespace yas;

#pragma mark - jusitified_layout

flow::observer ui::make_flow(justified_layout::args args) {
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

    std::vector<flow::output<float>> dst_outputs;
    for (auto &dst_guide : args.destination_guides) {
        dst_outputs.emplace_back(dst_guide.receiver().flowable().make_output());
    }

    return args.first_source_guide.begin_flow()
        .combine(args.second_source_guide.begin_flow())
        .perform([dst_outputs, normalized_rates](auto const &pair) mutable {
            auto const dst_count = dst_outputs.size();
            auto const first_value = pair.first;
            auto const distance = pair.second - first_value;

            if (dst_count == 1) {
                dst_outputs.at(0).output_value(first_value + distance * 0.5f);
            } else {
                auto each = make_fast_each(dst_count);
                while (yas_each_next(each)) {
                    auto const &idx = yas_each_index(each);
                    auto &output = dst_outputs.at(idx);
                    auto const &rate = normalized_rates.at(idx);
                    output.output_value(first_value + distance * rate);
                }
            }
        })
        .sync();
}

#pragma mark - other layouts

flow::observer ui::make_flow(min_layout::args args) {
    if (args.source_guides.size() < 2) {
        throw "source_guides is less than 2.";
    }

    if (!args.destination_guide) {
        throw "destination_guide is null.";
    }

    flow::node<float> flow = nullptr;

    auto each = make_fast_each(args.source_guides.size());
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto &guide = args.source_guides.at(idx);

        if (flow) {
            flow = flow.combine(guide.begin_flow())
                       .map([](std::pair<float, float> const &pair) { return std::min(pair.first, pair.second); })
                       .normalize();
        } else {
            flow = guide.begin_flow().normalize();
        }
    }

    return flow.receive(args.destination_guide.receiver()).sync();
}

flow::observer ui::make_flow(max_layout::args args) {
    if (args.source_guides.size() < 2) {
        throw "source_guides is less than 2.";
    }

    if (!args.destination_guide) {
        throw "destination_guide is null.";
    }

    flow::node<float> flow = nullptr;

    auto each = make_fast_each(args.source_guides.size());
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto &guide = args.source_guides.at(idx);

        if (flow) {
            flow = flow.combine(guide.begin_flow())
                       .map([](std::pair<float, float> const &pair) { return std::max(pair.first, pair.second); })
                       .normalize();
        } else {
            flow = guide.begin_flow().normalize();
        }
    }

    return flow.receive(args.destination_guide.receiver()).sync();
}
