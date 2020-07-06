//
//  yas_ui_background_protocol.h
//

#pragma once

#include <cpp_utils/yas_flagset.h>

#include "yas_ui_ptr.h"

namespace yas::ui {
enum class background_update_reason : std::size_t {
    color,
    alpha,

    count,
};

using background_updates_t = flagset<background_update_reason>;

struct renderable_background {
    virtual ~renderable_background() = default;

    virtual void fetch_updates(ui::background_updates_t &) = 0;
    virtual void clear_updates() = 0;

    static renderable_background_ptr cast(renderable_background_ptr const &);
};
}  // namespace yas::ui
