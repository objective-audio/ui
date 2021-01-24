//
//  yas_sample_cursor.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct cursor {
    ui::node_ptr const &node();

    static cursor_ptr make_shared();

   private:
    ui::node_ptr _node = ui::node::make_shared();
    observing::canceller_ptr _renderer_canceller = nullptr;

    cursor();

    void _prepare(cursor_ptr const &);
    void _setup_node();
};
}  // namespace yas::sample
