//
//  yas_sample_soft_keyboard.mm
//

#include <limits>
#include "yas_fast_each.h"
#include "yas_sample_soft_keyboard.h"

using namespace yas;

namespace yas {
namespace sample {
    struct soft_key : base {
        struct impl : base::impl {
            impl(std::string &&key, float const width, ui::font_atlas &&atlas)
                : _button({.size = {width, width}}), _strings({.font_atlas = std::move(atlas), .max_word_count = 1}) {
                _button.rect_plane().node().mesh().set_use_mesh_color(true);
                _button.rect_plane().data().set_rect_color(simd::float4{0.5f, 0.5f, 0.5f, 1.0f}, 0);
                _button.rect_plane().data().set_rect_color(simd::float4{0.2f, 0.2f, 0.2f, 1.0f}, 1);

                _strings.set_text(key);
                _strings.set_alignment(ui::layout_alignment::mid);

                _button.rect_plane().node().push_back_sub_node(_strings.rect_plane().node());

                auto const &font_atlas = _strings.font_atlas();
                float const strings_offset_y = std::roundf((width + font_atlas.ascent() + font_atlas.descent()) * 0.5f);

                _strings.frame_layout_guide_rect().set_region(
                    {.origin = {.y = strings_offset_y}, .size = {.width = width}});
            }

            ui::button _button;
            ui::strings _strings;
            std::vector<ui::layout> _layouts;
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

            button_node.collider().set_enabled(enabled);

            float const alpha = enabled ? 1.0f : 0.0f;

            renderer.erase_action(button_node);
            renderer.erase_action(strings_node);

            if (animated) {
                renderer.insert_action(
                    ui::make_action({.target = button_node, .start_alpha = button_node.alpha(), .end_alpha = alpha}));
                renderer.insert_action(
                    ui::make_action({.target = strings_node, .start_alpha = strings_node.alpha(), .end_alpha = alpha}));
            } else {
                button_node.set_alpha(alpha);
                strings_node.set_alpha(alpha);
            }
        }
    };
}
}

struct sample::soft_keyboard::impl : base::impl {
    impl(ui::font_atlas &&atlas) : _font_atlas(std::move(atlas)) {
        _root_node.dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::soft_keyboard &keyboard) {
        auto weak_keyboard = to_weak(keyboard);

        _renderer_observer = _root_node.subject().make_observer(ui::node::method::renderer_changed,
                                                                [weak_keyboard](auto const &context) mutable {
                                                                    auto &node = context.value;
                                                                    if (auto keyboard = weak_keyboard.lock()) {
                                                                        auto keyboard_impl = keyboard.impl_ptr<impl>();
                                                                        if (auto renderer = node.renderer()) {
                                                                            keyboard_impl->_setup_soft_keys_if_needed();
                                                                        } else {
                                                                            keyboard_impl->_dispose_soft_keys();
                                                                        }
                                                                    }
                                                                });

        _setup_soft_keys_if_needed();
    }

    void set_font_atlas(ui::font_atlas &&atlas) {
        if (_font_atlas != atlas) {
            _font_atlas = std::move(atlas);

            _setup_soft_keys_if_needed();
        }
    }

    ui::node _root_node;
    sample::soft_keyboard::subject_t _subject;

   private:
    std::vector<sample::soft_key> _soft_keys;
    ui::font_atlas _font_atlas = nullptr;

    ui::collection_layout _collection_layout = nullptr;
    std::vector<ui::layout> _frame_layouts;

    std::vector<ui::button::observer_t> _soft_key_observers;
    ui::node::observer_t _renderer_observer = nullptr;
    ui::collection_layout::observer_t _collection_observer;
    ui::layout_animator _cell_interporator = nullptr;
    std::vector<ui::layout_guide_rect> _src_cell_guide_rects;
    std::vector<ui::layout_guide_rect> _dst_cell_guide_rects;
    std::vector<std::vector<ui::layout>> _fixed_cell_layouts;

    void _setup_soft_keys_if_needed() {
        if (_soft_keys.size() > 0 && _soft_key_observers.size() > 0 && _collection_layout &&
            _frame_layouts.size() > 0 && _collection_observer) {
            return;
        }

        if (!_font_atlas || !_root_node.renderer()) {
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

        _soft_keys.reserve(key_count);
        _soft_key_observers.reserve(key_count);

        _collection_layout =
            ui::collection_layout{{.frame = {.size = {width, 0.0f}},
                                   .preferred_cell_count = key_count,
                                   .lines = {{.cell_sizes = cell_sizes}},
                                   .row_spacing = spacing,
                                   .col_spacing = spacing,
                                   .borders = {.left = spacing, .right = spacing, .bottom = spacing, .top = spacing}}};

        for (auto const &key : keys) {
            sample::soft_key soft_key{key, key_width, _font_atlas};

            auto observer = soft_key.button().subject().make_observer(
                ui::button::method::ended,
                [weak_keyboard = to_weak(cast<sample::soft_keyboard>()), key](auto const &context) {
                    if (auto keyboard = weak_keyboard.lock()) {
                        keyboard.impl_ptr<impl>()->_subject.notify(key, keyboard);
                    }
                });
            _soft_key_observers.emplace_back(std::move(observer));

            auto &node = soft_key.button().rect_plane().node();

            _root_node.push_back_sub_node(node);
            _soft_keys.emplace_back(std::move(soft_key));
        }

        _collection_observer = _collection_layout.subject().make_observer(
            ui::collection_layout::method::actual_cell_count_changed,
            [weak_keyboard = to_weak(cast<sample::soft_keyboard>())](auto const &context) {
                if (auto keyboard = weak_keyboard.lock()) {
                    keyboard.impl_ptr<impl>()->_update_soft_keys_enabled(true);
                    keyboard.impl_ptr<impl>()->_udpate_soft_key_count();
                }
            });

        _src_cell_guide_rects.resize(key_count);
        _dst_cell_guide_rects.resize(key_count);
        _fixed_cell_layouts.reserve(key_count);

        auto renderer = _root_node.renderer();
        auto &view_guide_rect = renderer.view_layout_guide_rect();
        auto const &frame_guide_rect = _collection_layout.frame_layout_guide_rect();

        _frame_layouts.emplace_back(
            ui::make_layout({.source_guide = view_guide_rect.left(), .destination_guide = frame_guide_rect.left()}));

        _frame_layouts.emplace_back(ui::make_layout(
            {.source_guide = view_guide_rect.bottom(), .destination_guide = frame_guide_rect.bottom()}));

        _frame_layouts.emplace_back(
            ui::make_layout({.source_guide = view_guide_rect.top(), .destination_guide = frame_guide_rect.top()}));

        ui::layout_guide max_right_guide;
        _frame_layouts.emplace_back(ui::make_layout(
            {.distance = width, .source_guide = view_guide_rect.left(), .destination_guide = max_right_guide}));
        _frame_layouts.emplace_back(
            ui::make_layout(ui::min_layout::args{.source_guides = {max_right_guide, view_guide_rect.right()},
                                                 .destination_guide = frame_guide_rect.right()}));

        _setup_soft_keys_layout();
        _udpate_soft_key_count();
        _update_soft_keys_enabled(false);
    }

    void _dispose_soft_keys() {
        _soft_keys.clear();
        _soft_key_observers.clear();
        _frame_layouts.clear();
        _collection_layout = nullptr;
        _collection_observer = nullptr;
        _src_cell_guide_rects.clear();
        _dst_cell_guide_rects.clear();
        _cell_interporator = nullptr;
    }

    void _setup_soft_keys_layout() {
        auto const key_count = _soft_keys.size();

        if (key_count == 0 || !_collection_layout) {
            return;
        }

        if (_cell_interporator) {
            return;
        }

        std::vector<ui::layout_guide_pair> guide_pairs;
        guide_pairs.reserve(key_count * 4);

        auto handler = [](sample::soft_key &soft_key, ui::region const &region) {
            soft_key.button().rect_plane().node().set_position({region.origin.x, region.origin.y});
            soft_key.button().layout_guide_rect().set_region({.size = region.size});
        };

        auto each = make_fast_each(key_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto &soft_key = _soft_keys.at(idx);
            auto &dst_guide_rect = _dst_cell_guide_rects.at(idx);

            dst_guide_rect.set_value_changed_handler([weak_soft_key = to_weak(soft_key), handler](auto const &context) {
                if (auto soft_key = weak_soft_key.lock()) {
                    handler(soft_key, context.new_value);
                }
            });

            yas::move_back_insert(guide_pairs, ui::make_layout_guide_pairs({.source = _src_cell_guide_rects.at(idx),
                                                                            .destination = dst_guide_rect}));
        }

        _cell_interporator = ui::layout_animator{
            {.renderer = _root_node.renderer(), .layout_guide_pairs = std::move(guide_pairs), .duration = 0.3f}};
    }

    void _udpate_soft_key_count() {
        auto const key_count = _soft_keys.size();

        if (key_count == 0 || !_collection_layout) {
            return;
        }

        if (!_cell_interporator) {
            return;
        }

        auto const layout_count = _collection_layout.actual_cell_count();

        auto each = make_fast_each(key_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            if (idx < layout_count) {
                if (idx >= _fixed_cell_layouts.size()) {
                    auto &src_guide_rect = _collection_layout.cell_layout_guide_rects().at(idx);
                    auto &dst_guide_rect = _src_cell_guide_rects.at(idx);

                    std::vector<ui::layout> layouts;
                    layouts.reserve(4);

                    layouts.emplace_back(ui::make_layout(
                        {.source_guide = src_guide_rect.left(), .destination_guide = dst_guide_rect.left()}));
                    layouts.emplace_back(ui::make_layout(
                        {.source_guide = src_guide_rect.bottom(), .destination_guide = dst_guide_rect.bottom()}));
                    layouts.emplace_back(ui::make_layout(
                        {.source_guide = src_guide_rect.right(), .destination_guide = dst_guide_rect.right()}));
                    layouts.emplace_back(ui::make_layout(
                        {.source_guide = src_guide_rect.top(), .destination_guide = dst_guide_rect.top()}));

                    _fixed_cell_layouts.emplace_back(std::move(layouts));
                }
            } else {
                if (layout_count < _fixed_cell_layouts.size()) {
                    _fixed_cell_layouts.resize(layout_count);
                }
                break;
            }
        }
    }

    void _update_soft_keys_enabled(bool animated) {
        auto const key_count = _soft_keys.size();

        if (key_count == 0 || !_collection_layout) {
            return;
        }

        auto const layout_count = _collection_layout.actual_cell_count();
        auto renderer = _root_node.renderer();

        auto each = make_fast_each(key_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            _soft_keys.at(idx).set_enabled(idx < layout_count, animated);
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

sample::soft_keyboard::subject_t &sample::soft_keyboard::subject() {
    return impl_ptr<impl>()->_subject;
}
