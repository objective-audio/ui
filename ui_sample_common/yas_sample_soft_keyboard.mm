//
//  yas_sample_soft_keyboard.mm
//

#include "yas_sample_soft_keyboard.h"

using namespace yas;

namespace yas {
namespace sample {
    struct soft_key : base {
        struct impl : base::impl {
            impl(std::string &&key, float const width, ui::font_atlas &&atlas)
                : _button({0.0f, 0.0f, width, width}), _strings({.font_atlas = std::move(atlas), .max_word_count = 1}) {
                float const half_width = roundf(width * 0.5f);

                _button.rect_plane().node().mesh().set_use_mesh_color(true);
                _button.rect_plane().data().set_rect_color(simd::float4{0.5f, 0.5f, 0.5f, 1.0f}, 0);
                _button.rect_plane().data().set_rect_color(simd::float4{0.2f, 0.2f, 0.2f, 1.0f},
                                                           to_index({ui::button::state::press}));

                _strings.set_text(key);
                _strings.set_pivot(ui::pivot::center);

                float const font_size = _strings.font_atlas().font_size();
                _strings.rect_plane().node().set_position({half_width, std::roundf(-font_size / 3.0f) + half_width});
                _button.rect_plane().node().push_back_sub_node(_strings.rect_plane().node());
            }

            ui::button _button;
            ui::strings _strings;
        };

        soft_key(std::string key, float const width, ui::font_atlas atlas)
            : base(std::make_shared<impl>(std::move(key), width, std::move(atlas))) {
        }

        ui::button &button() {
            return impl_ptr<impl>()->_button;
        }
    };
}
}

struct sample::soft_keyboard::impl : base::impl {
    void setup_renderer_observer() {
        _root_node.dispatch_method(ui::node::method::renderer_changed);

        _renderer_observer = _root_node.subject().make_observer(
            ui::node::method::renderer_changed,
            [weak_keyboard = to_weak(cast<soft_keyboard>()),
             view_size_observer = base{nullptr}](auto const &context) mutable {
                auto &node = context.value;
                if (auto renderer = node.renderer()) {
                    view_size_observer = renderer.subject().make_observer(
                        ui::renderer::method::view_size_changed, [weak_keyboard](auto const &context) {
                            if (auto keyboard = weak_keyboard.lock()) {
                                auto const &renderer = context.value;
                                keyboard.impl_ptr<impl>()->set_text_position(renderer.view_size());
                            }
                        });

                    if (auto keyboard = weak_keyboard.lock()) {
                        keyboard.impl_ptr<impl>()->set_text_position(renderer.view_size());
                    }
                } else {
                    view_size_observer = nullptr;
                }
            });
    }

    void set_font_atlas(ui::font_atlas &&atlas) {
        auto keys = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"};

        _soft_keys.reserve(keys.size());
        _soft_key_observers.reserve(keys.size());

        float x = 0.0f;
        float const width = 36.0f;

        for (auto const &key : keys) {
            sample::soft_key soft_key{key, width, atlas};

            auto observer = soft_key.button().subject().make_observer(
                ui::button::method::ended,
                [weak_keyboard = to_weak(cast<sample::soft_keyboard>()), key](auto const &context) {
                    if (auto keyboard = weak_keyboard.lock()) {
                        keyboard.impl_ptr<impl>()->_subject.notify(key, keyboard);
                    }
                });
            _soft_key_observers.emplace_back(std::move(observer));

            auto &node = soft_key.button().rect_plane().node();
            node.set_position({x, 0.0f});

            _root_node.push_back_sub_node(node);
            _soft_keys.emplace_back(std::move(soft_key));

            x += width + 4.0f;
        }
    }

    void set_text_position(ui::uint_size const &view_size) {
        _root_node.set_position(
            {static_cast<float>(view_size.width) * -0.5f, static_cast<float>(view_size.height) * -0.5f});
    }

    ui::node _root_node;
    sample::soft_keyboard::subject_t _subject;

   private:
    std::vector<sample::soft_key> _soft_keys;
    std::vector<base> _soft_key_observers;
    base _renderer_observer = nullptr;
};

sample::soft_keyboard::soft_keyboard() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->setup_renderer_observer();
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
