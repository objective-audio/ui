//
//  yas_sample_main.mm
//

#include "yas_sample_main.h"

using namespace yas;

void sample::main::setup() {
    auto &root_node = this->renderer.root_node();

    root_node.add_sub_node(this->_bg.rect_plane().node());

    ui::node batch_node;
    batch_node.set_batch(ui::batch{});
    batch_node.add_sub_node(this->_cursor_over_planes.node());
    root_node.add_sub_node(std::move(batch_node));

    root_node.add_sub_node(this->_soft_keyboard.node());
    root_node.add_sub_node(this->_big_button.button().rect_plane().node());
    root_node.add_sub_node(this->_cursor.node());
    root_node.add_sub_node(this->_touch_holder.node());
    root_node.add_sub_node(this->_inputted_text.strings().rect_plane().node());
    root_node.add_sub_node(this->_modifier_text.strings().rect_plane().node());
    root_node.add_sub_node(this->_justified_points.rect_plane().node());
    root_node.add_sub_node(this->_draw_call_text.strings().rect_plane().node());

    this->_big_button.button().rect_plane().node().add_sub_node(_big_button_text.strings().rect_plane().node());

    auto const big_button_region = this->_big_button.button().layout_guide_rect().region();
    this->_big_button_text.strings().frame_layout_guide_rect().set_region(
        {.origin = {.x = big_button_region.left()}, .size = {.width = big_button_region.size.width}});

    this->_button_observer =
        this->_big_button.button().subject().make_wild_card_observer([weak_text = to_weak(_big_button_text)](
            auto const &context) {
            if (auto text = weak_text.lock()) {
                text.set_status(context.key);
            }
        });

    this->_keyboard_observer =
        this->_soft_keyboard.subject().make_wild_card_observer([weak_text =
                                                                    to_weak(_inputted_text)](auto const &context) {
            if (auto text = weak_text.lock()) {
                text.append_text(context.key);
            }
        });

    auto button_pos_action =
        ui::make_action(ui::translate_action::args{.target = this->_big_button.button().rect_plane().node(),
                                                   .begin_position = {0.0f, 0.0f},
                                                   .end_position = {32.0f, 0.0f},
                                                   .continuous_action = {.duration = 5.0, .loop_count = 0}});
    button_pos_action.set_value_transformer([](float const value) { return sinf(M_PI * 2.0f * value); });
    this->renderer.insert_action(std::move(button_pos_action));

    auto update_texture_handler = [
        weak_font_atlas = to_weak(_font_atlas), weak_big_button = to_weak(_big_button),
        weak_touch_holder = to_weak(_touch_holder)
    ](ui::renderer const &renderer) {
        auto const scale_factor = renderer.scale_factor();

        ui::texture texture = nullptr;
        if (scale_factor > 0) {
            texture = ui::texture{{.point_size = {1024, 1024}, .scale_factor = scale_factor}};
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

    this->_scale_observer = this->renderer.subject().make_observer(
        ui::renderer::method::scale_factor_changed,
        [update_texture_handler](auto const &context) mutable { update_texture_handler(context.value); });

    update_texture_handler(this->renderer);

    ui::render_target render_target;
    render_target.set_scale_factor(this->renderer.scale_factor());
    render_target.set_effect(this->_blur.effect());

    ui::continuous_action blur_action{{.duration = 5.0, .loop_count = 0}};
    blur_action.set_value_updater([weak_blur = to_weak(this->_blur)](double const value){
        if (auto blur = weak_blur.lock()) {
            blur.set_sigma(value * 20.0);
        }
    });
    blur_action.set_value_transformer(ui::ping_pong_transformer());
    this->renderer.insert_action(std::move(blur_action));

    auto &safe_area_guide = this->renderer.safe_area_layout_guide_rect();
    auto &target_guide = render_target.layout_guide_rect();
    this->_render_target_layouts.emplace_back(ui::make_layout(
        ui::fixed_layout::args{.source_guide = safe_area_guide.left(), .destination_guide = target_guide.left()}));
    this->_render_target_layouts.emplace_back(ui::make_layout(
        ui::fixed_layout::args{.source_guide = safe_area_guide.right(), .destination_guide = target_guide.right()}));
    this->_render_target_layouts.emplace_back(ui::make_layout(
        ui::fixed_layout::args{.source_guide = safe_area_guide.top(), .destination_guide = target_guide.top()}));
    this->_render_target_layouts.emplace_back(ui::make_layout(
        ui::fixed_layout::args{.source_guide = safe_area_guide.bottom(), .destination_guide = target_guide.bottom()}));

    this->_render_target_node.set_render_target(render_target);
    root_node.add_sub_node(this->_render_target_node, 1);

    this->_plane_on_target.data().set_rect_position(
        {.origin = {.x = -100.0f, .y = -100.0f}, .size = {.width = 50.0f, .height = 50.0f}}, 0);
    this->_plane_on_target.node().set_color(ui::cyan_color());
    this->_render_target_node.add_sub_node(this->_plane_on_target.node());

    auto action = ui::make_action({.target = this->_plane_on_target.node(),
                                   .begin_angle = 0.0f,
                                   .end_angle = 360.0f,
                                   .continuous_action = {.duration = 3.0, .loop_count = 0}});
    this->renderer.insert_action(action);
}
