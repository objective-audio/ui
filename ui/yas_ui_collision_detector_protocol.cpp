//
//  yas_ui_collision_detector_protocol.cpp
//

#include "yas_ui_collider.h"
#include "yas_ui_collision_detector_protocol.h"

using namespace yas;

#pragma mark - ui::updatable_collision_detector

ui::updatable_collision_detector::updatable_collision_detector(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::updatable_collision_detector::updatable_collision_detector(std::nullptr_t) : protocol(nullptr) {
}

bool ui::updatable_collision_detector::is_updating() {
    return impl_ptr<impl>()->is_updating();
}

void ui::updatable_collision_detector::begin_update() {
    impl_ptr<impl>()->begin_update();
}

void ui::updatable_collision_detector::push_front_collider(ui::collider collider) {
    impl_ptr<impl>()->push_front_collider(std::move(collider));
}

void ui::updatable_collision_detector::end_update() {
    impl_ptr<impl>()->end_update();
}
