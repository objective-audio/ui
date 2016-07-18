//
//  yas_sample_main.mm
//

#include "yas_sample_main.h"

using namespace yas;

void sample::main::setup() {
    auto &root_node = renderer.root_node();

    root_node.push_back_sub_node(_bg.rect_plane().node());

    ui::node batch_node;
    batch_node.set_batch(ui::batch{});
    batch_node.push_back_sub_node(_cursor_over_node.node());
    root_node.push_back_sub_node(std::move(batch_node));

    root_node.push_back_sub_node(_soft_keyboard.node());
    root_node.push_back_sub_node(_button_node.button().rect_plane().node());
    root_node.push_back_sub_node(_cursor_node.node());
    root_node.push_back_sub_node(_touch_holder.node());
    root_node.push_back_sub_node(_text_node.strings().rect_plane().node());
    root_node.push_back_sub_node(_modifier_text.strings().rect_plane().node());

    _button_node.button().rect_plane().node().push_back_sub_node(_button_status_node.strings().rect_plane().node());

    _text_node.strings().set_font_atlas(_font_atlas);
    _modifier_text.strings().set_font_atlas(_font_atlas);
    _button_status_node.strings().set_font_atlas(_font_atlas);
    _soft_keyboard.set_font_atlas(_font_atlas);

    _button_observer =
        _button_node.button().subject().make_wild_card_observer([weak_status_node = to_weak(_button_status_node)](
            auto const &context) {
            if (auto status_node = weak_status_node.lock()) {
                status_node.set_status(context.key);
            }
        });

    _keyboard_observer =
        _soft_keyboard.subject().make_wild_card_observer([weak_text_node = to_weak(_text_node)](auto const &context) {
            if (auto text_node = weak_text_node.lock()) {
                text_node.append_text(context.key);
            }
        });

    auto button_pos_action =
        ui::make_action(ui::translate_action::args{.start_position = {0.0f, 0.0f},
                                                   .end_position = {32.0f, 0.0f},
                                                   .continuous_action = {.duration = 5.0, .loop_count = 0}});
    button_pos_action.set_target(_button_node.button().rect_plane().node());
    button_pos_action.set_value_transformer([](float const value) { return sinf(M_PI * 2.0f * value); });
    renderer.insert_action(std::move(button_pos_action));

    auto update_texture = [
        weak_font_atlas = to_weak(_font_atlas),
        weak_button_node = to_weak(_button_node),
        weak_touch_holder = to_weak(_touch_holder)
    ](ui::renderer const &renderer) {
        auto const scale_factor = renderer.scale_factor();

        ui::texture texture = nullptr;
        if (scale_factor > 0) {
            if (auto texture_result = ui::make_texture({.metal_system = renderer.metal_system(),
                                                        .point_size = {1024, 1024},
                                                        .scale_factor = scale_factor})) {
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
        ui::renderer::method::scale_factor_changed,
        [update_texture](auto const &context) mutable { update_texture(context.value); });

    update_texture(renderer);
}
