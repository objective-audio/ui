//
//  yas_ui_effect.mm
//

#include "yas_ui_effect_protocol.h"
#include <cpp_utils/yas_fast_each.h>
#include <cpp_utils/yas_stl_utils.h>
#include "yas_ui_texture.h"

using namespace yas;

ui::renderable_effect_ptr ui::renderable_effect::cast(renderable_effect_ptr const &renderable) {
    return renderable;
}

ui::encodable_effect_ptr ui::encodable_effect::cast(encodable_effect_ptr const &encodable) {
    return encodable;
}

#pragma mark -

std::string yas::to_string(ui::effect_update_reason const &reason) {
    switch (reason) {
        case ui::effect_update_reason::textures:
            return "textures";
        case ui::effect_update_reason::handler:
            return "handler";
        case ui::effect_update_reason::count:
            return "count";
    }
}

std::string yas::to_string(ui::effect_updates_t const &updates) {
    std::vector<std::string> flag_texts;
    auto each = make_fast_each(static_cast<std::size_t>(ui::effect_update_reason::count));
    while (yas_each_next(each)) {
        auto const value = static_cast<ui::effect_update_reason>(yas_each_index(each));
        if (updates.test(value)) {
            flag_texts.emplace_back(to_string(value));
        }
    }
    return joined(flag_texts, "|");
}
