//
//  yas_sample_main.mm
//

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

    auto update_texture = [
        weak_font_atlas = to_weak(_font_atlas),
        weak_button_node = to_weak(_button_node),
        weak_touch_holder = to_weak(_touch_holder)
    ](ui::renderer_base const &renderer) {
        auto const scale_factor = renderer.scale_factor();

        ui::texture texture = nullptr;
        if (scale_factor > 0) {
            if (auto texture_result = ui::make_texture(renderer.device(), {1024, 1024}, scale_factor)) {
                texture = std::move(texture_result.value());
            }
        }

        if (auto font_atlas = weak_font_atlas.lock()) {
            font_atlas.set_texture(texture);
        }

        if (auto button_node = weak_button_node.lock()) {
            button_node.set_texture(texture);
        }

        if (auto touch_holder = weak_touch_holder.lock()) {
            touch_holder.set_texture(texture);
        }
    };

    _scale_observer = renderer.subject().make_observer(
        ui::renderer_method::scale_factor_changed,
        [update_texture](auto const &context) mutable { update_texture(context.value); });

    update_texture(renderer);
}
