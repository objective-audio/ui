//
//  yas_sample_main.mm
//

#include <iostream>
#include "yas_sample_main.h"

using namespace yas;

void sample::main::setup() {
    auto &root_node = renderer.root_node();

    root_node.push_back_sub_node(_bg_node.square_node().node());
    root_node.push_back_sub_node(_cursor_over_node.node());
    root_node.push_back_sub_node(_button_node.square_node().node());
    root_node.push_back_sub_node(_cursor_node.node());
    root_node.push_back_sub_node(_touch_holder.node());
    root_node.push_back_sub_node(_text_node.strings_node().square_node().node());
    root_node.push_back_sub_node(_modifier_node.strings_node().square_node().node());
    root_node.push_back_sub_node(_button_status_node.strings_node().square_node().node());

    _text_node.strings_node().set_font_atlas(_font_atlas);
    _modifier_node.strings_node().set_font_atlas(_font_atlas);
    _button_status_node.strings_node().set_font_atlas(_font_atlas);

    _button_observer = _button_node.subject().make_wild_card_observer([weak_status_node = to_weak(_button_status_node)](
        auto const &context) {
        if (auto status_node = weak_status_node.lock()) {
            status_node.set_status(context.key);
        }
    });

    auto update_texture = [weak_font_atlas = to_weak(_font_atlas)](ui::renderer_base const &renderer) mutable {
        if (auto font_atlas = weak_font_atlas.lock()) {
            if (renderer.scale_factor() > 0) {
                auto const scale_factor = renderer.scale_factor();

                auto texture_result = ui::make_texture(renderer.device(), {1024, 1024}, scale_factor);
                assert(texture_result);

                font_atlas.set_texture(std::move(texture_result.value()));
            } else {
                font_atlas.set_texture(nullptr);
            }
        }
    };

    _scale_observer = renderer.subject().make_observer(
        ui::renderer_method::scale_factor_changed,
        [update_texture](auto const &context) mutable { update_texture(context.value); });

    update_texture(renderer);
}
