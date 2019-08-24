//
//  yas_sample_inputted_text.mm
//

#include "yas_sample_inputted_text.h"
#include <chaining/yas_chaining_utils.h>

using namespace yas;

struct sample::inputted_text::impl {
    ui::strings_ptr _strings;

    impl(ui::font_atlas_ptr const &font_atlas)
        : _strings(ui::strings::make_shared(
              {.font_atlas = font_atlas, .max_word_count = 512, .alignment = ui::layout_alignment::min})) {
    }

    void prepare(sample::inputted_text_ptr const &text) {
        auto &node = this->_strings->rect_plane()->node();

        this->_renderer_observer =
            node->chain_renderer()
                .perform([weak_text = to_weak(text), event_observer = chaining::any_observer_ptr{nullptr},
                          layout = chaining::any_observer_ptr{nullptr}](ui::renderer_ptr const &renderer) mutable {
                    if (auto text = weak_text.lock()) {
                        if (renderer) {
                            auto &text_impl = text->_impl;
                            auto &strings_frame_guide_rect = text_impl->_strings->frame_layout_guide_rect();

                            event_observer = renderer->event_manager()
                                                 ->chain(ui::event_manager::method::key_changed)
                                                 .perform([weak_text](ui::event_ptr const &event) {
                                                     if (auto text = weak_text.lock()) {
                                                         text->_impl->update_text(event);
                                                     }
                                                 })
                                                 .end();

                            layout = renderer->safe_area_layout_guide_rect()
                                         ->chain()
                                         .to(chaining::add<ui::region>(ui::insets{4.0f, -4.0f, 4.0f, -4.0f}))
                                         .send_to(strings_frame_guide_rect)
                                         .sync();
                        } else {
                            event_observer = nullptr;
                            layout = nullptr;
                        }
                    }
                })
                .end();
    }

    void update_text(ui::event_ptr const &event) {
        if (event->phase() == ui::event_phase::began || event->phase() == ui::event_phase::changed) {
            auto const key_code = event->get<ui::key>().key_code();

            switch (key_code) {
                case 51: {  // delete key
                    auto &text = this->_strings->text();
                    if (text.size() > 0) {
                        this->_strings->set_text(text.substr(0, text.size() - 1));
                    }
                } break;

                default: { append_text(event->get<ui::key>().characters()); } break;
            }
        }
    }

    void append_text(std::string text) {
        this->_strings->set_text(this->_strings->text() + text);
    }

   private:
    chaining::any_observer_ptr _renderer_observer = nullptr;
    ui::layout_guide_point_ptr _layout_guide_point = ui::layout_guide_point::make_shared();
};

sample::inputted_text::inputted_text(ui::font_atlas_ptr const &font_atlas) : _impl(std::make_unique<impl>(font_atlas)) {
}

void sample::inputted_text::append_text(std::string text) {
    this->_impl->append_text(std::move(text));
}

ui::strings_ptr const &sample::inputted_text::strings() {
    return this->_impl->_strings;
}

void sample::inputted_text::_prepare(inputted_text_ptr const &shared) {
    this->_impl->prepare(shared);
}

sample::inputted_text_ptr sample::inputted_text::make_shared(ui::font_atlas_ptr const &atlas) {
    auto shared = std::shared_ptr<inputted_text>(new inputted_text{atlas});
    shared->_prepare(shared);
    return shared;
}
