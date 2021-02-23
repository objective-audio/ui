//
//  yas_ui_detector.cpp
//

#include "yas_ui_detector.h"

using namespace yas;

#pragma mark - ui::detector

ui::detector::detector() {
}

ui::detector::~detector() = default;

std::optional<ui::collider_ptr> ui::detector::detect(ui::point const &location) const {
    for (auto const &collider : this->_colliders) {
        if (collider->hit_test(location)) {
            return collider;
        }
    }
    return std::nullopt;
}

bool ui::detector::detect(ui::point const &location, ui::collider_ptr const &collider) const {
    if (auto detected_collider = detect(location)) {
        if (detected_collider == collider) {
            return true;
        }
    }
    return false;
}

bool ui::detector::is_updating() {
    return this->_updating;
}

void ui::detector::begin_update() {
    this->_updating = true;
    this->_colliders.clear();
}

void ui::detector::push_front_collider(ui::collider_ptr const &collider) {
    if (!this->_updating) {
        throw std::runtime_error("detector is not updating.");
    }

    this->_colliders.emplace_front(collider);
}

void ui::detector::end_update() {
    this->_updating = false;
}

ui::detector_ptr ui::detector::make_shared() {
    return std::shared_ptr<detector>(new detector{});
}
