//
//  yas_ui_detector.cpp
//

#include "yas_ui_detector.h"
#include <deque>

using namespace yas;

#pragma mark - ui::detector::impl

struct ui::detector::impl {
    impl() {
        this->_updating = true;
    }

    bool is_updating() {
        return this->_updating;
    }

    void begin_update() {
        this->_updating = true;
        this->_colliders.clear();
    }

    void push_front_collider(ui::collider_ptr const &collider) {
        if (!this->_updating) {
            throw "detector is not updating.";
        }

        this->_colliders.emplace_front(collider);
    }

    void end_update() {
        this->_updating = false;
    }

    ui::collider_ptr detect(ui::point const &location) {
        for (auto const &collider : this->_colliders) {
            if (collider->hit_test(location)) {
                return collider;
            }
        }
        return nullptr;
    }

    bool detect(ui::point const &location, ui::collider_ptr const &collider) {
        if (auto detected_collider = detect(location)) {
            if (detected_collider == collider) {
                return true;
            }
        }
        return false;
    }

   private:
    std::deque<ui::collider_ptr> _colliders;
    bool _updating = false;
};

#pragma mark - ui::detector

ui::detector::detector() : _impl(std::make_unique<impl>()) {
}

ui::detector::~detector() = default;

ui::collider_ptr ui::detector::detect(ui::point const &location) const {
    return this->_impl->detect(location);
}

bool ui::detector::detect(ui::point const &location, ui::collider_ptr const &collider) const {
    return this->_impl->detect(location, collider);
}

bool ui::detector::is_updating() {
    return this->_impl->is_updating();
}

void ui::detector::begin_update() {
    this->_impl->begin_update();
}

void ui::detector::push_front_collider(ui::collider_ptr const &collider) {
    this->_impl->push_front_collider(collider);
}

void ui::detector::end_update() {
    this->_impl->end_update();
}

ui::detector_ptr ui::detector::make_shared() {
    return std::shared_ptr<detector>(new detector{});
}
