//
//  yas_sample_draw_call_text.mm
//

#include "yas_sample_draw_call_text.h"

using namespace yas;
using namespace yas::ui;

sample::draw_call_text::draw_call_text(std::shared_ptr<font_atlas> const &font_atlas,
                                       std::shared_ptr<ui::metal_system> const &metal_system)
    : _strings(strings::make_shared(
          {.text = "---", .alignment = layout_alignment::max, .font_atlas = font_atlas, .max_word_count = 32})),
      _weak_metal_system(metal_system) {
    this->_strings->rect_plane()
        ->node()
        ->observe_renderer([this, layouts_pool = observing::canceller_pool_ptr{nullptr},
                            strings_observer = observing::cancellable_ptr{nullptr}](
                               std::shared_ptr<renderer> const &renderer) mutable {
            if (renderer) {
                auto const &strings = this->strings();
                auto &strings_preferred_guide = strings->preferred_layout_guide();
                auto const &safe_area_guide = renderer->safe_area_layout_guide();

                auto pool = observing::canceller_pool::make_shared();

                safe_area_guide->left()
                    ->observe([weak_rect = to_weak(strings_preferred_guide)](float const &value) {
                        if (auto const region = weak_rect.lock()) {
                            region->right()->set_value(value + 4.0f);
                        }
                    })
                    .sync()
                    ->add_to(*pool);

                safe_area_guide->right()
                    ->observe([weak_guide = to_weak(strings_preferred_guide)](float const &value) {
                        if (auto const guide = weak_guide.lock()) {
                            guide->right()->set_value(value - 4.0f);
                        }
                    })
                    .sync()
                    ->add_to(*pool);

                safe_area_guide->bottom()
                    ->observe([weak_guide = to_weak(strings_preferred_guide)](float const &value) {
                        if (auto const guide = weak_guide.lock()) {
                            guide->bottom()->set_value(value + 4.0f);
                        }
                    })
                    .sync()
                    ->add_to(*pool);

                layouts_pool = pool;

                auto strings_handler = [top_layout = observing::cancellable_ptr{nullptr}](
                                           std::shared_ptr<ui::strings> const &strings) mutable {
                    float distance = 0.0f;

                    if (strings->font_atlas()) {
                        auto const &font_atlas = strings->font_atlas();
                        distance += font_atlas->ascent() + font_atlas->descent();
                    }

                    strings->preferred_layout_guide()
                        ->bottom()
                        ->observe([weak_strings = to_weak(strings), distance](float const &value) {
                            if (auto const strings = weak_strings.lock()) {
                                strings->preferred_layout_guide()->top()->set_value(value + distance);
                            }
                        })
                        .sync()
                        ->set_to(top_layout);
                };

                strings_handler(strings);

                strings_observer = strings
                                       ->observe_font_atlas([strings_handler = std::move(strings_handler),
                                                             weak_strings = to_weak(strings)](
                                                                std::shared_ptr<ui::font_atlas> const &) mutable {
                                           if (auto strings = weak_strings.lock()) {
                                               strings_handler(strings);
                                           }
                                       })
                                       .end();
            } else {
                layouts_pool = nullptr;
                strings_observer = nullptr;
            }
        })
        .end()
        ->set_to(this->_renderer_canceller);

    this->_timer = timer{1.0, true, [this] { this->_update_text(); }};
}

std::shared_ptr<strings> const &sample::draw_call_text::strings() {
    return this->_strings;
}

void sample::draw_call_text::_update_text() {
    std::string text = "---";

    if (auto const metal_system = this->_weak_metal_system.lock()) {
        std::size_t const count = metal_system->last_encoded_mesh_count();
        text = "drawcall:" + std::to_string(count);
    }

    this->_strings->set_text(text);
}

sample::draw_call_text_ptr sample::draw_call_text::make_shared(std::shared_ptr<font_atlas> const &atlas,
                                                               std::shared_ptr<ui::metal_system> const &metal_system) {
    return std::shared_ptr<draw_call_text>(new draw_call_text{atlas, metal_system});
}
