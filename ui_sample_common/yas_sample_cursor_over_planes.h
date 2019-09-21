//
//  yas_sample_cursor_over_planes.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
struct cursor_over_planes {
    ui::node_ptr const &node();

    static cursor_over_planes_ptr make_shared();

   private:
    ui::node_ptr root_node = ui::node::make_shared();
    std::vector<ui::node_ptr> _nodes;
    chaining::any_observer_ptr _renderer_observer = nullptr;

    cursor_over_planes();

    void _prepare(cursor_over_planes_ptr const &);
    void _setup_nodes();
};
}  // namespace yas::sample
