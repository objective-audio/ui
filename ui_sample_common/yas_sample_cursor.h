//
//  yas_sample_cursor.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct cursor {
    class impl;

    ui::node_ptr const &node();

    static cursor_ptr make_shared();

   private:
    std::unique_ptr<impl> _impl;

    cursor();

    void _prepare(cursor_ptr const &);
};
}  // namespace yas::sample
