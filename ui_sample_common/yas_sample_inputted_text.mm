//
//  yas_sample_inputted_text.mm
//

#include "yas_sample_inputted_text.h"

using namespace yas;
using namespace yas::ui;

sample::inputted_text::inputted_text(std::shared_ptr<font_atlas> const &font_atlas)
    : _strings(
          strings::make_shared({.font_atlas = font_atlas, .max_word_count = 512, .alignment = layout_alignment::min})) {
    this->_strings->rect_plane()
        ->node()
        ->observe_renderer(
            [this, pool = observing::canceller_pool::make_shared()](std::shared_ptr<renderer> const &renderer) {
                pool->cancel();

                if (renderer) {
                    renderer->event_manager()
                        ->observe([this](std::shared_ptr<event> const &event) {
                            if (event->type() == event_type::key) {
                                this->_update_text(event);
                            }
                        })
                        .end()
                        ->add_to(*pool);

                    renderer->safe_area_layout_guide_rect()
                        ->observe([this](region const &region) {
                            this->_strings->frame_layout_guide_rect()->set_region(region +
                                                                                  insets{4.0f, -4.0f, 4.0f, -4.0f});
                        })
                        .sync()
                        ->add_to(*pool);
                }
            })
        .end()
        ->set_to(this->_renderer_canceller);
}

void sample::inputted_text::append_text(std::string text) {
    this->_strings->set_text(this->_strings->text() + text);
}

std::shared_ptr<strings> const &sample::inputted_text::strings() {
    return this->_strings;
}

void sample::inputted_text::_update_text(std::shared_ptr<event> const &event) {
    if (event->phase() == event_phase::began || event->phase() == event_phase::changed) {
        auto const key_code = event->get<key>().key_code();

        switch (key_code) {
            case 51: {  // delete key
                auto &text = this->_strings->text();
                if (text.size() > 0) {
                    this->_strings->set_text(text.substr(0, text.size() - 1));
                }
            } break;

            default: {
                append_text(event->get<key>().characters());
            } break;
        }
    }
}

sample::inputted_text_ptr sample::inputted_text::make_shared(std::shared_ptr<font_atlas> const &atlas) {
    return std::shared_ptr<inputted_text>(new inputted_text{atlas});
}
