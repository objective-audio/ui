//
//  yas_sample_text_node.mm
//

#include "yas_sample_text_node.h"

using namespace yas;

struct sample::text_node::impl : base::impl {
    ui::strings_node strings_node;

    impl(ui::font_atlas &&font_atlas) : strings_node({.font_atlas = std::move(font_atlas), .max_word_count = 512}) {
        strings_node.set_pivot(ui::pivot::left);
    }

    void setup_renderer_observer() {
        auto &node = strings_node.square_node().node();

        node.dispatch_method(ui::node::method::renderer_changed);

        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_text_node = to_weak(cast<text_node>()),
            event_observer = base{nullptr},
            view_size_observer = base{nullptr}
        ](auto const &context) mutable {
            if (auto text_node = weak_text_node.lock()) {
                auto &node = context.value;
                if (auto renderer = node.renderer()) {
                    event_observer = renderer.event_manager().subject().make_observer(
                        ui::event_manager::method::key_changed, [weak_text_node](auto const &context) {
                            if (auto text_node = weak_text_node.lock()) {
                                text_node.impl_ptr<text_node::impl>()->update_text(context.value);
                            }
                        });

                    view_size_observer = renderer.subject().make_observer(
                        ui::renderer::method::view_size_changed, [weak_text_node](auto const &context) {
                            if (auto text_node = weak_text_node.lock()) {
                                auto const &renderer = context.value;
                                text_node.impl_ptr<text_node::impl>()->set_text_position(renderer.view_size());
                            }
                        });

                    text_node.impl_ptr<text_node::impl>()->set_text_position(renderer.view_size());
                } else {
                    event_observer = nullptr;
                    view_size_observer = nullptr;
                }
            }
        });
    }

    void update_text(ui::event const &event) {
        if (event.phase() == ui::event_phase::began || event.phase() == ui::event_phase::changed) {
            auto const key_code = event.get<ui::key>().key_code();

            switch (key_code) {
                case 51: {
                    auto &text = strings_node.text();
                    if (text.size() > 0) {
                        strings_node.set_text(text.substr(0, text.size() - 1));
                    }
                } break;

                default: { strings_node.set_text(strings_node.text() + event.get<ui::key>().characters()); } break;
            }
        }
    }

    void set_text_position(ui::uint_size const &view_size) {
        auto &node = strings_node.square_node().node();
        node.set_position(
            {static_cast<float>(view_size.width) * -0.5f, static_cast<float>(view_size.height) * 0.5f - 22.0f});
    }

   private:
    base _renderer_observer = nullptr;
};

sample::text_node::text_node(ui::font_atlas font_atlas) : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::text_node::text_node(std::nullptr_t) : base(nullptr) {
}

ui::strings_node &sample::text_node::strings_node() {
    return impl_ptr<impl>()->strings_node;
}
