//
//  yas_sample_draw_call_text.h
//

#pragma once

#include <cpp_utils/yas_timer.h>
#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct draw_call_text {
    ui::strings_ptr const &strings();

    static draw_call_text_ptr make_shared(ui::font_atlas_ptr const &);

   private:
    ui::strings_ptr _strings;
    std::optional<timer> _timer = std::nullopt;
    observing::cancellable_ptr _renderer_canceller = nullptr;

    explicit draw_call_text(ui::font_atlas_ptr const &);

    void _update_text();
};
}  // namespace yas::sample
