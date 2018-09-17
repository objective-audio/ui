//
//  yas_sample_soft_keyboard.mm
//

#include "yas_sample_soft_keyboard.h"
#include <limits>
#include "yas_chaining_utils.h"
#include "yas_fast_each.h"
#include "yas_stl_utils.h"

using namespace yas;

namespace yas::sample {
struct soft_key : base {
    struct impl : base::impl {
        impl(std::string &&key, float const width, ui::font_atlas &&atlas)
            : _button({.size = {width, width}}), _strings({.font_atlas = std::move(atlas), .max_word_count = 1}) {
            this->_button.rect_plane().node().mesh().value().set_use_mesh_color(true);
            this->_button.rect_plane().data().set_rect_color(simd::float4{0.5f, 0.5f, 0.5f, 1.0f}, 0);
            this->_button.rect_plane().data().set_rect_color(simd::float4{0.2f, 0.2f, 0.2f, 1.0f}, 1);

            this->_strings.set_text(key);
            this->_strings.set_alignment(ui::layout_alignment::mid);

            this->_button.rect_plane().node().add_sub_node(this->_strings.rect_plane().node());

            auto const &font_atlas = this->_strings.font_atlas();
            float const strings_offset_y = std::roundf((width + font_atlas.ascent() + font_atlas.descent()) * 0.5f);

            this->_strings.frame_layout_guide_rect().set_region(
                {.origin = {.y = strings_offset_y}, .size = {.width = width}});
        }

        ui::button _button;
        ui::strings _strings;
    };

    soft_key(std::string key, float const width, ui::font_atlas atlas)
        : base(std::make_shared<impl>(std::move(key), width, std::move(atlas))) {
    }

    soft_key(std::nullptr_t) : base(nullptr) {
    }

    ui::button &button() {
        return impl_ptr<impl>()->_button;
    }

    ui::strings const &strings() const {
        return impl_ptr<impl>()->_strings;
    }

    void set_enabled(bool const enabled, bool const animated = false) {
        auto &button_node = button().rect_plane().node();
        auto &strings_node = impl_ptr<impl>()->_strings.rect_plane().node();
        auto renderer = button_node.renderer();

        button_node.collider().value().set_enabled(enabled);

        float const alpha = enabled ? 1.0f : 0.0f;

        renderer.erase_action(button_node);
        renderer.erase_action(strings_node);

        if (animated) {
            renderer.insert_action(ui::make_action(
                {.target = button_node, .begin_alpha = button_node.alpha().value(), .end_alpha = alpha}));
            renderer.insert_action(ui::make_action(
                {.target = strings_node, .begin_alpha = strings_node.alpha().value(), .end_alpha = alpha}));
        } else {
            button_node.alpha().set_value(alpha);
            strings_node.alpha().set_value(alpha);
        }
    }
};
}

struct sample::soft_keyboard::impl : base::impl {
    impl(ui::font_atlas &&atlas) : _font_atlas(std::move(atlas)) {
    }

    void prepare(sample::soft_keyboard &keyboard) {
        auto weak_keyboard = to_weak(keyboard);

        this->_renderer_observer = this->_root_node.chain_renderer()
                                       .guard([weak_keyboard](auto const &) { return !!weak_keyboard; })
                                       .perform([weak_keyboard](ui::renderer const &renderer) {
                                           auto keyboard_impl = weak_keyboard.lock().impl_ptr<impl>();
                                           if (renderer) {
                                               keyboard_impl->_setup_soft_keys_if_needed();
                                           } else {
                                               keyboard_impl->_dispose_soft_keys();
                                           }
                                       })
                                       .sync();
    }

    void set_font_atlas(ui::font_atlas &&atlas) {
        if (this->_font_atlas != atlas) {
            this->_font_atlas = std::move(atlas);

            this->_setup_soft_keys_if_needed();
        }
    }

    ui::node _root_node;
    chaining::notifier<std::string> _key_sender;

   private:
    std::vector<sample::soft_key> _soft_keys;
    ui::font_atlas _font_atlas = nullptr;

    ui::collection_layout _collection_layout = nullptr;
    std::vector<chaining::any_observer> _frame_layouts;

    std::vector<chaining::any_observer> _soft_key_observers;
    chaining::any_observer _renderer_observer = nullptr;
    chaining::any_observer _actual_cell_count_observer = nullptr;
    ui::layout_animator _cell_interporator = nullptr;
    std::vector<ui::layout_guide_rect> _src_cell_guide_rects;
    std::vector<ui::layout_guide_rect> _dst_cell_guide_rects;
    std::vector<std::vector<chaining::any_observer>> _fixed_cell_layouts;
    std::vector<chaining::any_observer> _dst_rect_observers;

    void _setup_soft_keys_if_needed() {
        if (this->_soft_keys.size() > 0 && this->_soft_key_observers.size() > 0 && this->_collection_layout &&
            this->_frame_layouts.size() > 0 && this->_actual_cell_count_observer) {
            return;
        }

        if (!this->_font_atlas || !this->_root_node.renderer()) {
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
        this->_soft_key_observers.reserve(key_count);

        this->_collection_layout =
            ui::collection_layout{{.frame = {.size = {width, 0.0f}},
                                   .preferred_cell_count = key_count,
                                   .lines = {{.cell_sizes = cell_sizes}},
                                   .row_spacing = spacing,
                                   .col_spacing = spacing,
                                   .borders = {.left = spacing, .right = spacing, .bottom = spacing, .top = spacing}}};

        for (auto const &key : keys) {
            sample::soft_key soft_key{key, key_width, this->_font_atlas};

            chaining::any_observer observer =
                soft_key.button()
                    .chain(ui::button::method::ended)
                    .perform([weak_keyboard = to_weak(cast<sample::soft_keyboard>()), key](auto const &context) {
                        if (auto keyboard = weak_keyboard.lock()) {
                            keyboard.impl_ptr<impl>()->_key_sender.notify(key);
                        }
                    })
                    .end();

            this->_soft_key_observers.emplace_back(std::move(observer));

            auto &node = soft_key.button().rect_plane().node();

            this->_root_node.add_sub_node(node);
            this->_soft_keys.emplace_back(std::move(soft_key));
        }

        this->_actual_cell_count_observer =
            this->_collection_layout.chain_actual_cell_count()
                .perform([weak_keyboard = to_weak(cast<sample::soft_keyboard>())](auto const &) {
                    if (auto keyboard = weak_keyboard.lock()) {
                        keyboard.impl_ptr<impl>()->_update_soft_keys_enabled(true);
                        keyboard.impl_ptr<impl>()->_update_soft_key_count();
                    }
                })
                .end();

        this->_src_cell_guide_rects.resize(key_count);
        this->_dst_cell_guide_rects.resize(key_count);
        this->_fixed_cell_layouts.reserve(key_count);

        auto renderer = this->_root_node.renderer();
        auto &safe_area_guide_rect = renderer.safe_area_layout_guide_rect();
        auto &frame_guide_rect = this->_collection_layout.frame_layout_guide_rect();

        this->_frame_layouts.emplace_back(
            safe_area_guide_rect.left().chain().receive(frame_guide_rect.left().receiver()).sync());
        this->_frame_layouts.emplace_back(
            safe_area_guide_rect.bottom().chain().receive(frame_guide_rect.bottom().receiver()).sync());
        this->_frame_layouts.emplace_back(
            safe_area_guide_rect.top().chain().receive(frame_guide_rect.top().receiver()).sync());

        ui::layout_guide max_right_guide;
        this->_frame_layouts.emplace_back(
            safe_area_guide_rect.left().chain().to(chaining::add(width)).receive(max_right_guide.receiver()).sync());
        this->_frame_layouts.emplace_back(max_right_guide.chain()
                                              .combine(safe_area_guide_rect.right().chain())
                                              .to(chaining::min<float>())
                                              .receive(frame_guide_rect.right().receiver())
                                              .sync());

        this->_setup_soft_keys_layout();
        this->_update_soft_key_count();
        this->_update_soft_keys_enabled(false);
    }

    void _dispose_soft_keys() {
        this->_soft_keys.clear();
        this->_soft_key_observers.clear();
        this->_frame_layouts.clear();
        this->_collection_layout = nullptr;
        this->_actual_cell_count_observer = nullptr;
        this->_src_cell_guide_rects.clear();
        this->_dst_cell_guide_rects.clear();
        this->_cell_interporator = nullptr;
        this->_dst_rect_observers.clear();
    }

    void _setup_soft_keys_layout() {
        auto const key_count = this->_soft_keys.size();

        if (key_count == 0 || !this->_collection_layout) {
            return;
        }

        if (this->_cell_interporator) {
            return;
        }

        std::vector<ui::layout_guide_pair> guide_pairs;
        guide_pairs.reserve(key_count * 4);

        auto handler = [](sample::soft_key &soft_key, ui::region const &region) {
            soft_key.button().rect_plane().node().position().set_value({region.origin.x, region.origin.y});
            soft_key.button().layout_guide_rect().set_region({.size = region.size});
        };

        auto each = make_fast_each(key_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto &soft_key = this->_soft_keys.at(idx);
            auto &dst_guide_rect = this->_dst_cell_guide_rects.at(idx);

            auto weak_soft_key = to_weak(soft_key);

            this->_dst_rect_observers.emplace_back(
                dst_guide_rect.chain()
                    .guard([weak_soft_key](ui::region const &) { return !!weak_soft_key; })
                    .perform([weak_soft_key, handler](ui::region const &value) {
                        auto soft_key = weak_soft_key.lock();
                        handler(soft_key, value);
                    })
                    .end());

            yas::move_back_insert(guide_pairs,
                                  ui::make_layout_guide_pairs(
                                      {.source = this->_src_cell_guide_rects.at(idx), .destination = dst_guide_rect}));
        }

        this->_cell_interporator = ui::layout_animator{
            {.renderer = this->_root_node.renderer(), .layout_guide_pairs = std::move(guide_pairs), .duration = 0.3f}};
    }

    void _update_soft_key_count() {
        auto const key_count = this->_soft_keys.size();

        if (key_count == 0 || !this->_collection_layout) {
            return;
        }

        if (!this->_cell_interporator) {
            return;
        }

        auto const layout_count = this->_collection_layout.actual_cell_count();

        auto each = make_fast_each(key_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            if (idx < layout_count) {
                if (idx >= this->_fixed_cell_layouts.size()) {
                    auto &src_guide_rect = this->_collection_layout.cell_layout_guide_rects().at(idx);
                    auto &dst_guide_rect = this->_src_cell_guide_rects.at(idx);

                    std::vector<chaining::any_observer> layouts;
                    layouts.reserve(4);

                    layouts.emplace_back(
                        src_guide_rect.left().chain().receive(dst_guide_rect.left().receiver()).sync());
                    layouts.emplace_back(
                        src_guide_rect.bottom().chain().receive(dst_guide_rect.bottom().receiver()).sync());
                    layouts.emplace_back(
                        src_guide_rect.right().chain().receive(dst_guide_rect.right().receiver()).sync());
                    layouts.emplace_back(src_guide_rect.top().chain().receive(dst_guide_rect.top().receiver()).sync());

                    this->_fixed_cell_layouts.emplace_back(std::move(layouts));
                }
            } else {
                if (layout_count < this->_fixed_cell_layouts.size()) {
                    this->_fixed_cell_layouts.resize(layout_count);
                }
                break;
            }
        }
    }

    void _update_soft_keys_enabled(bool animated) {
        auto const key_count = this->_soft_keys.size();

        if (key_count == 0 || !this->_collection_layout) {
            return;
        }

        auto const layout_count = this->_collection_layout.actual_cell_count();
        auto renderer = this->_root_node.renderer();

        auto each = make_fast_each(key_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            this->_soft_keys.at(idx).set_enabled(idx < layout_count, animated);
        }
    }
};

sample::soft_keyboard::soft_keyboard(ui::font_atlas atlas) : base(std::make_shared<impl>(std::move(atlas))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::soft_keyboard::soft_keyboard(std::nullptr_t) : base(nullptr) {
}

void sample::soft_keyboard::set_font_atlas(ui::font_atlas atlas) {
    impl_ptr<impl>()->set_font_atlas(std::move(atlas));
}

ui::node &sample::soft_keyboard::node() {
    return impl_ptr<impl>()->_root_node;
}

chaining::chain<std::string, std::string, std::string, false> sample::soft_keyboard::chain() const {
    return impl_ptr<impl>()->_key_sender.chain();
}
