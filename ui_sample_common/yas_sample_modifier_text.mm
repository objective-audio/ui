//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"
#include <chaining/yas_chaining_utils.h>
#include <cpp_utils/yas_stl_utils.h>

using namespace yas;

sample::modifier_text::modifier_text(ui::font_atlas_ptr const &font_atlas, ui::layout_guide_ptr const &bottom_guide)
    : _strings(ui::strings::make_shared(
          {.font_atlas = font_atlas, .max_word_count = 64, .alignment = ui::layout_alignment::max})),
      _bottom_guide(bottom_guide) {
    this->_strings->rect_plane()
        ->node()
        ->observe_renderer(
            [this, pool = observing::canceller_pool::make_shared()](ui::renderer_ptr const &renderer) {
                pool->invalidate();

                if (renderer) {
                    renderer->event_manager()
                        ->observe(
                            [this, flags = std::unordered_set<ui::modifier_flags>{}](auto const &context) mutable {
                                if (context.method == ui::event_manager::method::modifier_changed) {
                                    ui::event_ptr const &event = context.event;
                                    this->_update_text(event, flags);
                                }
                            })
                        ->add_to(*pool);

                    auto const &safe_area_guide_rect = renderer->safe_area_layout_guide_rect();

                    safe_area_guide_rect->left()
                        ->observe(
                            [this](float const &value) {
                                this->_strings->frame_layout_guide_rect()->left()->set_value(value + 4.0f);
                            },
                            true)
                        ->add_to(*pool);

                    safe_area_guide_rect->right()
                        ->observe(
                            [this](float const &value) {
                                this->_strings->frame_layout_guide_rect()->right()->set_value(value - 4.0f);
                            },
                            true)
                        ->add_to(*pool);

                    this->_bottom_guide
                        ->observe(
                            [this](float const &value) {
                                this->_strings->frame_layout_guide_rect()->bottom()->set_value(value + 4.0f);
                            },
                            true)
                        ->add_to(*pool);

                    this->_strings
                        ->observe_font_atlas(
                            [this, top_layout =
                                       observing::cancellable_ptr{nullptr}](ui::font_atlas_ptr const &value) mutable {
                                float distance = 0.0f;

                                if (auto const &font_atlas = this->_strings->font_atlas()) {
                                    distance += font_atlas->ascent() + font_atlas->descent();
                                }

                                this->_strings->frame_layout_guide_rect()
                                    ->bottom()
                                    ->observe(
                                        [this, distance](float const &value) {
                                            this->_strings->frame_layout_guide_rect()->top()->set_value(value +
                                                                                                        distance);
                                        },
                                        true)
                                    ->set_to(top_layout);
                            },
                            true)
                        ->add_to(*pool);
                }
            },
            false)
        ->set_to(this->_renderer_canceller);
}

ui::strings_ptr const &sample::modifier_text::strings() {
    return this->_strings;
}

void sample::modifier_text::_update_text(ui::event_ptr const &event, std::unordered_set<ui::modifier_flags> &flags) {
    auto flag = event->get<ui::modifier>().flag();

    if (event->phase() == ui::event_phase::began) {
        flags.insert(flag);
    } else if (event->phase() == ui::event_phase::ended) {
        flags.erase(flag);
    }

    std::vector<std::string> flag_texts;
    flag_texts.reserve(flags.size());

    for (auto const &flg : flags) {
        flag_texts.emplace_back(to_string(flg));
    }

    this->_strings->set_text(joined(flag_texts, " + "));
}

sample::modifier_text_ptr sample::modifier_text::make_shared(ui::font_atlas_ptr const &atlas,
                                                             ui::layout_guide_ptr const &bottom_guide) {
    return std::shared_ptr<modifier_text>(new modifier_text{atlas, bottom_guide});
}
