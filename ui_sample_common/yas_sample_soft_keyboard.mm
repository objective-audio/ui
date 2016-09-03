//
//  yas_sample_soft_keyboard.mm
//

#include "yas_each_index.h"
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
                _button.rect_plane().data().set_rect_color(simd::float4{0.2f, 0.2f, 0.2f, 1.0f},
                                                           to_index({ui::button::state::press}));

                _strings.set_text(key);
                _strings.set_pivot(ui::pivot::center);

                _button.rect_plane().node().push_back_sub_node(_strings.rect_plane().node());

                _strings.rect_plane().node().attach_x_layout_guide(_strings_guide_point.x());
                _strings.rect_plane().node().attach_y_layout_guide(_y_offset_guide);

                float const &font_size = _strings.font_atlas().font_size();
                _layouts.emplace_back(ui::make_fixed_layout({.distance = std::roundf(-font_size / 3.0f),
                                                             .source_guide = _strings_guide_point.y(),
                                                             .destination_guide = _y_offset_guide}));

                auto const &button_guide_rect = _button.layout_guide_rect();
                _layouts.emplace_back(ui::make_justified_layout({.first_source_guide = button_guide_rect.left(),
                                                                 .second_source_guide = button_guide_rect.right(),
                                                                 .destination_guides = {_strings_guide_point.x()}}));

                _layouts.emplace_back(ui::make_justified_layout({.first_source_guide = button_guide_rect.bottom(),
                                                                 .second_source_guide = button_guide_rect.top(),
                                                                 .destination_guides = {_strings_guide_point.y()}}));
            }

            ui::button _button;
            ui::strings _strings;
            std::vector<ui::layout> _layouts;
            ui::layout_guide _y_offset_guide;
            ui::layout_guide_point _strings_guide_point;
        };

        soft_key(std::string key, float const width, ui::font_atlas atlas)
            : base(std::make_shared<impl>(std::move(key), width, std::move(atlas))) {
        }

        soft_key(std::nullptr_t) : base(nullptr) {
        }

        ui::button &button() {
            return impl_ptr<impl>()->_button;
        }
    };
}
}

struct sample::soft_keyboard::impl : base::impl {
    impl() {
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
    std::vector<ui::layout> _layouts;
    ui::layout_guide _right_min_guide;

    std::vector<ui::button::observer_t> _soft_key_observers;
    ui::node::observer_t _renderer_observer = nullptr;
    ui::collection_layout::observer_t _collection_observer;

    void _setup_soft_keys_if_needed() {
        if (_soft_keys.size() > 0 && _soft_key_observers.size() > 0 && _collection_layout && _layouts.size() > 0 &&
            _collection_observer) {
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
        for (auto const &idx : make_each(key_count)) {
            if (idx == 0) {
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
                                   .cell_sizes = std::move(cell_sizes),
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
                    keyboard.impl_ptr<impl>()->_update_soft_keys_position();
                }
            });

        auto const renderer = _root_node.renderer();
        auto const &view_guide_rect = renderer.view_layout_guide_rect();
        auto const &frame_guide_rect = _collection_layout.frame_layout_guide_rect();

        _layouts.emplace_back(ui::make_fixed_layout(
            {.source_guide = view_guide_rect.left(), .destination_guide = frame_guide_rect.left()}));

        _layouts.emplace_back(ui::make_fixed_layout(
            {.source_guide = view_guide_rect.bottom(), .destination_guide = frame_guide_rect.bottom()}));

        _layouts.emplace_back(ui::make_fixed_layout(
            {.source_guide = view_guide_rect.top(), .destination_guide = frame_guide_rect.top()}));

        _layouts.emplace_back(ui::make_fixed_layout(
            {.distance = width, .source_guide = view_guide_rect.left(), .destination_guide = _right_min_guide}));

        _layouts.emplace_back(ui::make_min_layout({.source_guides = {_right_min_guide, view_guide_rect.right()},
                                                   .destination_guide = frame_guide_rect.right()}));

        _update_soft_keys_position();
    }

    void _dispose_soft_keys() {
        _soft_keys.clear();
        _soft_key_observers.clear();
        _layouts.clear();
        _collection_layout = nullptr;
        _collection_observer = nullptr;
    }

    void _update_soft_keys_position() {
        auto const key_count = _soft_keys.size();

        if (key_count == 0 || !_collection_layout) {
            return;
        }

        auto const layout_count = _collection_layout.actual_cell_count();

        auto handler = [](sample::soft_key &soft_key, ui::region const &region) {
            soft_key.button().rect_plane().node().set_position({region.origin.x, region.origin.y});
            soft_key.button().layout_guide_rect().set_region({.size = region.size});
        };

        for (auto const &idx : make_each(key_count)) {
            auto &soft_key = _soft_keys.at(idx);

            if (idx < layout_count) {
                soft_key.button().rect_plane().node().set_enabled(true);

                auto &layout = _collection_layout.cell_layout_guide_rects().at(idx);
                layout.set_value_changed_handler([weak_soft_key = to_weak(soft_key), handler](auto const &context) {
                    if (auto soft_key = weak_soft_key.lock()) {
                        handler(soft_key, context.new_value);
                    }
                });

                handler(soft_key, layout.region());
            } else {
                soft_key.button().rect_plane().node().set_enabled(false);
            }
        }
    }
};

sample::soft_keyboard::soft_keyboard() : base(std::make_shared<impl>()) {
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
