//
//  yas_sample_soft_keyboard_extension.mm
//

#include "yas_each_index.h"
#include "yas_sample_soft_keyboard_extension.h"
#include "yas_ui_fixed_layout.h"

using namespace yas;

namespace yas {
namespace sample {
    struct soft_key : base {
        struct impl : base::impl {
            impl(std::string &&key, float const width, ui::font_atlas &&atlas)
                : _button_ext({0.0f, 0.0f, width, width}),
                  _strings_ext({.font_atlas = std::move(atlas), .max_word_count = 1}) {
                float const half_width = roundf(width * 0.5f);

                _button_ext.rect_plane_extension().node().mesh().set_use_mesh_color(true);
                _button_ext.rect_plane_extension().data().set_rect_color(simd::float4{0.5f, 0.5f, 0.5f, 1.0f}, 0);
                _button_ext.rect_plane_extension().data().set_rect_color(
                    simd::float4{0.2f, 0.2f, 0.2f, 1.0f}, to_index({ui::button_extension::state::press}));

                _strings_ext.set_text(key);
                _strings_ext.set_pivot(ui::pivot::center);

                float const &font_size = _strings_ext.font_atlas().font_size();
                _strings_ext.rect_plane_extension().node().set_position(
                    {half_width, std::roundf(-font_size / 3.0f) + half_width});
                _button_ext.rect_plane_extension().node().push_back_sub_node(
                    _strings_ext.rect_plane_extension().node());
            }

            ui::button_extension _button_ext;
            ui::strings_extension _strings_ext;
        };

        soft_key(std::string key, float const width, ui::font_atlas atlas)
            : base(std::make_shared<impl>(std::move(key), width, std::move(atlas))) {
        }

        soft_key(std::nullptr_t) : base(nullptr) {
        }

        ui::button_extension &button_extension() {
            return impl_ptr<impl>()->_button_ext;
        }
    };
}
}

struct sample::soft_keyboard_extension::impl : base::impl {
    impl() {
        _root_node.attach_position_layout_guides(_layout_guide_point);
        _root_node.dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::soft_keyboard_extension &ext) {
        auto weak_ext = to_weak(ext);

        _renderer_observer = _root_node.subject().make_observer(
            ui::node::method::renderer_changed,
            [weak_ext, bottom_layout = base{nullptr}, left_layout = base{nullptr}](auto const &context) mutable {
                auto &node = context.value;
                if (auto keyboard_ext = weak_ext.lock()) {
                    auto keyboard_impl = keyboard_ext.impl_ptr<impl>();
                    if (auto renderer = node.renderer()) {
                        keyboard_impl->_setup_soft_keys_if_needed();

                        left_layout = ui::fixed_layout{{.distance = 0.0f,
                                                        .source_guide = renderer.view_layout_guide_rect().left(),
                                                        .destination_guide = keyboard_impl->_layout_guide_point.x()}};

                        bottom_layout = ui::fixed_layout{{.distance = 0.0f,
                                                          .source_guide = renderer.view_layout_guide_rect().bottom(),
                                                          .destination_guide = keyboard_impl->_layout_guide_point.y()}};
                    } else {
                        keyboard_impl->_dispose_soft_keys();

                        bottom_layout = nullptr;
                        left_layout = nullptr;
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
    sample::soft_keyboard_extension::subject_t _subject;

   private:
    std::vector<sample::soft_key> _soft_keys;
    ui::font_atlas _font_atlas = nullptr;
    ui::collection_layout _collection_layout = nullptr;
    ui::layout_guide_point _layout_guide_point;

    std::vector<ui::button_extension::observer_t> _soft_key_observers;
    ui::node::observer_t _renderer_observer = nullptr;
    ui::collection_layout::observer_t _collection_layout_observer;

    void _setup_soft_keys_if_needed() {
        if (_soft_keys.size() > 0 && _soft_key_observers.size() > 0 && _collection_layout &&
            _collection_layout_observer) {
            return;
        }

        if (!_font_atlas || !_root_node.renderer()) {
            return;
        }

        auto const keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9"};
        auto const key_count = keys.size();
        float const width = 36.0f;
        float const spacing = 4.0f;

        _soft_keys.reserve(key_count);
        _soft_key_observers.reserve(key_count);

        _collection_layout =
            ui::collection_layout{{.frame = {.size = {width * 3.0f + spacing * 5.0f, 0.0f}},
                                   .preferred_cell_count = key_count,
                                   .cell_sizes = {{width, width}},
                                   .row_spacing = spacing,
                                   .col_spacing = spacing,
                                   .borders = {.left = spacing, .right = spacing, .bottom = spacing, .top = spacing}}};

        for (auto const &key : keys) {
            sample::soft_key soft_key{key, width, _font_atlas};

            auto observer = soft_key.button_extension().subject().make_observer(
                ui::button_extension::method::ended,
                [weak_keyboard_ext = to_weak(cast<sample::soft_keyboard_extension>()), key](auto const &context) {
                    if (auto keyboard = weak_keyboard_ext.lock()) {
                        keyboard.impl_ptr<impl>()->_subject.notify(key, keyboard);
                    }
                });
            _soft_key_observers.emplace_back(std::move(observer));

            auto &node = soft_key.button_extension().rect_plane_extension().node();

            _root_node.push_back_sub_node(node);
            _soft_keys.emplace_back(std::move(soft_key));
        }

        _collection_layout_observer = _collection_layout.subject().make_observer(
            ui::collection_layout::method::actual_cell_count_changed,
            [weak_ext = to_weak(cast<sample::soft_keyboard_extension>())](auto const &context) {
                if (auto ext = weak_ext.lock()) {
                    ext.impl_ptr<impl>()->_update_soft_keys_position();
                }
            });

        _update_soft_keys_position();
    }

    void _dispose_soft_keys() {
        _soft_keys.clear();
        _soft_key_observers.clear();
        _collection_layout = nullptr;
        _collection_layout_observer = nullptr;
    }

    void _update_soft_keys_position() {
        auto const key_count = _soft_keys.size();

        if (key_count == 0 || !_collection_layout) {
            return;
        }

        auto const layout_count = _collection_layout.actual_cell_count();

        for (auto const &idx : make_each(key_count)) {
            auto &soft_key = _soft_keys.at(idx);

            if (idx < layout_count) {
                soft_key.button_extension().rect_plane_extension().node().set_enabled(true);

                auto &layout = _collection_layout.cell_layout_guide_rects().at(idx);
                layout.set_value_changed_handler([weak_soft_key = to_weak(soft_key)](auto const &context) {
                    if (auto soft_key = weak_soft_key.lock()) {
                        soft_key.button_extension().rect_plane_extension().node().set_position(
                            {context.new_value.origin.x, context.new_value.origin.y});
                    }
                });

                auto const region = layout.region();
                soft_key.button_extension().rect_plane_extension().node().set_position(
                    {region.origin.x, region.origin.y});
            } else {
                soft_key.button_extension().rect_plane_extension().node().set_enabled(false);
            }
        }
    }
};

sample::soft_keyboard_extension::soft_keyboard_extension() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::soft_keyboard_extension::soft_keyboard_extension(std::nullptr_t) : base(nullptr) {
}

void sample::soft_keyboard_extension::set_font_atlas(ui::font_atlas atlas) {
    impl_ptr<impl>()->set_font_atlas(std::move(atlas));
}

ui::node &sample::soft_keyboard_extension::node() {
    return impl_ptr<impl>()->_root_node;
}

sample::soft_keyboard_extension::subject_t &sample::soft_keyboard_extension::subject() {
    return impl_ptr<impl>()->_subject;
}
