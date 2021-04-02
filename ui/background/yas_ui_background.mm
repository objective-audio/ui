//
//  yas_ui_background.mm
//

#include "yas_ui_background.h"
#include "yas_ui_color.h"

using namespace yas;
using namespace yas::ui;

background::background()
    : _color(observing::value::holder<ui::color>::make_shared({.v = 1.0f})),
      _alpha(observing::value::holder<float>::make_shared(1.0f)) {
    this->_updates.flags.set();

    this->_color->observe([this](auto const &) { this->_updates.set(background_update_reason::color); })
        .sync()
        ->add_to(this->_pool);

    this->_alpha->observe([this](auto const &) { this->_updates.set(background_update_reason::alpha); })
        .sync()
        ->add_to(this->_pool);
}

background::~background() = default;

void background::set_color(ui::color const &color) {
    this->_color->set_value(color);
}

void background::set_color(ui::color &&color) {
    this->_color->set_value(std::move(color));
}

ui::color const &background::color() const {
    return this->_color->value();
}

observing::syncable background::observe_color(observing::caller<ui::color>::handler_f &&handler) {
    return this->_color->observe(std::move(handler));
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

std::shared_ptr<background> background::make_shared() {
    return std::shared_ptr<background>(new background{});
}

background_updates_t const &background::updates() const {
    return this->_updates;
}

void background::clear_updates() {
    this->_updates.flags.reset();
}
