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

void ui::updatable_collision_detector::set_needs_update_colliders() {
    impl_ptr<impl>()->set_needs_update_colliders();
}

void ui::updatable_collision_detector::clear_colliders_if_needed() {
    impl_ptr<impl>()->clear_colliders_if_needed();
}

void ui::updatable_collision_detector::push_front_collider_if_needed(ui::collider collider) {
    impl_ptr<impl>()->push_front_collider_if_needed(std::move(collider));
}

void ui::updatable_collision_detector::finalize() {
    impl_ptr<impl>()->finalize();
}
