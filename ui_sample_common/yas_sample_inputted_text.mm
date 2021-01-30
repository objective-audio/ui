//
//  yas_sample_inputted_text.mm
//

#include "yas_sample_inputted_text.h"
#include <chaining/yas_chaining_utils.h>

using namespace yas;

sample::inputted_text::inputted_text(ui::font_atlas_ptr const &font_atlas)
    : _strings(ui::strings::make_shared(
          {.font_atlas = font_atlas, .max_word_count = 512, .alignment = ui::layout_alignment::min})) {
    this->_strings->rect_plane()
        ->node()
        ->observe_renderer(
            [this, pool = observing::canceller_pool::make_shared()](ui::renderer_ptr const &renderer) {
                pool->invalidate();

                if (renderer) {
                    renderer->event_manager()
                        ->observe([this](auto const &context) {
                            if (context.method == ui::event_manager::method::key_changed) {
                                ui::event_ptr const &event = context.event;
                                this->_update_text(event);
                            }
                        })
                        ->add_to(*pool);

                    renderer->safe_area_layout_guide_rect()
                        ->observe(
                            [this](ui::region const &region) {
                                this->_strings->frame_layout_guide_rect()->set_region(
                                    region + ui::insets{4.0f, -4.0f, 4.0f, -4.0f});
                            },
                            true)
                        ->add_to(*pool);
                }
            },
            false)
        ->set_to(this->_renderer_canceller);
}

void sample::inputted_text::append_text(std::string text) {
    this->_strings->set_text(this->_strings->text() + text);
}

ui::strings_ptr const &sample::inputted_text::strings() {
    return this->_strings;
}

void sample::inputted_text::_update_text(ui::event_ptr const &event) {
    if (event->phase() == ui::event_phase::began || event->phase() == ui::event_phase::changed) {
        auto const key_code = event->get<ui::key>().key_code();

        switch (key_code) {
            case 51: {  // delete key
                auto &text = this->_strings->text();
                if (text.size() > 0) {
                    this->_strings->set_text(text.substr(0, text.size() - 1));
                }
            } break;

            default: {
                append_text(event->get<ui::key>().characters());
            } break;
        }
    }
}

sample::inputted_text_ptr sample::inputted_text::make_shared(ui::font_atlas_ptr const &atlas) {
    return std::shared_ptr<inputted_text>(new inputted_text{atlas});
}
