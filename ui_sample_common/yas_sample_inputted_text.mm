//
//  yas_sample_inputted_text.mm
//

#include "yas_sample_inputted_text.h"

using namespace yas;

struct sample::inputted_text::impl : base::impl {
    ui::dynamic_strings _strings;

    impl(ui::font_atlas &&font_atlas)
        : _strings({.frame = {.origin = {0.0f, 0.0f}, .size = {200.0f, 0.0f}},
                    .font_atlas = std::move(font_atlas),
                    .max_word_count = 512,
                    .alignment = ui::layout_alignment::min}) {
        auto &node = _strings.rect_plane().node();
        node.dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::inputted_text &text) {
        auto &node = _strings.rect_plane().node();

        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_text = to_weak(text),
            event_observer = base{nullptr},
            left_layout = ui::layout{nullptr},
            right_layout = ui::layout{nullptr},
            bottom_layout = ui::layout{nullptr},
            top_layout = ui::layout{nullptr}
        ](auto const &context) mutable {
            if (auto text = weak_text.lock()) {
                auto &node = context.value;
                if (auto renderer = node.renderer()) {
                    auto text_impl = text.impl_ptr<inputted_text::impl>();
                    auto &strings_frame_guide_rect = text_impl->_strings.frame_layout_guide_rect();

                    event_observer = renderer.event_manager().subject().make_observer(
                        ui::event_manager::method::key_changed, [weak_text](auto const &context) {
                            if (auto text = weak_text.lock()) {
                                text.impl_ptr<inputted_text::impl>()->update_text(context.value);
                            }
                        });

                    left_layout = ui::make_layout({.distance = 4.0f,
                                                   .source_guide = renderer.view_layout_guide_rect().left(),
                                                   .destination_guide = strings_frame_guide_rect.left()});
                    right_layout = ui::make_layout({.distance = -4.0f,
                                                    .source_guide = renderer.view_layout_guide_rect().right(),
                                                    .destination_guide = strings_frame_guide_rect.right()});
                    bottom_layout = ui::make_layout({.distance = 4.0f,
                                                     .source_guide = renderer.view_layout_guide_rect().bottom(),
                                                     .destination_guide = strings_frame_guide_rect.bottom()});
                    top_layout = ui::make_layout({.distance = -4.0f,
                                                  .source_guide = renderer.view_layout_guide_rect().top(),
                                                  .destination_guide = strings_frame_guide_rect.top()});

                } else {
                    event_observer = nullptr;
                    left_layout = nullptr;
                    top_layout = nullptr;
                }
            }
        });
    }

    void update_text(ui::event const &event) {
        if (event.phase() == ui::event_phase::began || event.phase() == ui::event_phase::changed) {
            auto const key_code = event.get<ui::key>().key_code();

            switch (key_code) {
                case 51: {  // delete key
                    auto &text = _strings.text();
                    if (text.size() > 0) {
                        _strings.set_text(text.substr(0, text.size() - 1));
                    }
                } break;

                default: { append_text(event.get<ui::key>().characters()); } break;
            }
        }
    }

    void append_text(std::string text) {
        _strings.set_text(_strings.text() + text);
    }

   private:
    ui::node::observer_t _renderer_observer = nullptr;
    ui::layout_guide_point _layout_guide_point;
};

sample::inputted_text::inputted_text(ui::font_atlas font_atlas) : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::inputted_text::inputted_text(std::nullptr_t) : base(nullptr) {
}

void sample::inputted_text::append_text(std::string text) {
    impl_ptr<impl>()->append_text(std::move(text));
}

ui::dynamic_strings &sample::inputted_text::strings() {
    return impl_ptr<impl>()->_strings;
}
