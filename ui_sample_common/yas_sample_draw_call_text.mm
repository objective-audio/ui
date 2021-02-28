//
//  yas_sample_draw_call_text.mm
//

#include "yas_sample_draw_call_text.h"

using namespace yas;

sample::draw_call_text::draw_call_text(ui::font_atlas_ptr const &font_atlas)
    : _strings(ui::strings::make_shared(
          {.text = "---", .alignment = ui::layout_alignment::max, .font_atlas = font_atlas, .max_word_count = 32})) {
    this->_strings->rect_plane()
        ->node()
        ->observe_renderer(
            [this, layouts_pool = observing::canceller_pool_ptr{nullptr},
             strings_observer = observing::canceller_ptr{nullptr}](ui::renderer_ptr const &renderer) mutable {
                if (renderer) {
                    auto const &strings = this->strings();
                    auto &strings_guide_rect = strings->frame_layout_guide_rect();
                    auto const &safe_area_guide_rect = renderer->safe_area_layout_guide_rect();

                    auto pool = observing::canceller_pool::make_shared();

                    safe_area_guide_rect->left()
                        ->observe(
                            [weak_rect = to_weak(strings_guide_rect)](float const &value) {
                                if (auto const rect = weak_rect.lock()) {
                                    rect->right()->set_value(value + 4.0f);
                                }
                            },
                            true)
                        ->add_to(*pool);

                    safe_area_guide_rect->right()
                        ->observe(
                            [weak_rect = to_weak(strings_guide_rect)](float const &value) {
                                if (auto const rect = weak_rect.lock()) {
                                    rect->right()->set_value(value - 4.0f);
                                }
                            },
                            true)
                        ->add_to(*pool);

                    safe_area_guide_rect->bottom()
                        ->observe(
                            [weak_rect = to_weak(strings_guide_rect)](float const &value) {
                                if (auto const rect = weak_rect.lock()) {
                                    rect->bottom()->set_value(value + 4.0f);
                                }
                            },
                            true)
                        ->add_to(*pool);

                    layouts_pool = pool;

                    auto strings_handler =
                        [top_layout = observing::cancellable_ptr{nullptr}](ui::strings_ptr const &strings) mutable {
                            float distance = 0.0f;

                            if (strings->font_atlas()) {
                                auto const &font_atlas = strings->font_atlas();
                                distance += font_atlas->ascent() + font_atlas->descent();
                            }

                            strings->frame_layout_guide_rect()
                                ->bottom()
                                ->observe(
                                    [weak_strings = to_weak(strings), distance](float const &value) {
                                        if (auto const strings = weak_strings.lock()) {
                                            strings->frame_layout_guide_rect()->top()->set_value(value + distance);
                                        }
                                    },
                                    true)
                                ->set_to(top_layout);
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
                    layouts_pool = nullptr;
                    strings_observer = nullptr;
                }
            },
            false)
        ->set_to(this->_renderer_canceller);

    this->_timer = timer{1.0, true, [this] { this->_update_text(); }};
}

ui::strings_ptr const &sample::draw_call_text::strings() {
    return this->_strings;
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
    return std::shared_ptr<draw_call_text>(new draw_call_text{atlas});
}
