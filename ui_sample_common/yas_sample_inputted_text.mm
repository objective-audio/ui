//
//  yas_sample_inputted_text.mm
//

#include "yas_sample_inputted_text.h"

using namespace yas;

struct sample::inputted_text::impl : base::impl {
    ui::strings _strings;

    impl(ui::font_atlas &&font_atlas)
        : _strings(
              {.font_atlas = std::move(font_atlas), .max_word_count = 512, .alignment = ui::layout_alignment::min}) {
    }

    void prepare(sample::inputted_text &text) {
        auto &node = this->_strings.rect_plane().node();

        this->_renderer_observer = node.dispatch_and_make_observer(
            ui::node::method::renderer_changed, [weak_text = to_weak(text), event_observer = base{nullptr},
                                                 layout = flow::observer<float>{nullptr}](auto const &context) mutable {
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

                        layout = ui::make_flow({.distances = ui::insets{4.0f, -4.0f, 4.0f, -4.0f},
                                                .source_guide_rect = renderer.safe_area_layout_guide_rect(),
                                                .destination_guide_rect = strings_frame_guide_rect});
                    } else {
                        event_observer = nullptr;
                        layout = nullptr;
                    }
                }
            });
    }

    void update_text(ui::event const &event) {
        if (event.phase() == ui::event_phase::began || event.phase() == ui::event_phase::changed) {
            auto const key_code = event.get<ui::key>().key_code();

            switch (key_code) {
                case 51: {  // delete key
                    auto &text = this->_strings.text();
                    if (text.size() > 0) {
                        this->_strings.set_text(text.substr(0, text.size() - 1));
                    }
                } break;

                default: { append_text(event.get<ui::key>().characters()); } break;
            }
        }
    }

    void append_text(std::string text) {
        this->_strings.set_text(this->_strings.text() + text);
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

ui::strings &sample::inputted_text::strings() {
    return impl_ptr<impl>()->_strings;
}
