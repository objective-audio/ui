//
//  yas_sample_main.mm
//

#include "yas_sample_main.h"

using namespace yas;
using namespace yas::ui;

sample::main::main(std::shared_ptr<ui::view_look> const &view_look,
                   std::shared_ptr<ui::metal_system> const &metal_system)
    : standard(ui::standard::make_shared(view_look, metal_system)) {
}

void sample::main::setup() {
    auto const &root_node = this->standard->root_node();

    root_node->add_sub_node(this->_bg->rect_plane()->node());

    auto batch_node = node::make_shared();
    batch_node->set_batch(batch::make_shared());
    batch_node->add_sub_node(this->_cursor_over_planes->node());
    root_node->add_sub_node(std::move(batch_node));

    root_node->add_sub_node(this->_soft_keyboard->node());
    root_node->add_sub_node(this->_big_button->button()->rect_plane()->node());
    root_node->add_sub_node(this->_cursor->node());
    root_node->add_sub_node(this->_touch_holder->node());
    root_node->add_sub_node(this->_inputted_text->strings()->rect_plane()->node());
    root_node->add_sub_node(this->_modifier_text->strings()->rect_plane()->node());
    root_node->add_sub_node(this->_justified_points->rect_plane()->node());
    root_node->add_sub_node(this->_draw_call_text->strings()->rect_plane()->node());

    this->_big_button->button()->rect_plane()->node()->add_sub_node(
        this->_big_button_text->strings()->rect_plane()->node());

    auto const big_button_region = this->_big_button->button()->layout_guide()->region();
    this->_big_button_text->strings()->preferred_layout_guide()->set_region(
        {.origin = {.x = big_button_region.left()}, .size = {.width = big_button_region.size.width}});

    this->_big_button->button()
        ->observe([weak_text = to_weak(this->_big_button_text)](auto const &context) {
            if (auto text = weak_text.lock()) {
                text->set_status(context.method);
            }
        })
        .end()
        ->add_to(this->_pool);

    this->_soft_keyboard
        ->observe([weak_text = to_weak(this->_inputted_text)](std::string const &key) {
            if (auto text = weak_text.lock()) {
                text->append_text(key);
            }
        })
        .end()
        ->add_to(this->_pool);

    auto button_pos_action =
        make_action({.target = this->_big_button->button()->rect_plane()->node(),
                     .begin_position = {0.0f, 0.0f},
                     .end_position = {32.0f, 0.0f},
                     .duration = 5.0,
                     .loop_count = 0,
                     .value_transformer = [](float const value) { return sinf(M_PI * 2.0f * value); }});

    this->standard->action_manager()->insert_action(button_pos_action);

    this->_big_button->set_texture(this->_texture);
    this->_touch_holder->set_texture(this->_texture);

    auto render_target = render_target::make_shared(this->standard->view_look());
    render_target->set_effect(this->_blur->effect());

    auto blur_action =
        action::make_continuous({.duration = 5.0,
                                 .loop_count = 0,
                                 .value_transformer = ping_pong_transformer(),
                                 .value_updater = [weak_blur = to_weak(this->_blur)](double const value) {
                                     if (auto blur = weak_blur.lock()) {
                                         blur->set_sigma(value * 20.0);
                                     }
                                 }});

    this->standard->action_manager()->insert_action(blur_action);

    auto &view_guide = this->standard->view_look()->view_layout_guide();

    view_guide->observe([render_target](region const &region) { render_target->layout_guide()->set_region(region); })
        .sync()
        ->add_to(this->_pool);

    this->_render_target_node->set_render_target(render_target);

    root_node->add_sub_node(this->_render_target_node, 1);

    this->_plane_on_target->data()->set_rect_position(
        {.origin = {.x = -100.0f, .y = -100.0f}, .size = {.width = 50.0f, .height = 50.0f}}, 0);
    this->_plane_on_target->node()->set_color(cyan_color());
    this->_render_target_node->add_sub_node(this->_plane_on_target->node());

    auto action = make_action({.target = this->_plane_on_target->node(),
                               .begin_angle = 0.0f,
                               .end_angle = 360.0f,
                               .duration = 3.0,
                               .loop_count = 0});
    this->standard->action_manager()->insert_action(action);
}

std::shared_ptr<sample::main> sample::main::make_shared(std::shared_ptr<ui::view_look> const &view_look,
                                                        std::shared_ptr<ui::metal_system> const &metal_system) {
    return std::shared_ptr<main>(new main{view_look, metal_system});
}
