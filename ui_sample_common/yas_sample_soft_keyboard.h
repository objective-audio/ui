//
//  yas_sample_soft_keyboard.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct soft_keyboard {
    class impl;

    void set_font_atlas(ui::font_atlas_ptr const &);

    ui::node_ptr const &node();

    chaining::chain_unsync_t<std::string> chain() const;

    static soft_keyboard_ptr make_shared(ui::font_atlas_ptr const &);

   private:
    std::unique_ptr<impl> _impl;

    explicit soft_keyboard(ui::font_atlas_ptr const &);

    void _prepare(soft_keyboard_ptr const &);
};
}  // namespace yas::sample
