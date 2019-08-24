//
//  yas_sample_touch_holder.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct touch_holder {
    class impl;

    void set_texture(ui::texture_ptr const &);

    ui::node_ptr const &node();

    static touch_holder_ptr make_shared();

   private:
    std::unique_ptr<impl> _impl;

    touch_holder();

    void _prepare(touch_holder_ptr const &);
};
}  // namespace yas::sample
