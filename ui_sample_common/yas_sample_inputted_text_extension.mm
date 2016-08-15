//
//  yas_sample_inputted_text_extension.mm
//

#include "yas_sample_inputted_text_extension.h"

using namespace yas;

struct sample::inputted_text_extension::impl : base::impl {
    ui::strings_extension _strings_ext;

    impl(ui::font_atlas &&font_atlas) : _strings_ext({.font_atlas = std::move(font_atlas), .max_word_count = 512}) {
        _strings_ext.set_pivot(ui::pivot::left);

        auto &node = _strings_ext.rect_plane_extension().node();
        node.attach_x_layout_guide(_x_guide);
        node.attach_y_layout_guide(_y_guide);

        node.dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::inputted_text_extension &ext) {
        auto &node = _strings_ext.rect_plane_extension().node();

        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_ext = to_weak(ext),
            event_observer = base{nullptr},
            left_layout = base{nullptr},
            top_layout = base{nullptr}
        ](auto const &context) mutable {
            if (auto ext = weak_ext.lock()) {
                auto &node = context.value;
                if (auto renderer = node.renderer()) {
                    auto ext_impl = ext.impl_ptr<inputted_text_extension::impl>();

                    event_observer = renderer.event_manager().subject().make_observer(
                        ui::event_manager::method::key_changed, [weak_ext](auto const &context) {
                            if (auto ext = weak_ext.lock()) {
                                ext.impl_ptr<inputted_text_extension::impl>()->update_text(context.value);
                            }
                        });

                    left_layout = ui::fixed_layout{{.distance = 4.0f,
                                                    .source_guide = renderer.view_layout_rect().left_guide(),
                                                    .destination_guide = ext_impl->_x_guide}};
                    top_layout = ui::fixed_layout{{.distance = -22.0f,
                                                   .source_guide = renderer.view_layout_rect().top_guide(),
                                                   .destination_guide = ext_impl->_y_guide}};
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
                case 51: {
                    auto &text = _strings_ext.text();
                    if (text.size() > 0) {
                        _strings_ext.set_text(text.substr(0, text.size() - 1));
                    }
                } break;

                default: { append_text(event.get<ui::key>().characters()); } break;
            }
        }
    }

    void append_text(std::string text) {
        _strings_ext.set_text(_strings_ext.text() + text);
    }

   private:
    base _renderer_observer = nullptr;
    ui::layout_guide _x_guide;
    ui::layout_guide _y_guide;
};

sample::inputted_text_extension::inputted_text_extension(ui::font_atlas font_atlas)
    : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::inputted_text_extension::inputted_text_extension(std::nullptr_t) : base(nullptr) {
}

void sample::inputted_text_extension::append_text(std::string text) {
    impl_ptr<impl>()->append_text(std::move(text));
}

ui::strings_extension &sample::inputted_text_extension::strings_extension() {
    return impl_ptr<impl>()->_strings_ext;
}
