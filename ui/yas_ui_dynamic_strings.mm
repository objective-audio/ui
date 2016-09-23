//
//  yas_ui_dynamic_strings.mm
//

#include "yas_ui_dynamic_strings.h"
#include "yas_ui_dynamic_strings_layout.h"
#include "yas_ui_layout_types.h"

using namespace yas;

struct ui::dynamic_strings::impl : base::impl {
    ui::dynamic_strings_layout _strings_layout;

    impl(ui::dynamic_strings_layout::args &&args) : _strings_layout(std::move(args)) {
    }
};

ui::dynamic_strings::dynamic_strings() : dynamic_strings(ui::dynamic_strings_layout::args{}) {
}

ui::dynamic_strings::dynamic_strings(ui::dynamic_strings_layout::args args)
    : base(std::make_shared<impl>(std::move(args))) {
}

ui::dynamic_strings::dynamic_strings(std::nullptr_t) : base(nullptr) {
}

ui::dynamic_strings::~dynamic_strings() = default;

void ui::dynamic_strings::set_text(std::string text) {
    impl_ptr<impl>()->_strings_layout.set_text(std::move(text));
}

void ui::dynamic_strings::set_font_atlas(ui::font_atlas atlas) {
    impl_ptr<impl>()->_strings_layout.set_font_atlas(std::move(atlas));
}

void ui::dynamic_strings::set_line_height(float const line_height) {
    impl_ptr<impl>()->_strings_layout.set_line_height(line_height);
}

void ui::dynamic_strings::set_alignment(ui::layout_alignment const alignment) {
    impl_ptr<impl>()->_strings_layout.set_alignment(alignment);
}

std::string const &ui::dynamic_strings::text() const {
    return impl_ptr<impl>()->_strings_layout.text();
}

ui::font_atlas const &ui::dynamic_strings::font_atlas() const {
    return impl_ptr<impl>()->_strings_layout.font_atlas();
}

float ui::dynamic_strings::line_height() const {
    return impl_ptr<impl>()->_strings_layout.line_height();
}

ui::layout_alignment ui::dynamic_strings::alignment() const {
    return impl_ptr<impl>()->_strings_layout.alignment();
}

ui::layout_guide_rect &ui::dynamic_strings::frame_layout_guide_rect() {
    return impl_ptr<impl>()->_strings_layout.frame_layout_guide_rect();
}

ui::rect_plane &ui::dynamic_strings::rect_plane() {
    return impl_ptr<impl>()->_strings_layout.rect_plane();
}
