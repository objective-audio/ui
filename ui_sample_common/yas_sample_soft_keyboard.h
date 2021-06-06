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
    void set_font_atlas(std::shared_ptr<ui::font_atlas> const &);

    std::shared_ptr<ui::node> const &node();

    [[nodiscard]] observing::endable observe(observing::caller<std::string>::handler_f &&);

    static soft_keyboard_ptr make_shared(std::shared_ptr<ui::font_atlas> const &);

   private:
    std::shared_ptr<ui::node> _root_node = ui::node::make_shared();
    observing::notifier_ptr<std::string> _key_notifier = observing::notifier<std::string>::make_shared();

    std::vector<sample::soft_key_ptr> _soft_keys;
    std::shared_ptr<ui::font_atlas> _font_atlas;

    std::shared_ptr<ui::collection_layout> _collection_layout = nullptr;
    std::vector<observing::cancellable_ptr> _frame_cancellers;

    std::vector<observing::cancellable_ptr> _soft_key_cancellers;
    observing::cancellable_ptr _renderer_canceller = nullptr;
    observing::cancellable_ptr _actual_cell_count_canceller = nullptr;
    std::shared_ptr<ui::layout_animator> _cell_interporator = nullptr;
    std::vector<std::shared_ptr<ui::layout_region_guide>> _src_cell_region_guides;
    std::vector<std::shared_ptr<ui::layout_region_guide>> _dst_cell_region_guides;
    std::vector<observing::cancellable_ptr> _fixed_cell_layouts;
    observing::canceller_pool _dst_rect_pool;

    explicit soft_keyboard(std::shared_ptr<ui::font_atlas> const &);

    void _setup_soft_keys_if_needed();
    void _dispose_soft_keys();
    void _setup_soft_keys_layout();
    void _update_soft_key_count();
    void _update_soft_keys_enabled(bool animated);
};
}  // namespace yas::sample
