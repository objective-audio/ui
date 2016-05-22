//
//  yas_button_status_node.mm
//

#include "yas_sample_button_node.h"
#include "yas_sample_button_status_node.h"

using namespace yas;

struct sample::button_status_node::impl : base::impl {
    ui::strings_node strings_node;

    impl(ui::font_atlas &&font_atlas) : strings_node({.font_atlas = font_atlas, .max_word_count = 32}) {
        strings_node.square_node().node().set_position(ui::point{0.0f, -7.0f});
        strings_node.square_node().node().set_alpha(0.5f);
        strings_node.set_pivot(ui::pivot::center);
        strings_node.set_text("-----");
    }

    void set_status(sample::button_method const status) {
        strings_node.set_text(to_string(status));
    }

   private:
    sample::button_method _status;
};

sample::button_status_node::button_status_node(ui::font_atlas font_atlas)
    : base(std::make_shared<impl>(std::move(font_atlas))) {
}

sample::button_status_node::button_status_node(std::nullptr_t) : base(nullptr) {
}

void sample::button_status_node::set_status(sample::button_method const status) {
    impl_ptr<impl>()->set_status(status);
}

ui::strings_node &sample::button_status_node::strings_node() {
    return impl_ptr<impl>()->strings_node;
}
