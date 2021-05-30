//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"
#include <cpp_utils/yas_stl_utils.h>

using namespace yas;
using namespace yas::ui;

sample::modifier_text::modifier_text(std::shared_ptr<font_atlas> const &font_atlas,
                                     std::shared_ptr<layout_guide> const &bottom_guide)
    : _strings(
          strings::make_shared({.font_atlas = font_atlas, .max_word_count = 64, .alignment = layout_alignment::max})),
      _bottom_guide(bottom_guide) {
    this->_strings->rect_plane()
        ->node()
        ->observe_renderer(
            [this, pool = observing::canceller_pool::make_shared()](std::shared_ptr<renderer> const &renderer) {
                pool->cancel();

                if (renderer) {
                    renderer->event_manager()
                        ->observe([this, flags = std::unordered_set<modifier_flags>{}](auto const &event) mutable {
                            if (event->type() == event_type::modifier) {
                                this->_update_text(event, flags);
                            }
                        })
                        .end()
                        ->add_to(*pool);

                    auto const &safe_area_guide_rect = renderer->safe_area_layout_guide_rect();

                    safe_area_guide_rect->left()
                        ->observe([this](float const &value) {
                            this->_strings->frame_layout_guide_rect()->left()->set_value(value + 4.0f);
                        })
                        .sync()
                        ->add_to(*pool);

                    safe_area_guide_rect->right()
                        ->observe([this](float const &value) {
                            this->_strings->frame_layout_guide_rect()->right()->set_value(value - 4.0f);
                        })
                        .sync()
                        ->add_to(*pool);

                    this->_bottom_guide
                        ->observe([this](float const &value) {
                            this->_strings->frame_layout_guide_rect()->bottom()->set_value(value + 4.0f);
                        })
                        .sync()
                        ->add_to(*pool);

                    this->_strings
                        ->observe_font_atlas([this, top_layout = observing::cancellable_ptr{nullptr}](
                                                 std::shared_ptr<ui::font_atlas> const &value) mutable {
                            float distance = 0.0f;

                            if (auto const &font_atlas = this->_strings->font_atlas()) {
                                distance += font_atlas->ascent() + font_atlas->descent();
                            }

                            this->_strings->frame_layout_guide_rect()
                                ->bottom()
                                ->observe([this, distance](float const &value) {
                                    this->_strings->frame_layout_guide_rect()->top()->set_value(value + distance);
                                })
                                .sync()
                                ->set_to(top_layout);
                        })
                        .sync()
                        ->add_to(*pool);
                }
            })
        .end()
        ->set_to(this->_renderer_canceller);
}

std::shared_ptr<strings> const &sample::modifier_text::strings() {
    return this->_strings;
}

void sample::modifier_text::_update_text(std::shared_ptr<event> const &event,
                                         std::unordered_set<modifier_flags> &flags) {
    auto flag = event->get<modifier>().flag();

    if (event->phase() == event_phase::began) {
        flags.insert(flag);
    } else if (event->phase() == event_phase::ended) {
        flags.erase(flag);
    }

    std::vector<std::string> flag_texts;
    flag_texts.reserve(flags.size());

    for (auto const &flg : flags) {
        flag_texts.emplace_back(to_string(flg));
    }

    this->_strings->set_text(joined(flag_texts, " + "));
}

sample::modifier_text_ptr sample::modifier_text::make_shared(std::shared_ptr<font_atlas> const &atlas,
                                                             std::shared_ptr<layout_guide> const &bottom_guide) {
    return std::shared_ptr<modifier_text>(new modifier_text{atlas, bottom_guide});
}
