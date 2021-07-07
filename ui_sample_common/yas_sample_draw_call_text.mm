//
//  yas_sample_draw_call_text.mm
//

#include "yas_sample_draw_call_text.h"

using namespace yas;
using namespace yas::ui;

sample::draw_call_text::draw_call_text(std::shared_ptr<font_atlas> const &font_atlas,
                                       std::shared_ptr<ui::metal_system> const &metal_system,
                                       std::shared_ptr<layout_region_source> const &safe_area_guide)
    : _strings(strings::make_shared(
          {.text = "---", .alignment = layout_alignment::max, .font_atlas = font_atlas, .max_word_count = 32})),
      _weak_metal_system(metal_system) {
    auto const &strings = this->strings();
    auto &strings_preferred_guide = strings->preferred_layout_guide();

    auto pool = observing::canceller_pool::make_shared();

    safe_area_guide->layout_horizontal_range_source()
        ->layout_min_value_source()
        ->observe_layout_value([weak_rect = to_weak(strings_preferred_guide)](float const &value) {
            if (auto const region = weak_rect.lock()) {
                region->right()->set_value(value + 4.0f);
            }
        })
        .sync()
        ->add_to(this->_pool);

    safe_area_guide->layout_horizontal_range_source()
        ->layout_max_value_source()
        ->observe_layout_value([weak_guide = to_weak(strings_preferred_guide)](float const &value) {
            if (auto const guide = weak_guide.lock()) {
                guide->right()->set_value(value - 4.0f);
            }
        })
        .sync()
        ->add_to(this->_pool);

    safe_area_guide->layout_vertical_range_source()
        ->layout_min_value_source()
        ->observe_layout_value([weak_guide = to_weak(strings_preferred_guide)](float const &value) {
            if (auto const guide = weak_guide.lock()) {
                guide->bottom()->set_value(value + 4.0f);
            }
        })
        .sync()
        ->add_to(this->_pool);

    float const distance = font_atlas->ascent() + font_atlas->descent();

    ui::layout(strings->preferred_layout_guide()->bottom(), strings->preferred_layout_guide()->top(),
               [distance](float const &value) { return value + distance; })
        .sync()
        ->add_to(this->_pool);

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

sample::draw_call_text_ptr sample::draw_call_text::make_shared(
    std::shared_ptr<font_atlas> const &atlas, std::shared_ptr<ui::metal_system> const &metal_system,
    std::shared_ptr<layout_region_source> const &safe_area_guide) {
    return std::shared_ptr<draw_call_text>(new draw_call_text{atlas, metal_system, safe_area_guide});
}
