//
//  yas_big_button_text.mm
//

#include "yas_sample_big_button_text.h"

using namespace yas;

sample::big_button_text::big_button_text(ui::font_atlas_ptr const &font_atlas)
    : _strings(ui::strings::make_shared(
          {.text = "-----", .alignment = ui::layout_alignment::mid, .font_atlas = font_atlas, .max_word_count = 32})) {
    this->_strings->rect_plane()->node()->alpha()->set_value(0.5f);

    this->strings()
        ->observe_font_atlas([this](ui::font_atlas_ptr const &) { this->_update_strings_position(); }, true)
        ->set_to(this->_strings_canceller);
}

void sample::big_button_text::set_status(ui::button::method const status) {
    this->_strings->set_text(to_string(status));
}

ui::strings_ptr const &sample::big_button_text::strings() {
    return this->_strings;
}

void sample::big_button_text::_update_strings_position() {
    if (auto const &atlas = this->_strings->font_atlas()) {
        float const offset_y = (atlas->ascent() + atlas->descent()) * 0.5f;
        this->_strings->rect_plane()->node()->position()->set_value(ui::point{0.0f, offset_y});
    }
}

sample::big_button_text_ptr sample::big_button_text::make_shared(ui::font_atlas_ptr const &atlas) {
    return std::shared_ptr<big_button_text>(new big_button_text{atlas});
}
