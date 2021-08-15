//
//  yas_ui_detector.cpp
//

#include "yas_ui_detector.h"

using namespace yas;
using namespace yas::ui;

#pragma mark - detector

detector::detector() {
}

std::optional<std::shared_ptr<collider>> detector::detect(point const &location) const {
    for (auto const &collider : this->_colliders) {
        if (collider->hit_test(location)) {
            return collider;
        }
    }
    return std::nullopt;
}

bool detector::detect(point const &location, std::shared_ptr<collider> const &collider) const {
    if (auto detected_collider = detect(location)) {
        if (detected_collider == collider) {
            return true;
        }
    }
    return false;
}

bool detector::is_updating() {
    return this->_updating;
}

void detector::begin_update() {
    this->_updating = true;
    this->_colliders.clear();
}

void detector::push_front_collider(std::shared_ptr<collider> const &collider) {
    if (!this->_updating) {
        throw std::runtime_error("detector is not updating.");
    }

    this->_colliders.emplace_front(collider);
}

void detector::end_update() {
    this->_updating = false;
}

std::shared_ptr<detector> detector::make_shared() {
    return std::shared_ptr<detector>(new detector{});
}
