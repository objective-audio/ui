//
//  yas_ui_background.mm
//

#include "yas_ui_background.h"
#include "yas_ui_color.h"

using namespace yas;

ui::background::background()
    : _color(observing::value::holder<ui::color>::make_shared({.v = 1.0f})),
      _alpha(observing::value::holder<float>::make_shared(1.0f)) {
    this->_updates.flags.set();

    this->_color->observe([this](auto const &) { this->_updates.set(ui::background_update_reason::color); }, true)
        ->add_to(this->_pool);

    this->_alpha->observe([this](auto const &) { this->_updates.set(ui::background_update_reason::alpha); }, true)
        ->add_to(this->_pool);
}

ui::background::~background() = default;

void ui::background::set_color(ui::color const &color) {
    this->_color->set_value(color);
}

void ui::background::set_color(ui::color &&color) {
    this->_color->set_value(std::move(color));
}

ui::color const &ui::background::color() const {
    return this->_color->value();
}

observing::canceller_ptr ui::background::observe_color(observing::caller<ui::color>::handler_f &&handler,
                                                       bool const sync) {
    return this->_color->observe(std::move(handler), sync);
}

observing::value::holder_ptr<float> const &ui::background::alpha() const {
    return this->_alpha;
}

std::shared_ptr<ui::background> ui::background::make_shared() {
    return std::shared_ptr<background>(new background{});
}

ui::background_updates_t const &ui::background::updates() const {
    return this->_updates;
}

void ui::background::clear_updates() {
    this->_updates.flags.reset();
}
