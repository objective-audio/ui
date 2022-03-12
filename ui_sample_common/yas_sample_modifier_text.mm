//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"
#include <cpp_utils/yas_stl_utils.h>

using namespace yas;
using namespace yas::ui;

sample::modifier_text::modifier_text(std::shared_ptr<font_atlas> const &font_atlas,
                                     std::shared_ptr<ui::event_manager> const &event_manager,
                                     std::shared_ptr<ui::layout_region_source> const &safe_area_guide,
                                     std::shared_ptr<layout_value_guide> const &bottom_guide)
    : _strings(strings::make_shared({.max_word_count = 64, .alignment = layout_alignment::max}, font_atlas)),
      _bottom_guide(bottom_guide) {
    event_manager
        ->observe([this, flags = std::unordered_set<modifier_flags>{}](auto const &event) mutable {
            if (event->type() == event_type::modifier) {
                this->_update_text(event, flags);
            }
        })
        .end()
        ->add_to(this->_pool);

    safe_area_guide->layout_horizontal_range_source()
        ->layout_min_value_source()
        ->observe_layout_value(
            [this](float const &value) { this->_strings->preferred_layout_guide()->left()->set_value(value + 4.0f); })
        .sync()
        ->add_to(this->_pool);

    safe_area_guide->layout_horizontal_range_source()
        ->layout_max_value_source()
        ->observe_layout_value(
            [this](float const &value) { this->_strings->preferred_layout_guide()->right()->set_value(value - 4.0f); })
        .sync()
        ->add_to(this->_pool);

    this->_bottom_guide
        ->observe(
            [this](float const &value) { this->_strings->preferred_layout_guide()->bottom()->set_value(value + 4.0f); })
        .sync()
        ->add_to(this->_pool);

    float const distance = font_atlas->ascent() + font_atlas->descent();

    this->_strings->preferred_layout_guide()
        ->bottom()
        ->observe([this, distance](float const &value) {
            this->_strings->preferred_layout_guide()->top()->set_value(value + distance);
        })
        .sync()
        ->add_to(this->_pool);
}

std::shared_ptr<strings> const &sample::modifier_text::strings() {
    return this->_strings;
}

void sample::modifier_text::_update_text(std::shared_ptr<event> const &event,
                                         std::unordered_set<modifier_flags> &flags) {
    auto flag = event->get<modifier>().flag;

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

sample::modifier_text_ptr sample::modifier_text::make_shared(
    std::shared_ptr<font_atlas> const &atlas, std::shared_ptr<ui::event_manager> const &event_manager,
    std::shared_ptr<ui::layout_region_source> const &safe_area_guide,
    std::shared_ptr<layout_value_guide> const &bottom_guide) {
    return std::shared_ptr<modifier_text>(new modifier_text{atlas, event_manager, safe_area_guide, bottom_guide});
}
