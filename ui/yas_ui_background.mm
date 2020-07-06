//
//  yas_ui_background.mm
//

#include "yas_ui_background.h"
#include "yas_ui_color.h"

using namespace yas;

ui::background::background()
    : _color(chaining::value::holder<ui::color>::make_shared({.v = 1.0f})),
      _alpha(chaining::value::holder<float>::make_shared(1.0f)) {
    this->_updates.flags.set();

    this->_color->chain()
        .perform([this](auto const &) { this->_updates.set(ui::background_update_reason::color); })
        .end()
        ->add_to(this->_pool);

    this->_alpha->chain()
        .perform([this](auto const &) { this->_updates.set(ui::background_update_reason::alpha); })
        .end()
        ->add_to(this->_pool);
}

ui::background::~background() = default;

chaining::value::holder_ptr<ui::color> const &ui::background::color() const {
    return this->_color;
}

chaining::value::holder_ptr<float> const &ui::background::alpha() const {
    return this->_alpha;
}

std::shared_ptr<ui::background> ui::background::make_shared() {
    return std::shared_ptr<background>(new background{});
}

void ui::background::fetch_updates(ui::background_updates_t &updates) {
    updates.flags |= this->_updates.flags;
}

void ui::background::clear_updates() {
    this->_updates.flags.reset();
}
