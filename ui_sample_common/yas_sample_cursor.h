//
//  yas_sample_cursor.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
struct cursor {
    std::shared_ptr<ui::node> const &node();

    static cursor_ptr make_shared(std::shared_ptr<ui::event_manager> const &,
                                  std::shared_ptr<ui::action_manager> const &);

   private:
    std::shared_ptr<ui::node> const _node = ui::node::make_shared();
    observing::cancellable_ptr _event_canceller = nullptr;

    explicit cursor(std::shared_ptr<ui::event_manager> const &, std::shared_ptr<ui::action_manager> const &);

    void _setup_node();
};
}  // namespace yas::sample
