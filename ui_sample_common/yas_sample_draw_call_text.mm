//
//  yas_sample_draw_call_text.mm
//

#include "yas_sample_draw_call_text.h"
#include <chaining/yas_chaining_utils.h>

using namespace yas;

sample::draw_call_text::draw_call_text(ui::font_atlas_ptr const &font_atlas)
    : _strings(ui::strings::make_shared(
          {.text = "---", .alignment = ui::layout_alignment::max, .font_atlas = font_atlas, .max_word_count = 32})) {
}

ui::strings_ptr const &sample::draw_call_text::strings() {
    return this->_strings;
}

void sample::draw_call_text::_prepare(draw_call_text_ptr const &text) {
    auto &node = this->_strings->rect_plane()->node();

    this->_renderer_canceller = node->observe_renderer(
        [weak_text = to_weak(text), left_layout = chaining::any_observer_ptr{nullptr},
         right_layout = chaining::any_observer_ptr{nullptr}, bottom_layout = chaining::any_observer_ptr{nullptr},
         strings_observer = observing::canceller_ptr{nullptr}](ui::renderer_ptr const &renderer) mutable {
            if (auto text = weak_text.lock()) {
                if (renderer) {
                    auto const &strings = text->strings();
                    auto &strings_guide_rect = strings->frame_layout_guide_rect();
                    auto const &safe_area_guide_rect = renderer->safe_area_layout_guide_rect();
                    left_layout = safe_area_guide_rect->left()
                                      ->chain()
                                      .to(chaining::add(4.0f))
                                      .send_to(strings_guide_rect->right())
                                      .sync();

                    right_layout = safe_area_guide_rect->right()
                                       ->chain()
                                       .to(chaining::add(-4.0f))
                                       .send_to(strings_guide_rect->right())
                                       .sync();

                    bottom_layout = safe_area_guide_rect->bottom()
                                        ->chain()
                                        .to(chaining::add(4.0f))
                                        .send_to(strings_guide_rect->bottom())
                                        .sync();

                    auto strings_handler =
                        [top_layout = chaining::any_observer_ptr{nullptr}](ui::strings_ptr const &strings) mutable {
                            float distance = 0.0f;

                            if (strings->font_atlas()) {
                                auto const &font_atlas = strings->font_atlas();
                                distance += font_atlas->ascent() + font_atlas->descent();
                            }

                            top_layout = strings->frame_layout_guide_rect()
                                             ->bottom()
                                             ->chain()
                                             .to(chaining::add(distance))
                                             .send_to(strings->frame_layout_guide_rect()->top())
                                             .sync();
                        };

                    strings_handler(strings);

                    strings_observer = strings->observe_font_atlas(
                        [strings_handler = std::move(strings_handler),
                         weak_strings = to_weak(strings)](ui::font_atlas_ptr const &) mutable {
                            if (auto strings = weak_strings.lock()) {
                                strings_handler(strings);
                            }
                        },
                        false);
                } else {
                    left_layout = nullptr;
                    right_layout = nullptr;
                    bottom_layout = nullptr;
                    strings_observer = nullptr;
                }
            }
        },
        false);

    auto timer_handler = [weak_text = to_weak(text)]() {
        if (auto text = weak_text.lock()) {
            text->_update_text();
        }
    };

    this->_timer = timer{1.0, true, std::move(timer_handler)};
}

void sample::draw_call_text::_update_text() {
    std::string text = "---";

    if (auto renderer = this->_strings->rect_plane()->node()->renderer()) {
        if (auto metal_system = renderer->metal_system()) {
            std::size_t const count = metal_system->last_encoded_mesh_count();
            text = "drawcall:" + std::to_string(count);
        }
    }

    this->_strings->set_text(text);
}

sample::draw_call_text_ptr sample::draw_call_text::make_shared(ui::font_atlas_ptr const &atlas) {
    auto shared = std::shared_ptr<draw_call_text>(new draw_call_text{atlas});
    shared->_prepare(shared);
    return shared;
}
