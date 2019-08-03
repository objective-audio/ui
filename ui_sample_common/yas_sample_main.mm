//
//  yas_sample_main.mm
//

#include "yas_sample_main.h"

using namespace yas;

void sample::main::setup() {
    auto &root_node = this->renderer.root_node();

    root_node.add_sub_node(this->_bg.rect_plane().node());

    ui::node batch_node;
    batch_node.batch().set_value(ui::batch{});
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

    this->_big_button.button().rect_plane().node().add_sub_node(this->_big_button_text.strings().rect_plane().node());

    auto const big_button_region = this->_big_button.button().layout_guide_rect().region();
    this->_big_button_text.strings().frame_layout_guide_rect().set_region(
        {.origin = {.x = big_button_region.left()}, .size = {.width = big_button_region.size.width}});

    this->_button_observer = this->_big_button.button()
                                 .chain()
                                 .perform([weak_text = to_weak(this->_big_button_text)](auto const &pair) {
                                     if (auto text = weak_text.lock()) {
                                         text.set_status(pair.first);
                                     }
                                 })
                                 .end();

    this->_keyboard_observer = this->_soft_keyboard.chain()
                                   .perform([weak_text = to_weak(this->_inputted_text)](std::string const &key) {
                                       if (auto text = weak_text.lock()) {
                                           text.append_text(key);
                                       }
                                   })
                                   .end();

    auto button_pos_action = ui::make_action({.target = this->_big_button.button().rect_plane().node(),
                                              .begin_position = {0.0f, 0.0f},
                                              .end_position = {32.0f, 0.0f},
                                              .continuous_action = {.duration = 5.0, .loop_count = 0}});
    button_pos_action->set_value_transformer([](float const value) { return sinf(M_PI * 2.0f * value); });
    this->renderer.insert_action(std::move(button_pos_action));

    ui::texture texture{{.point_size = {1024, 1024}}};
    texture.sync_scale_from_renderer(this->renderer);

    this->_font_atlas.set_texture(texture);
    this->_big_button.set_texture(texture);
    this->_touch_holder.set_texture(texture);

    ui::render_target render_target;
    render_target.sync_scale_from_renderer(this->renderer);
    render_target.set_effect(this->_blur->effect());

    auto blur_action = ui::continuous_action::make_shared({.duration = 5.0, .loop_count = 0});
    blur_action->set_value_updater([weak_blur = to_weak(this->_blur)](double const value) {
        if (auto blur = weak_blur.lock()) {
            blur->set_sigma(value * 20.0);
        }
    });
    blur_action->set_value_transformer(ui::ping_pong_transformer());
    this->renderer.insert_action(std::move(blur_action));

    auto &view_guide = this->renderer.view_layout_guide_rect();
    auto &target_guide = render_target.layout_guide_rect();
    this->_render_target_layout = view_guide.chain().send_to(target_guide).sync();

    this->_render_target_node.render_target().set_value(render_target);
    root_node.add_sub_node(this->_render_target_node, 1);

    this->_plane_on_target.data().set_rect_position(
        {.origin = {.x = -100.0f, .y = -100.0f}, .size = {.width = 50.0f, .height = 50.0f}}, 0);
    this->_plane_on_target.node().color().set_value(ui::cyan_color());
    this->_render_target_node.add_sub_node(this->_plane_on_target.node());

    auto action = ui::make_action({.target = this->_plane_on_target.node(),
                                   .begin_angle = 0.0f,
                                   .end_angle = 360.0f,
                                   .continuous_action = {.duration = 3.0, .loop_count = 0}});
    this->renderer.insert_action(action);
}
