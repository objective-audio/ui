//
//  yas_sample_text_node.mm
//

#include "yas_sample_text_node.h"

using namespace yas;

struct sample::text_node::impl : base::impl {
    ui::strings_node strings_node;

    impl(ui::font_atlas const &font_atlas) : strings_node(font_atlas, 512) {
        strings_node.set_pivot(ui::pivot::left);
    }

    void setup_renderer_observer() {
        auto &node = strings_node.square_node().node();
        node.dispatch_method(ui::node_method::renderer_changed);
        _renderer_observer = node.subject().make_observer(ui::node_method::renderer_changed, [
            weak_text_node = to_weak(cast<text_node>()),
            event_observer = base{nullptr},
            view_size_observer = base{nullptr}
        ](auto const &context) mutable {
            if (auto text_node = weak_text_node.lock()) {
                auto impl = text_node.impl_ptr<text_node::impl>();
                auto node = context.value;
                if (auto renderer = node.renderer()) {
                    event_observer = impl::_make_event_observer(impl->strings_node, renderer.event_manager());
                    view_size_observer =
                        impl::_make_view_size_observer(impl->strings_node.square_node().node(), renderer);
                } else {
                    event_observer = nullptr;
                    view_size_observer = nullptr;
                }
            }
        });
    }

   private:
    static base _make_event_observer(ui::strings_node &str_node, ui::event_manager &event_manager) {
        return event_manager.subject().make_observer(
            ui::event_method::key_changed, [weak_str_node = to_weak(str_node)](auto const &context) {
                ui::event const &event = context.value;
                if (auto result = where(weak_str_node.lock(), event.phase() == ui::event_phase::began ||
                                                                  event.phase() == ui::event_phase::changed)) {
                    auto &str_node = std::get<0>(result.value());
                    auto const key_code = event.get<ui::key>().key_code();

                    switch (key_code) {
                        case 51: {
                            auto &text = str_node.text();
                            if (text.size() > 0) {
                                str_node.set_text(text.substr(0, text.size() - 1));
                            }
                        } break;

                        default: { str_node.set_text(str_node.text() + event.get<ui::key>().characters()); } break;
                    }
                }
            });
    }

    static base _make_view_size_observer(ui::node &node, ui::renderer &renderer) {
        auto set_text_pos = [](ui::node &node, ui::uint_size const &view_size) {
            node.set_position(
                {static_cast<float>(view_size.width) * -0.5f, static_cast<float>(view_size.height) * 0.5f - 22.0f});
        };

        set_text_pos(node, renderer.view_size());

        return renderer.subject().make_observer(
            ui::renderer_method::view_size_changed,
            [weak_node = to_weak(node), set_text_pos = std::move(set_text_pos)](auto const &context) {
                if (auto node = weak_node.lock()) {
                    auto const &renderer = context.value;
                    set_text_pos(node, renderer.view_size());
                }
            });
    }

    base _renderer_observer = nullptr;
};

sample::text_node::text_node(ui::font_atlas const &font_atlas) : base(std::make_shared<impl>(font_atlas)) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::text_node::text_node(std::nullptr_t) : base(nullptr) {
}

ui::strings_node &sample::text_node::strings_node() {
    return impl_ptr<impl>()->strings_node;
}
