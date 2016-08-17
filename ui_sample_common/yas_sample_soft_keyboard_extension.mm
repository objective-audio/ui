//
//  yas_sample_soft_keyboard_extension.mm
//

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

                float const font_size = _strings_ext.font_atlas().font_size();
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
        _renderer_observer = _root_node.subject().make_observer(
            ui::node::method::renderer_changed,
            [weak_keyboard_ext = to_weak(ext), bottom_layout = base{nullptr}, left_layout = base{nullptr}](
                auto const &context) mutable {
                auto &node = context.value;
                if (auto renderer = node.renderer()) {
                    if (auto keyboard_ext = weak_keyboard_ext.lock()) {
                        auto keyboard_impl = keyboard_ext.impl_ptr<impl>();

                        left_layout =
                            ui::fixed_layout{{.distance = 4.0f,
                                              .source_guide = renderer.view_layout_guide_rect().left(),
                                              .destination_guide = keyboard_impl->_layout_guide_point.x()}};

                        bottom_layout =
                            ui::fixed_layout{{.distance = 4.0f,
                                              .source_guide = renderer.view_layout_guide_rect().bottom(),
                                              .destination_guide = keyboard_impl->_layout_guide_point.y()}};
                    }
                } else {
                    bottom_layout = nullptr;
                    left_layout = nullptr;
                }
            });
    }

    void set_font_atlas(ui::font_atlas &&atlas) {
        auto keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9"};

        _soft_keys.reserve(keys.size());
        _soft_key_observers.reserve(keys.size());

        std::size_t x_idx = 0, y_idx = 0;
        std::size_t const line_count = 3;
        float const width = 36.0f;
        float const offset = width + 4.0f;

        for (auto const &key : keys) {
            sample::soft_key soft_key{key, width, atlas};

            auto observer = soft_key.button_extension().subject().make_observer(
                ui::button_extension::method::ended,
                [weak_keyboard_ext = to_weak(cast<sample::soft_keyboard_extension>()), key](auto const &context) {
                    if (auto keyboard = weak_keyboard_ext.lock()) {
                        keyboard.impl_ptr<impl>()->_subject.notify(key, keyboard);
                    }
                });
            _soft_key_observers.emplace_back(std::move(observer));

            auto &node = soft_key.button_extension().rect_plane_extension().node();
            node.set_position({(float)x_idx * offset, (float)y_idx * offset});

            _root_node.push_back_sub_node(node);
            _soft_keys.emplace_back(std::move(soft_key));

            ++x_idx;
            if (x_idx == line_count) {
                ++y_idx;
                x_idx = 0;
            }
        }
    }

    ui::node _root_node;
    sample::soft_keyboard_extension::subject_t _subject;

   private:
    std::vector<sample::soft_key> _soft_keys;
    std::vector<base> _soft_key_observers;
    base _renderer_observer = nullptr;

    ui::layout_guide_point _layout_guide_point;
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
