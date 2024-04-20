//
//  yas_ui_render_target_types.h
//

#pragma once

#include <cpp-utils/yas_flagset.h>

namespace yas::ui {
enum class render_target_update_reason : std::size_t {
    region,
    scale_factor,
    effect,

    count,
};

using render_target_updates_t = flagset<render_target_update_reason>;
}  // namespace yas::ui
