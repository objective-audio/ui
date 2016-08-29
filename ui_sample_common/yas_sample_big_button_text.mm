//
//  yas_big_button_text.mm
//

#include "yas_sample_big_button_text.h"

using namespace yas;

struct sample::big_button_text::impl : base::impl {
    ui::strings_extension _strings_ext;

    impl(ui::font_atlas &&font_atlas) : _strings_ext({.font_atlas = font_atlas, .max_word_count = 32}) {
        _strings_ext.rect_plane().node().set_position(ui::point{0.0f, -7.0f});
        _strings_ext.rect_plane().node().set_alpha(0.5f);
        _strings_ext.set_pivot(ui::pivot::center);
        _strings_ext.set_text("-----");
    }

    void set_status(ui::button_extension::method const status) {
        _strings_ext.set_text(to_string(status));
    }

   private:
    ui::button_extension::method _status;
};

sample::big_button_text::big_button_text(ui::font_atlas font_atlas)
    : base(std::make_shared<impl>(std::move(font_atlas))) {
}

sample::big_button_text::big_button_text(std::nullptr_t) : base(nullptr) {
}

void sample::big_button_text::set_status(ui::button_extension::method const status) {
    impl_ptr<impl>()->set_status(status);
}

ui::strings_extension &sample::big_button_text::strings_extension() {
    return impl_ptr<impl>()->_strings_ext;
}
