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
        this->_strings.rect_plane().node().alpha().set_value(0.5f);
    }

    void prepare(sample::big_button_text &text) {
        this->_strings_flow = text.strings()
                                  .begin_font_atlas_flow()
                                  .perform([weak_text = to_weak(text)](ui::font_atlas const &) {
                                      if (auto text = weak_text.lock()) {
                                          text.impl_ptr<impl>()->_update_strings_position();
                                      }
                                  })
                                  .sync();
    }

    void set_status(ui::button::method const status) {
        this->_strings.set_text(to_string(status));
    }

   private:
    ui::button::method _status;
    flow::observer _strings_flow = nullptr;

    void _update_strings_position() {
        if (auto const &atlas = this->_strings.font_atlas()) {
            float const offset_y = (atlas.ascent() + atlas.descent()) * 0.5f;
            this->_strings.rect_plane().node().position().set_value(ui::point{0.0f, offset_y});
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
