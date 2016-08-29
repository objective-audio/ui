//
//  yas_ui_fixed_layout.cpp
//

#include "yas_ui_fixed_layout.h"
#include "yas_ui_layout.h"

using namespace yas;

ui::layout ui::make_fixed_layout(fixed_layout_args args) {
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
