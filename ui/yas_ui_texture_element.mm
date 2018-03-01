//
//  yas_ui_texture_element.mm
//

#include "yas_ui_texture_element.h"
#include "yas_property.h"

using namespace yas;

#pragma mark - ui::teture::texture_element::impl

struct ui::texture_element::impl : base::impl {
    image_pair_t const _image_pair;
    property<std::nullptr_t, ui::uint_region> _tex_coords{{.value = ui::uint_region::zero()}};
    subject_t _subject;

    impl(image_pair_t &&pair) : _image_pair(std::move(pair)) {
    }

    void prepare(texture_element &element) {
        this->_tex_coords_observer = this->_tex_coords.subject().make_observer(
            property_method::did_change, [weak_element = to_weak(element)](auto const &context) {
                if (texture_element element = weak_element.lock()) {
                    element.impl_ptr<impl>()->_subject.notify(method::tex_coords_changed, element);
                }
            });
    }

   private:
    base _tex_coords_observer = nullptr;
};

#pragma mark - ui::texture_element

ui::texture_element::texture_element(image_pair_t &&pair) : base(std::make_shared<impl>(std::move(pair))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::texture_element::texture_element(std::nullptr_t) : base(nullptr) {
}

ui::image_pair_t const &ui::texture_element::image_pair() const {
    return impl_ptr<impl>()->_image_pair;
}

void ui::texture_element::set_tex_coords(ui::uint_region const &tex_coords) {
    impl_ptr<impl>()->_tex_coords.set_value(tex_coords);
}

ui::uint_region const &ui::texture_element::tex_coords() const {
    return impl_ptr<impl>()->_tex_coords.value();
}

ui::texture_element::subject_t &ui::texture_element::subject() {
    return impl_ptr<impl>()->_subject;
}