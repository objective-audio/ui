//
//  yas_sample_soft_keyboard.mm
//

#include "yas_sample_soft_keyboard.h"
#include <cpp_utils/yas_fast_each.h>
#include <cpp_utils/yas_stl_utils.h>
#include <limits>

using namespace yas;

namespace yas::sample {
struct soft_key {
    std::shared_ptr<ui::button> const &button() {
        return this->_button;
    }

    ui::strings_ptr const &strings() const {
        return this->_strings;
    }

    void set_enabled(bool const enabled, bool const animated = false) {
        auto const &button_node = button()->rect_plane()->node();
        auto const &strings_node = this->_strings->rect_plane()->node();
        auto renderer = button_node->renderer();

        button_node->collider()->set_enabled(enabled);

        float const alpha = enabled ? 1.0f : 0.0f;

        renderer->erase_action(button_node);
        renderer->erase_action(strings_node);

        if (animated) {
            renderer->insert_action(
                ui::make_action({.target = button_node, .begin_alpha = button_node->alpha(), .end_alpha = alpha}));
            renderer->insert_action(
                ui::make_action({.target = strings_node, .begin_alpha = strings_node->alpha(), .end_alpha = alpha}));
        } else {
            button_node->set_alpha(alpha);
            strings_node->set_alpha(alpha);
        }
    }

    static soft_key_ptr make_shared(std::string key, float const width, ui::font_atlas_ptr const &atlas) {
        return std::shared_ptr<soft_key>(new soft_key(std::move(key), width, atlas));
    }

   private:
    ui::button_ptr const _button;
    ui::strings_ptr const _strings;

    soft_key(std::string &&key, float const width, ui::font_atlas_ptr const &atlas)
        : _button(ui::button::make_shared({.size = {width, width}})),
          _strings(ui::strings::make_shared({.font_atlas = atlas, .max_word_count = 1})) {
        this->_button->rect_plane()->node()->mesh()->set_use_mesh_color(true);
        this->_button->rect_plane()->data()->set_rect_color(simd::float4{0.5f, 0.5f, 0.5f, 1.0f}, 0);
        this->_button->rect_plane()->data()->set_rect_color(simd::float4{0.2f, 0.2f, 0.2f, 1.0f}, 1);

        this->_strings->set_text(std::move(key));
        this->_strings->set_alignment(ui::layout_alignment::mid);

        this->_button->rect_plane()->node()->add_sub_node(this->_strings->rect_plane()->node());

        auto const &font_atlas = this->_strings->font_atlas();
        float const strings_offset_y = std::roundf((width + font_atlas->ascent() + font_atlas->descent()) * 0.5f);

        this->_strings->frame_layout_guide_rect()->set_region(
            {.origin = {.y = strings_offset_y}, .size = {.width = width}});
    }
};
}

sample::soft_keyboard::soft_keyboard(ui::font_atlas_ptr const &atlas) : _font_atlas(atlas) {
    this->_renderer_canceller = this->_root_node->observe_renderer(
        [this](ui::renderer_ptr const &renderer) {
            if (renderer) {
                this->_setup_soft_keys_if_needed();
            } else {
                this->_dispose_soft_keys();
            }
        },
        true);
}

void sample::soft_keyboard::set_font_atlas(ui::font_atlas_ptr const &atlas) {
    if (this->_font_atlas != atlas) {
        this->_font_atlas = std::move(atlas);

        this->_setup_soft_keys_if_needed();
    }
}

ui::node_ptr const &sample::soft_keyboard::node() {
    return this->_root_node;
}

observing::cancellable_ptr sample::soft_keyboard::observe(observing::caller<std::string>::handler_f &&handler) {
    return this->_key_notifier->observe(std::move(handler));
}

void sample::soft_keyboard::_setup_soft_keys_if_needed() {
    if (this->_soft_keys.size() > 0 && this->_soft_key_cancellers.size() > 0 && this->_collection_layout &&
        this->_frame_cancellers.size() > 0 && this->_actual_cell_count_canceller) {
        return;
    }

    if (!this->_font_atlas || !this->_root_node->renderer()) {
        return;
    }

    auto const keys = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"};
    auto const key_count = keys.size();
    auto const key_width = 36.0f;
    auto const spacing = 4.0f;
    auto const width = key_width * 3.0f + spacing * 4.0f;

    std::vector<ui::size> cell_sizes;
    cell_sizes.reserve(key_count);
    auto each = make_fast_each(key_count);
    while (yas_each_next(each)) {
        if (yas_each_index(each) == 0) {
            cell_sizes.emplace_back(ui::size{0.0f, key_width});
        } else {
            cell_sizes.emplace_back(ui::size{key_width, key_width});
        }
    }

    this->_soft_keys.reserve(key_count);
    this->_soft_key_cancellers.reserve(key_count);

    this->_collection_layout = ui::collection_layout::make_shared(
        {.frame = {.size = {width, 0.0f}},
         .preferred_cell_count = key_count,
         .lines = {{.cell_sizes = cell_sizes}},
         .row_spacing = spacing,
         .col_spacing = spacing,
         .borders = {.left = spacing, .right = spacing, .bottom = spacing, .top = spacing}});

    for (auto const &key : keys) {
        sample::soft_key_ptr soft_key = sample::soft_key::make_shared(key, key_width, this->_font_atlas);

        observing::cancellable_ptr canceller = soft_key->button()->observe([this, key](auto const &context) {
            if (context.method == ui::button::method::ended) {
                this->_key_notifier->notify(key);
            }
        });

        this->_soft_key_cancellers.emplace_back(std::move(canceller));

        auto &node = soft_key->button()->rect_plane()->node();

        this->_root_node->add_sub_node(node);
        this->_soft_keys.emplace_back(std::move(soft_key));
    }

    this->_collection_layout
        ->observe_actual_cell_count(
            [this](auto const &) {
                this->_update_soft_keys_enabled(true);
                this->_update_soft_key_count();
            },
            false)
        ->set_to(this->_actual_cell_count_canceller);

    if (this->_src_cell_guide_rects.size() > key_count) {
        this->_src_cell_guide_rects.resize(key_count);
    } else {
        while (this->_src_cell_guide_rects.size() < key_count) {
            this->_src_cell_guide_rects.emplace_back(ui::layout_guide_rect::make_shared());
        }
    }

    if (this->_dst_cell_guide_rects.size() > key_count) {
        this->_dst_cell_guide_rects.resize(key_count);
    } else {
        while (this->_dst_cell_guide_rects.size() < key_count) {
            this->_dst_cell_guide_rects.emplace_back(ui::layout_guide_rect::make_shared());
        }
    }

    this->_fixed_cell_layouts.reserve(key_count);

    auto const &renderer = this->_root_node->renderer();
    auto const &safe_area_guide_rect = renderer->safe_area_layout_guide_rect();

    this->_frame_cancellers.emplace_back(safe_area_guide_rect->left()->observe(
        [this](float const &value) { this->_collection_layout->frame_guide_rect->left()->set_value(value); }, true));
    this->_frame_cancellers.emplace_back(safe_area_guide_rect->bottom()->observe(
        [this](float const &value) { this->_collection_layout->frame_guide_rect->bottom()->set_value(value); }, true));
    this->_frame_cancellers.emplace_back(safe_area_guide_rect->top()->observe(
        [this](float const &value) { this->_collection_layout->frame_guide_rect->top()->set_value(value); }, true));

    auto apply_to_frame_right = [this, width] {
        auto const &safe_area_rect = this->_root_node->renderer()->safe_area_layout_guide_rect();
        auto const min = std::min(safe_area_rect->left()->value() + width, safe_area_rect->right()->value());
        this->_collection_layout->frame_guide_rect->right()->set_value(min);
    };

    this->_frame_cancellers.emplace_back(safe_area_guide_rect->left()->observe(
        [apply_to_frame_right](float const &value) { apply_to_frame_right(); }, false));
    this->_frame_cancellers.emplace_back(safe_area_guide_rect->right()->observe(
        [apply_to_frame_right](float const &value) { apply_to_frame_right(); }, true));

    this->_setup_soft_keys_layout();
    this->_update_soft_key_count();
    this->_update_soft_keys_enabled(false);
}

void sample::soft_keyboard::_dispose_soft_keys() {
    this->_soft_keys.clear();
    this->_soft_key_cancellers.clear();
    this->_frame_cancellers.clear();
    this->_collection_layout = nullptr;
    this->_actual_cell_count_canceller = nullptr;
    this->_src_cell_guide_rects.clear();
    this->_dst_cell_guide_rects.clear();
    this->_cell_interporator = nullptr;
    this->_dst_rect_pool.cancel();
}

void sample::soft_keyboard::_setup_soft_keys_layout() {
    auto const key_count = this->_soft_keys.size();

    if (key_count == 0 || !this->_collection_layout) {
        return;
    }

    if (this->_cell_interporator) {
        return;
    }

    std::vector<ui::layout_guide_pair> guide_pairs;
    guide_pairs.reserve(key_count * 4);

    auto each = make_fast_each(key_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto &soft_key = this->_soft_keys.at(idx);
        auto &dst_guide_rect = this->_dst_cell_guide_rects.at(idx);

        auto weak_soft_key = to_weak(soft_key);

        dst_guide_rect
            ->observe(
                [weak_soft_key](ui::region const &value) {
                    if (auto const soft_key = weak_soft_key.lock()) {
                        soft_key->button()->rect_plane()->node()->set_position({value.origin.x, value.origin.y});
                        soft_key->button()->layout_guide_rect()->set_region({.size = value.size});
                    }
                },
                false)
            ->add_to(this->_dst_rect_pool);

        yas::move_back_insert(guide_pairs, ui::make_layout_guide_pairs({.source = this->_src_cell_guide_rects.at(idx),
                                                                        .destination = dst_guide_rect}));
    }

    this->_cell_interporator = ui::layout_animator::make_shared(
        {.renderer = this->_root_node->renderer(), .layout_guide_pairs = std::move(guide_pairs), .duration = 0.3f});
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
                auto const &src_guide_rect = this->_collection_layout->cell_guide_rects().at(idx);
                auto weak_dst_guide_rect = to_weak(this->_src_cell_guide_rects.at(idx));

                auto pool = observing::canceller_pool::make_shared();

                src_guide_rect->left()
                    ->observe(
                        [weak_dst_guide_rect](float const &value) {
                            if (auto const rect = weak_dst_guide_rect.lock()) {
                                rect->left()->set_value(value);
                            }
                        },
                        true)
                    ->add_to(*pool);
                src_guide_rect->bottom()
                    ->observe(
                        [weak_dst_guide_rect](float const &value) {
                            if (auto const rect = weak_dst_guide_rect.lock()) {
                                rect->bottom()->set_value(value);
                            }
                        },
                        true)
                    ->add_to(*pool);
                src_guide_rect->right()
                    ->observe(
                        [weak_dst_guide_rect](float const &value) {
                            if (auto const rect = weak_dst_guide_rect.lock()) {
                                rect->right()->set_value(value);
                            }
                        },
                        true)
                    ->add_to(*pool);
                src_guide_rect->top()
                    ->observe(
                        [weak_dst_guide_rect](float const &value) {
                            if (auto const rect = weak_dst_guide_rect.lock()) {
                                rect->top()->set_value(value);
                            }
                        },
                        true)
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

sample::soft_keyboard_ptr sample::soft_keyboard::make_shared(ui::font_atlas_ptr const &atlas) {
    return std::shared_ptr<soft_keyboard>(new soft_keyboard{atlas});
}
