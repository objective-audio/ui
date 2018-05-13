//
//  yas_ui_detector_protocol.cpp
//

#include "yas_ui_detector_protocol.h"
#include "yas_ui_collider.h"

using namespace yas;

#pragma mark - ui::updatable_detector

ui::updatable_detector::updatable_detector(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::updatable_detector::updatable_detector(std::nullptr_t) : protocol(nullptr) {
}

bool ui::updatable_detector::is_updating() {
    return impl_ptr<impl>()->is_updating();
}

void ui::updatable_detector::begin_update() {
    impl_ptr<impl>()->begin_update();
}

void ui::updatable_detector::push_front_collider(ui::collider collider) {
    impl_ptr<impl>()->push_front_collider(std::move(collider));
}

void ui::updatable_detector::end_update() {
    impl_ptr<impl>()->end_update();
}
