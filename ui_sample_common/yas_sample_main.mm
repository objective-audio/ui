//
//  yas_sample_main.mm
//

#include <iostream>
#include "yas_sample_main.h"

using namespace yas;

void sample::main::setup() {
    auto const scale_factor = renderer.scale_factor();

    auto &root_node = renderer.root_node();

    _bg_node = sample::bg_node{};
    _cursor_over_node = sample::cursor_over_node{};
    _cursor_node = sample::cursor_node{};
    _touch_holder = sample::touch_holder(renderer.device(), scale_factor);

    root_node.push_back_sub_node(_bg_node.square_node().node());
    root_node.push_back_sub_node(_cursor_over_node.node());
    root_node.push_back_sub_node(_button_node.square_node().node());
    root_node.push_back_sub_node(_cursor_node.node());
    root_node.push_back_sub_node(_touch_holder.node());

    if (auto texture_result = ui::make_texture(renderer.device(), {1024, 1024}, scale_factor)) {
        ui::font_atlas font_atlas{"TrebuchetMS-Bold", 26.0f,
                                  " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+-",
                                  std::move(texture_result.value())};

        _text_node = sample::text_node{font_atlas};
        _modifier_node = sample::modifier_node{font_atlas};
        _button_status_node = sample::button_status_node{font_atlas};

        _button_observer =
            _button_node.subject().make_wild_card_observer([weak_status_node =
                                                                to_weak(_button_status_node)](auto const &context) {
                if (auto status_node = weak_status_node.lock()) {
                    status_node.set_status(context.key);
                }
            });

        root_node.push_back_sub_node(_text_node.strings_node().square_node().node());
        root_node.push_back_sub_node(_modifier_node.strings_node().square_node().node());
        root_node.push_back_sub_node(_button_status_node.strings_node().square_node().node());
    } else {
        std::cout << "make_texture error : " << texture_result.error() << std::endl;
    }
}