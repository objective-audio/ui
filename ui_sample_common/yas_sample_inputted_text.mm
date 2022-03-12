//
//  yas_sample_inputted_text.mm
//

#include "yas_sample_inputted_text.h"

using namespace yas;
using namespace yas::ui;

sample::inputted_text::inputted_text(std::shared_ptr<font_atlas> const &font_atlas,
                                     std::shared_ptr<ui::event_manager> const &event_manager,
                                     std::shared_ptr<ui::layout_region_source> const &safe_area_guide)
    : _strings(strings::make_shared(
          {.attributes = {{.color = {.v = 1.0f}},
                          {.range = index_range{.index = 1, .length = 2}, .color = to_color(ui::blue_color(), 1.0f)}},
           .max_word_count = 512,
           .alignment = layout_alignment::min},
          font_atlas)) {
    this->_strings->rect_plane()->node()->mesh()->set_use_mesh_color(true);

    event_manager
        ->observe([this](std::shared_ptr<event> const &event) {
            if (event->type() == event_type::key) {
                this->_update_text(event);
            }
        })
        .end()
        ->add_to(this->_pool);

    safe_area_guide
        ->observe_layout_region([this](region const &region) {
            this->_strings->preferred_layout_guide()->set_region(region + region_insets{4.0f, -4.0f, 4.0f, -4.0f});
        })
        .sync()
        ->add_to(this->_pool);
}

void sample::inputted_text::append_text(std::string text) {
    this->_strings->set_text(this->_strings->text() + text);
}

std::shared_ptr<strings> const &sample::inputted_text::strings() {
    return this->_strings;
}

void sample::inputted_text::_update_text(std::shared_ptr<event> const &event) {
    if (event->phase() == event_phase::began || event->phase() == event_phase::changed) {
        auto const key_code = event->get<key>().key_code;

        switch (key_code) {
            case 51: {  // delete key
                auto &text = this->_strings->text();
                if (text.size() > 0) {
                    this->_strings->set_text(text.substr(0, text.size() - 1));
                }
            } break;

            default: {
                append_text(event->get<key>().characters);
            } break;
        }
    }
}

sample::inputted_text_ptr sample::inputted_text::make_shared(
    std::shared_ptr<font_atlas> const &atlas, std::shared_ptr<ui::event_manager> const &event_manager,
    std::shared_ptr<ui::layout_region_source> const &safe_area_guide) {
    return std::shared_ptr<inputted_text>(new inputted_text{atlas, event_manager, safe_area_guide});
}
