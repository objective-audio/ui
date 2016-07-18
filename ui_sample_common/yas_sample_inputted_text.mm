//
//  yas_sample_inputted_text.mm
//

#include "yas_sample_inputted_text.h"

using namespace yas;

struct sample::inputted_text::impl : base::impl {
    ui::strings _strings;

    impl(ui::font_atlas &&font_atlas) : _strings({.font_atlas = std::move(font_atlas), .max_word_count = 512}) {
        _strings.set_pivot(ui::pivot::left);
    }

    void setup_renderer_observer() {
        auto &node = _strings.rect_plane().node();

        node.dispatch_method(ui::node::method::renderer_changed);

        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_inputted_text = to_weak(cast<inputted_text>()),
            event_observer = base{nullptr},
            view_size_observer = base{nullptr}
        ](auto const &context) mutable {
            if (auto inputted_text = weak_inputted_text.lock()) {
                auto &node = context.value;
                if (auto renderer = node.renderer()) {
                    event_observer = renderer.event_manager().subject().make_observer(
                        ui::event_manager::method::key_changed, [weak_inputted_text](auto const &context) {
                            if (auto inputted_text = weak_inputted_text.lock()) {
                                inputted_text.impl_ptr<inputted_text::impl>()->update_text(context.value);
                            }
                        });

                    view_size_observer = renderer.subject().make_observer(
                        ui::renderer::method::view_size_changed, [weak_inputted_text](auto const &context) {
                            if (auto inputted_text = weak_inputted_text.lock()) {
                                auto const &renderer = context.value;
                                inputted_text.impl_ptr<inputted_text::impl>()->set_text_position(renderer.view_size());
                            }
                        });

                    inputted_text.impl_ptr<inputted_text::impl>()->set_text_position(renderer.view_size());
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
                    auto &text = _strings.text();
                    if (text.size() > 0) {
                        _strings.set_text(text.substr(0, text.size() - 1));
                    }
                } break;

                default: { append_text(event.get<ui::key>().characters()); } break;
            }
        }
    }

    void set_text_position(ui::uint_size const &view_size) {
        auto &node = _strings.rect_plane().node();
        node.set_position(
            {static_cast<float>(view_size.width) * -0.5f, static_cast<float>(view_size.height) * 0.5f - 22.0f});
    }

    void append_text(std::string text) {
        _strings.set_text(_strings.text() + text);
    }

   private:
    base _renderer_observer = nullptr;
};

sample::inputted_text::inputted_text(ui::font_atlas font_atlas) : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::inputted_text::inputted_text(std::nullptr_t) : base(nullptr) {
}

void sample::inputted_text::append_text(std::string text) {
    impl_ptr<impl>()->append_text(std::move(text));
}

ui::strings &sample::inputted_text::strings() {
    return impl_ptr<impl>()->_strings;
}
