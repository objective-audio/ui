//
//  yas_sample_touch_holder.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
class touch_object;

struct touch_holder {
    void set_texture(ui::texture_ptr const &);

    ui::node_ptr const &node();

    static touch_holder_ptr make_shared();

   private:
    ui::node_ptr root_node = ui::node::make_shared();
    std::unordered_map<uintptr_t, touch_object> _objects;
    ui::texture_ptr _texture = nullptr;
    ui::rect_plane_data_ptr _rect_plane_data = ui::rect_plane_data::make_shared(1);
    chaining::any_observer_ptr _renderer_observer = nullptr;

    touch_holder();

    void _prepare(touch_holder_ptr const &);
    void _update_touch_node(ui::event_ptr const &);
    void _set_texture(ui::texture_ptr const &texture);
    void _insert_touch_node(uintptr_t const identifier);
    void _move_touch_node(uintptr_t const identifier, ui::point const &position);
    void _erase_touch_node(uintptr_t const identifier);
};
}  // namespace yas::sample
