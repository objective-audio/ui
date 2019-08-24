//
//  yas_sample_bg.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct bg {
    class impl;

    ui::rect_plane_ptr const &rect_plane();

    static bg_ptr make_shared();

   private:
    std::shared_ptr<impl> _impl;

    bg();

    void _prepare(bg_ptr const &);
};
}  // namespace yas::sample
