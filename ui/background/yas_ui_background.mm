//
//  yas_ui_background.mm
//

#include "yas_ui_background.h"

using namespace yas;
using namespace yas::ui;

background::background()
    : _rgb_color(observing::value::holder<ui::rgb_color>::make_shared({.v = 1.0f})),
      _alpha(observing::value::holder<float>::make_shared(1.0f)) {
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

observing::syncable background::observe_rgb_color(observing::caller<ui::rgb_color>::handler_f &&handler) {
    return this->_rgb_color->observe(std::move(handler));
}

void background::set_alpha(float const &alpha) {
    this->_alpha->set_value(alpha);
}

float const &background::alpha() const {
    return this->_alpha->value();
}

observing::syncable background::observe_alpha(observing::caller<float>::handler_f &&handler) {
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

std::shared_ptr<background> background::make_shared() {
    return std::shared_ptr<background>(new background{});
}
