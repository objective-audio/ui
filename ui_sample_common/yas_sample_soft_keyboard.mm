//
//  yas_sample_soft_keyboard.mm
//

#include "yas_sample_soft_keyboard.h"
#include <cpp_utils/yas_fast_each.h>
#include <cpp_utils/yas_stl_utils.h>
#include <limits>

using namespace yas;
using namespace yas::ui;

namespace yas::sample {
struct soft_key {
    std::shared_ptr<button> const &button() {
        return this->_button;
    }

    std::shared_ptr<strings> const &strings() const {
        return this->_strings;
    }

    void set_enabled(bool const enabled, bool const animated = false) {
        auto const &button_node = button()->rect_plane()->node();
        auto const &strings_node = this->_strings->rect_plane()->node();

        button_node->collider()->set_enabled(enabled);

        float const alpha = enabled ? 1.0f : 0.0f;

        if (auto const action_manager = this->_weak_action_manager.lock()) {
            action_manager->erase_action(button_node);
            action_manager->erase_action(strings_node);

            if (animated) {
                action_manager->insert_action(
                    make_action({.target = button_node, .begin_alpha = button_node->alpha(), .end_alpha = alpha}));
                action_manager->insert_action(
                    make_action({.target = strings_node, .begin_alpha = strings_node->alpha(), .end_alpha = alpha}));
            } else {
                button_node->set_alpha(alpha);
                strings_node->set_alpha(alpha);
            }
        }
    }

    static soft_key_ptr make_shared(std::string key, float const width, std::shared_ptr<font_atlas> const &atlas,
                                    std::shared_ptr<ui::event_manager> const &event_manager,
                                    std::shared_ptr<ui::action_manager> const &action_manager,
                                    std::shared_ptr<ui::detector> const &detector) {
        return std::shared_ptr<soft_key>(
            new soft_key(std::move(key), width, atlas, event_manager, action_manager, detector));
    }

   private:
    std::shared_ptr<ui::button> const _button;
    std::shared_ptr<ui::strings> const _strings;
    std::weak_ptr<ui::action_manager> const _weak_action_manager;

    soft_key(std::string &&key, float const width, std::shared_ptr<font_atlas> const &atlas,
             std::shared_ptr<ui::event_manager> const &event_manager,
             std::shared_ptr<ui::action_manager> const &action_manager, std::shared_ptr<ui::detector> const &detector)
        : _button(button::make_shared({.size = {width, width}}, event_manager, detector)),
          _strings(strings::make_shared({.font_atlas = atlas, .max_word_count = 1})),
          _weak_action_manager(action_manager) {
        this->_button->rect_plane()->node()->mesh()->set_use_mesh_color(true);
        this->_button->rect_plane()->data()->set_rect_color(simd::float4{0.5f, 0.5f, 0.5f, 1.0f}, 0);
        this->_button->rect_plane()->data()->set_rect_color(simd::float4{0.2f, 0.2f, 0.2f, 1.0f}, 1);

        this->_strings->set_text(std::move(key));
        this->_strings->set_alignment(layout_alignment::mid);

        this->_button->rect_plane()->node()->add_sub_node(this->_strings->rect_plane()->node());

        auto const &font_atlas = this->_strings->font_atlas();
        float const strings_offset_y = std::roundf((width + font_atlas->ascent() + font_atlas->descent()) * 0.5f);

        this->_strings->preferred_layout_guide()->set_region(
            {.origin = {.y = strings_offset_y}, .size = {.width = width}});
    }
};
}

sample::soft_keyboard::soft_keyboard(std::shared_ptr<font_atlas> const &atlas,
                                     std::shared_ptr<ui::event_manager> const &event_manager,
                                     std::shared_ptr<action_manager> const &action_manager,
                                     std::shared_ptr<ui::detector> const &detector,
                                     std::shared_ptr<layout_region_source> const &safe_area_guide)
    : _font_atlas(atlas) {
    this->_setup_soft_keys_if_needed(event_manager, action_manager, detector, safe_area_guide);
}

std::shared_ptr<node> const &sample::soft_keyboard::node() {
    return this->_root_node;
}

observing::endable sample::soft_keyboard::observe(observing::caller<std::string>::handler_f &&handler) {
    return this->_key_notifier->observe(std::move(handler));
}

void sample::soft_keyboard::_setup_soft_keys_if_needed(
    std::shared_ptr<event_manager> const &event_manager, std::shared_ptr<action_manager> const &action_manager,
    std::shared_ptr<ui::detector> const &detector, std::shared_ptr<ui::layout_region_source> const &safe_area_guide) {
    auto const keys = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"};
    auto const key_count = keys.size();
    auto const key_width = 36.0f;
    auto const spacing = 4.0f;
    auto const width = key_width * 3.0f + spacing * 4.0f;

    std::vector<size> cell_sizes;
    cell_sizes.reserve(key_count);
    auto each = make_fast_each(key_count);
    while (yas_each_next(each)) {
        if (yas_each_index(each) == 0) {
            cell_sizes.emplace_back(size{0.0f, key_width});
        } else {
            cell_sizes.emplace_back(size{key_width, key_width});
        }
    }

    this->_soft_keys.reserve(key_count);
    this->_soft_key_cancellers.reserve(key_count);

    this->_collection_layout = collection_layout::make_shared(
        {.frame = {.size = {width, 0.0f}},
         .preferred_cell_count = key_count,
         .lines = {{.cell_sizes = cell_sizes}},
         .row_spacing = spacing,
         .col_spacing = spacing,
         .borders = {.left = spacing, .right = spacing, .bottom = spacing, .top = spacing}});

    for (auto const &key : keys) {
        sample::soft_key_ptr soft_key =
            sample::soft_key::make_shared(key, key_width, this->_font_atlas, event_manager, action_manager, detector);

        observing::cancellable_ptr canceller = soft_key->button()
                                                   ->observe([this, key](auto const &context) {
                                                       if (context.method == button::method::ended) {
                                                           this->_key_notifier->notify(key);
                                                       }
                                                   })
                                                   .end();

        this->_soft_key_cancellers.emplace_back(std::move(canceller));

        auto &node = soft_key->button()->rect_plane()->node();

        this->_root_node->add_sub_node(node);
        this->_soft_keys.emplace_back(std::move(soft_key));
    }

    this->_collection_layout
        ->observe_actual_cell_layout_guides([this](auto const &) {
            this->_update_soft_keys_enabled(true);
            this->_update_soft_key_count();
        })
        .end()
        ->set_to(this->_actual_cell_count_canceller);

    if (this->_src_cell_layout_guides.size() > key_count) {
        this->_src_cell_layout_guides.resize(key_count);
    } else {
        while (this->_src_cell_layout_guides.size() < key_count) {
            this->_src_cell_layout_guides.emplace_back(layout_region_guide::make_shared());
        }
    }

    if (this->_dst_cell_layout_guides.size() > key_count) {
        this->_dst_cell_layout_guides.resize(key_count);
    } else {
        while (this->_dst_cell_layout_guides.size() < key_count) {
            this->_dst_cell_layout_guides.emplace_back(layout_region_guide::make_shared());
        }
    }

    this->_fixed_cell_layouts.reserve(key_count);

    ui::layout(safe_area_guide->layout_horizontal_range_source()->layout_min_value_source(),
               this->_collection_layout->preferred_layout_guide()->left(), [](float const &value) { return value; })
        .sync()
        ->add_to(this->_frame_pool);

    ui::layout(safe_area_guide->layout_vertical_range_source()->layout_min_value_source(),
               this->_collection_layout->preferred_layout_guide()->bottom(), [](float const &value) { return value; })
        .sync()
        ->add_to(this->_frame_pool);

    ui::layout(safe_area_guide->layout_vertical_range_source()->layout_max_value_source(),
               this->_collection_layout->preferred_layout_guide()->top(), [](float const &value) { return value; })
        .sync()
        ->add_to(this->_frame_pool);

    ui::layout(safe_area_guide->layout_horizontal_range_source(),
               this->_collection_layout->preferred_layout_guide()->right(),
               [width](ui::range const &range) { return std::min(range.min() + width, range.max()); })
        .sync()
        ->add_to(this->_frame_pool);

    this->_setup_soft_keys_layout(action_manager);
    this->_update_soft_key_count();
    this->_update_soft_keys_enabled(false);
}

void sample::soft_keyboard::_setup_soft_keys_layout(std::shared_ptr<action_manager> const &action_manager) {
    auto const key_count = this->_soft_keys.size();

    if (key_count == 0 || !this->_collection_layout) {
        return;
    }

    if (this->_cell_interporator) {
        return;
    }

    std::vector<layout_value_guide_pair> guide_pairs;
    guide_pairs.reserve(key_count * 4);

    auto each = make_fast_each(key_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto &soft_key = this->_soft_keys.at(idx);
        auto &dst_guide_rect = this->_dst_cell_layout_guides.at(idx);

        auto weak_soft_key = to_weak(soft_key);

        dst_guide_rect
            ->observe([weak_soft_key](region const &value) {
                if (auto const soft_key = weak_soft_key.lock()) {
                    soft_key->button()->rect_plane()->node()->set_position({value.origin.x, value.origin.y});
                    soft_key->button()->layout_guide()->set_region({.size = value.size});
                }
            })
            .end()
            ->add_to(this->_dst_rect_pool);

        yas::move_back_insert(guide_pairs, make_layout_guide_pairs({.source = this->_src_cell_layout_guides.at(idx),
                                                                    .destination = dst_guide_rect}));
    }

    this->_cell_interporator = layout_animator::make_shared(
        {.action_manager = action_manager, .layout_guide_pairs = std::move(guide_pairs), .duration = 0.3f});
}

void sample::soft_keyboard::_update_soft_key_count() {
    auto const key_count = this->_soft_keys.size();

    if (key_count == 0 || !this->_collection_layout) {
        return;
    }

    if (!this->_cell_interporator) {
        return;
    }

    auto const layout_count = this->_collection_layout->actual_cell_count();

    auto each = make_fast_each(key_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        if (idx < layout_count) {
            if (idx >= this->_fixed_cell_layouts.size()) {
                auto const &src_guide_rect = this->_collection_layout->actual_cell_layout_guides().at(idx);
                auto weak_dst_guide = to_weak(this->_src_cell_layout_guides.at(idx));

                auto pool = observing::canceller_pool::make_shared();

                src_guide_rect->left()
                    ->observe([weak_dst_guide](float const &value) {
                        if (auto const guide = weak_dst_guide.lock()) {
                            guide->left()->set_value(value);
                        }
                    })
                    .sync()
                    ->add_to(*pool);
                src_guide_rect->bottom()
                    ->observe([weak_dst_guide](float const &value) {
                        if (auto const guide = weak_dst_guide.lock()) {
                            guide->bottom()->set_value(value);
                        }
                    })
                    .sync()
                    ->add_to(*pool);
                src_guide_rect->right()
                    ->observe([weak_dst_guide](float const &value) {
                        if (auto const guide = weak_dst_guide.lock()) {
                            guide->right()->set_value(value);
                        }
                    })
                    .sync()
                    ->add_to(*pool);
                src_guide_rect->top()
                    ->observe([weak_dst_guide](float const &value) {
                        if (auto const guide = weak_dst_guide.lock()) {
                            guide->top()->set_value(value);
                        }
                    })
                    .sync()
                    ->add_to(*pool);

                this->_fixed_cell_layouts.emplace_back(std::move(pool));
            }
        } else {
            if (layout_count < this->_fixed_cell_layouts.size()) {
                this->_fixed_cell_layouts.resize(layout_count);
            }
            break;
        }
    }
}

void sample::soft_keyboard::_update_soft_keys_enabled(bool animated) {
    auto const key_count = this->_soft_keys.size();

    if (key_count == 0 || !this->_collection_layout) {
        return;
    }

    auto const layout_count = this->_collection_layout->actual_cell_count();

    auto each = make_fast_each(key_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        this->_soft_keys.at(idx)->set_enabled(idx < layout_count, animated);
    }
}

sample::soft_keyboard_ptr sample::soft_keyboard::make_shared(
    std::shared_ptr<font_atlas> const &atlas, std::shared_ptr<ui::event_manager> const &event_manager,
    std::shared_ptr<ui::action_manager> const &action_manager, std::shared_ptr<ui::detector> const &detector,
    std::shared_ptr<layout_region_source> const &safe_area_guide) {
    return std::shared_ptr<soft_keyboard>(
        new soft_keyboard{atlas, event_manager, action_manager, detector, safe_area_guide});
}
