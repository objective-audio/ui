//
//  yas_big_button_text.mm
//

#include "yas_sample_big_button_text.h"

using namespace yas;

struct sample::big_button_text::impl : base::impl {
    ui::strings _strings;

    impl(ui::font_atlas &&font_atlas)
        : _strings({.text = "-----",
                    .alignment = ui::layout_alignment::mid,
                    .font_atlas = std::move(font_atlas),
                    .max_word_count = 32}) {
        this->_strings.rect_plane().node().set_alpha(0.5f);
    }

    void prepare(sample::big_button_text &text) {
        this->_strings_observer = text.strings().subject().make_observer(
            ui::strings::method::font_atlas_changed, [weak_text = to_weak(text)](auto const &context) {
                if (auto text = weak_text.lock()) {
                    text.impl_ptr<impl>()->_update_strings_position();
                }
            });

        this->_update_strings_position();
    }

    void set_status(ui::button::method const status) {
        this->_strings.set_text(to_string(status));
    }

   private:
    ui::button::method _status;
    ui::strings::observer_t _strings_observer = nullptr;

    void _update_strings_position() {
        if (auto const &atlas = this->_strings.font_atlas()) {
            float const offset_y = (atlas.ascent() + atlas.descent()) * 0.5f;
            this->_strings.rect_plane().node().set_position(ui::point{0.0f, offset_y});
        }
    }
};

sample::big_button_text::big_button_text(ui::font_atlas font_atlas)
    : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::big_button_text::big_button_text(std::nullptr_t) : base(nullptr) {
}

void sample::big_button_text::set_status(ui::button::method const status) {
    impl_ptr<impl>()->set_status(status);
}

ui::strings &sample::big_button_text::strings() {
    return impl_ptr<impl>()->_strings;
}
