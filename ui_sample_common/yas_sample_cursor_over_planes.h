//
//  yas_sample_cursor_over_planes.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct cursor_over_planes {
    class impl;

    ui::node_ptr const &node();

    static cursor_over_planes_ptr make_shared();

   private:
    std::unique_ptr<impl> _impl;

    cursor_over_planes();

    void _prepare(cursor_over_planes_ptr const &);
};
}  // namespace yas::sample
