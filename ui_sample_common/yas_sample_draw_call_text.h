//
//  yas_sample_draw_call_text.h
//

#pragma once

#include <cpp_utils/yas_timer.h>
#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct draw_call_text {
    std::shared_ptr<ui::strings> const &strings();

    static draw_call_text_ptr make_shared(std::shared_ptr<ui::font_atlas> const &);

   private:
    std::shared_ptr<ui::strings> _strings;
    std::optional<timer> _timer = std::nullopt;
    observing::cancellable_ptr _renderer_canceller = nullptr;

    explicit draw_call_text(std::shared_ptr<ui::font_atlas> const &);

    void _update_text();
};
}  // namespace yas::sample
