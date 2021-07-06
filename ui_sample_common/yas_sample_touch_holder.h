//
//  yas_sample_touch_holder.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>

#include "yas_sample_ptr.h"

namespace yas::sample {
class touch_object;

struct touch_holder {
    void set_texture(std::shared_ptr<ui::texture> const &);

    std::shared_ptr<ui::node> const &node();

    static touch_holder_ptr make_shared(std::shared_ptr<ui::event_manager> const &,
                                        std::shared_ptr<ui::action_manager> const &);

   private:
    std::shared_ptr<ui::node> root_node = ui::node::make_shared();
    std::unordered_map<uintptr_t, touch_object> _objects;
    std::shared_ptr<ui::texture> _texture = nullptr;
    std::shared_ptr<ui::rect_plane_data> _rect_plane_data = ui::rect_plane_data::make_shared(1);
    observing::cancellable_ptr _event_canceller = nullptr;

    touch_holder(std::shared_ptr<ui::event_manager> const &, std::shared_ptr<ui::action_manager> const &);

    void _update_touch_node(std::shared_ptr<ui::event> const &, std::shared_ptr<ui::action_manager> const &);
    void _set_texture(std::shared_ptr<ui::texture> const &texture);
    void _insert_touch_node(uintptr_t const identifier, std::shared_ptr<ui::action_manager> const &action_manager);
    void _move_touch_node(uintptr_t const identifier, ui::point const &position);
    void _erase_touch_node(uintptr_t const identifier, std::shared_ptr<ui::action_manager> const &);
};
}  // namespace yas::sample
