//
//  yas_button_status_node.mm
//

#include "yas_sample_button_status_node.h"

using namespace yas;

struct sample::button_status_node::impl : base::impl {
    ui::strings _strings;

    impl(ui::font_atlas &&font_atlas) : _strings({.font_atlas = font_atlas, .max_word_count = 32}) {
        _strings.rect_plane().node().set_position(ui::point{0.0f, -7.0f});
        _strings.rect_plane().node().set_alpha(0.5f);
        _strings.set_pivot(ui::pivot::center);
        _strings.set_text("-----");
    }

    void set_status(ui::button::method const status) {
        _strings.set_text(to_string(status));
    }

   private:
    ui::button::method _status;
};

sample::button_status_node::button_status_node(ui::font_atlas font_atlas)
    : base(std::make_shared<impl>(std::move(font_atlas))) {
}

sample::button_status_node::button_status_node(std::nullptr_t) : base(nullptr) {
}

void sample::button_status_node::set_status(ui::button::method const status) {
    impl_ptr<impl>()->set_status(status);
}

ui::strings &sample::button_status_node::strings() {
    return impl_ptr<impl>()->_strings;
}
