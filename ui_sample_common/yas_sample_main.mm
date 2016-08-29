//
//  yas_sample_main.mm
//

#include "yas_sample_main.h"

using namespace yas;

void sample::main::setup() {
    auto &root_node = renderer.root_node();

    root_node.push_back_sub_node(_bg.rect_plane().node());
    root_node.push_back_sub_node(_collection_ext.rect_plane_ext().node());

    ui::node batch_node;
    batch_node.set_batch(ui::batch{});
    batch_node.push_back_sub_node(_cursor_over_planes_ext.node());
    root_node.push_back_sub_node(std::move(batch_node));

    root_node.push_back_sub_node(_soft_keyboard_ext.node());
    root_node.push_back_sub_node(_big_button.button().rect_plane().node());
    root_node.push_back_sub_node(_cursor.node());
    root_node.push_back_sub_node(_touch_holder.node());
    root_node.push_back_sub_node(_inputted_text.strings().rect_plane().node());
    root_node.push_back_sub_node(_modifier_text.strings().rect_plane().node());
    root_node.push_back_sub_node(_justified_points_ext.rect_plane_ext().node());

    _big_button.button().rect_plane().node().push_back_sub_node(_big_button_text_ext.strings().rect_plane().node());

    _inputted_text.strings().set_font_atlas(_font_atlas);
    _modifier_text.strings().set_font_atlas(_font_atlas);
    _big_button_text_ext.strings().set_font_atlas(_font_atlas);
    _soft_keyboard_ext.set_font_atlas(_font_atlas);

    _button_observer =
        _big_button.button().subject().make_wild_card_observer([weak_ext = to_weak(_big_button_text_ext)](
            auto const &context) {
            if (auto ext = weak_ext.lock()) {
                ext.set_status(context.key);
            }
        });

    _keyboard_observer = _soft_keyboard_ext.subject().make_wild_card_observer([weak_ext = to_weak(_inputted_text)](
        auto const &context) {
        if (auto ext = weak_ext.lock()) {
            ext.append_text(context.key);
        }
    });

    auto button_pos_action =
        ui::make_action(ui::translate_action::args{.start_position = {0.0f, 0.0f},
                                                   .end_position = {32.0f, 0.0f},
                                                   .continuous_action = {.duration = 5.0, .loop_count = 0}});
    button_pos_action.set_target(_big_button.button().rect_plane().node());
    button_pos_action.set_value_transformer([](float const value) { return sinf(M_PI * 2.0f * value); });
    renderer.insert_action(std::move(button_pos_action));

    auto update_texture = [
        weak_font_atlas = to_weak(_font_atlas),
        weak_big_button = to_weak(_big_button),
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

        if (auto big_button = weak_big_button.lock()) {
            big_button.set_texture(texture);
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
