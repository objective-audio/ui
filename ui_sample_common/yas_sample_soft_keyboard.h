//
//  yas_sample_soft_keyboard.h
//

#pragma once

#include <ui/yas_ui_umbrella.h>
#include "yas_sample_ptr.h"

namespace yas::sample {
class soft_key;
using soft_key_ptr = std::shared_ptr<soft_key>;

struct soft_keyboard {
    void set_font_atlas(ui::font_atlas_ptr const &);

    ui::node_ptr const &node();

    chaining::chain_unsync_t<std::string> chain() const;

    static soft_keyboard_ptr make_shared(ui::font_atlas_ptr const &);

   private:
    ui::node_ptr _root_node = ui::node::make_shared();
    chaining::notifier_ptr<std::string> _key_sender = chaining::notifier<std::string>::make_shared();

    std::weak_ptr<soft_keyboard> _weak_keyboard;

    std::vector<sample::soft_key_ptr> _soft_keys;
    ui::font_atlas_ptr _font_atlas;

    std::shared_ptr<ui::collection_layout> _collection_layout = nullptr;
    std::vector<chaining::any_observer_ptr> _frame_layouts;

    std::vector<chaining::any_observer_ptr> _soft_key_observers;
    chaining::any_observer_ptr _renderer_observer = nullptr;
    chaining::any_observer_ptr _actual_cell_count_observer = nullptr;
    ui::layout_animator_ptr _cell_interporator = nullptr;
    std::vector<ui::layout_guide_rect_ptr> _src_cell_guide_rects;
    std::vector<ui::layout_guide_rect_ptr> _dst_cell_guide_rects;
    std::vector<std::vector<chaining::any_observer_ptr>> _fixed_cell_layouts;
    std::vector<chaining::any_observer_ptr> _dst_rect_observers;

    explicit soft_keyboard(ui::font_atlas_ptr const &);

    void _prepare(soft_keyboard_ptr const &);
    void _setup_soft_keys_if_needed();
    void _dispose_soft_keys();
    void _setup_soft_keys_layout();
    void _update_soft_key_count();
    void _update_soft_keys_enabled(bool animated);
};
}  // namespace yas::sample
