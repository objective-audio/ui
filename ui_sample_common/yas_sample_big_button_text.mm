//
//  yas_big_button_text.mm
//

#include "yas_sample_big_button_text.h"

using namespace yas;
using namespace yas::ui;

sample::big_button_text::big_button_text(std::shared_ptr<font_atlas> const &font_atlas)
    : _strings(strings::make_shared(
          {.text = "-----", .alignment = layout_alignment::mid, .font_atlas = font_atlas, .max_word_count = 32})) {
    this->_strings->rect_plane()->node()->set_alpha(0.5f);

    float const offset_y = (font_atlas->ascent() + font_atlas->descent()) * 0.5f;
    this->_strings->rect_plane()->node()->set_position(point{0.0f, offset_y});
}

void sample::big_button_text::set_status(button::method const status) {
    this->_strings->set_text(to_string(status));
}

std::shared_ptr<strings> const &sample::big_button_text::strings() {
    return this->_strings;
}

sample::big_button_text_ptr sample::big_button_text::make_shared(std::shared_ptr<font_atlas> const &atlas) {
    return std::shared_ptr<big_button_text>(new big_button_text{atlas});
}
