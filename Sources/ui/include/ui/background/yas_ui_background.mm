//
//  yas_ui_background.mm
//

#include "yas_ui_background.h"

using namespace yas;
using namespace yas::ui;

std::shared_ptr<background> background::make_shared() {
    return std::shared_ptr<background>(new background{});
}

background::background()
    : _rgb_color(observing::value::holder<ui::rgb_color>::make_shared({.v = 1.0f})),
      _alpha(observing::value::holder<float>::make_shared(1.0f)) {
    this->_rgb_color
        ->observe([this](ui::rgb_color const &) { this->_updates.set(ui::background_update_reason::color); })
        .sync()
        ->add_to(this->_pool);
    this->_alpha->observe([this](float const &) { this->_updates.set(ui::background_update_reason::alpha); })
        .sync()
        ->add_to(this->_pool);
}

void background::set_rgb_color(ui::rgb_color const &color) {
    this->_rgb_color->set_value(color);
}

void background::set_rgb_color(ui::rgb_color &&color) {
    this->_rgb_color->set_value(std::move(color));
}

ui::rgb_color const &background::rgb_color() const {
    return this->_rgb_color->value();
}

observing::syncable background::observe_rgb_color(std::function<void(ui::rgb_color const &)> &&handler) {
    return this->_rgb_color->observe(std::move(handler));
}

void background::set_alpha(float const &alpha) {
    this->_alpha->set_value(alpha);
}

void background::set_alpha(float &&alpha) {
    this->_alpha->set_value(std::move(alpha));
}

float const &background::alpha() const {
    return this->_alpha->value();
}

observing::syncable background::observe_alpha(std::function<void(float const &)> &&handler) {
    return this->_alpha->observe(std::move(handler));
}

void background::set_color(ui::color const &color) {
    this->set_rgb_color(color.rgb);
    this->set_alpha(color.alpha);
}

void background::set_color(ui::color &&color) {
    this->set_rgb_color(std::move(color.rgb));
    this->set_alpha(std::move(color.alpha));
}

ui::color background::color() const {
    auto const &rgb = this->rgb_color();
    return {rgb.red, rgb.green, rgb.blue, this->alpha()};
}

void background::fetch_updates(ui::tree_updates &tree_updates) {
    tree_updates.background_updates.flags |= this->_updates.flags;
}

void background::clear_updates() {
    this->_updates.flags.reset();
}
