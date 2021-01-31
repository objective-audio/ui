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

    [[nodiscard]] observing::canceller_ptr observe(observing::caller<std::string>::handler_f &&);

    static soft_keyboard_ptr make_shared(ui::font_atlas_ptr const &);

   private:
    ui::node_ptr _root_node = ui::node::make_shared();
    observing::notifier_ptr<std::string> _key_notifier = observing::notifier<std::string>::make_shared();

    std::vector<sample::soft_key_ptr> _soft_keys;
    ui::font_atlas_ptr _font_atlas;

    std::shared_ptr<ui::collection_layout> _collection_layout = nullptr;
    std::vector<observing::cancellable_ptr> _frame_cancellers;

    std::vector<observing::canceller_ptr> _soft_key_cancellers;
    observing::canceller_ptr _renderer_canceller = nullptr;
    observing::cancellable_ptr _actual_cell_count_canceller = nullptr;
    ui::layout_animator_ptr _cell_interporator = nullptr;
    std::vector<ui::layout_guide_rect_ptr> _src_cell_guide_rects;
    std::vector<ui::layout_guide_rect_ptr> _dst_cell_guide_rects;
    std::vector<observing::cancellable_ptr> _fixed_cell_layouts;
    observing::canceller_pool _dst_rect_pool;

    explicit soft_keyboard(ui::font_atlas_ptr const &);

    void _setup_soft_keys_if_needed();
    void _dispose_soft_keys();
    void _setup_soft_keys_layout();
    void _update_soft_key_count();
    void _update_soft_keys_enabled(bool animated);
};
}  // namespace yas::sample
