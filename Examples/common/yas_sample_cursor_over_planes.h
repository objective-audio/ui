//
//  yas_sample_cursor_over_planes.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct cursor_over_planes {
    std::shared_ptr<ui::node> const &node();

    static cursor_over_planes_ptr make_shared(std::shared_ptr<ui::event_manager> const &,
                                              std::shared_ptr<ui::action_manager> const &,
                                              std::shared_ptr<ui::detector> const &);

   private:
    std::shared_ptr<ui::node> root_node = ui::node::make_shared();
    std::vector<std::shared_ptr<ui::node>> _nodes;
    observing::cancellable_ptr _event_canceller = nullptr;

    cursor_over_planes(std::shared_ptr<ui::event_manager> const &, std::shared_ptr<ui::action_manager> const &,
                       std::shared_ptr<ui::detector> const &);

    void _setup_nodes();
};
}  // namespace yas::sample
