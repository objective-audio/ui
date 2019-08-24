//
//  yas_ui_detector.cpp
//

#include "yas_ui_detector.h"
#include <deque>

using namespace yas;

#pragma mark - ui::detector::impl

struct ui::detector::impl : updatable_detector::impl {
    impl() {
        this->_updating = true;
    }

    bool is_updating() override {
        return this->_updating;
    }

    void begin_update() override {
        this->_updating = true;
        this->_colliders.clear();
    }

    void push_front_collider(ui::collider_ptr &&collider) override {
        if (!this->_updating) {
            throw "detector is not updating.";
        }

        this->_colliders.emplace_front(std::move(collider));
    }

    void end_update() override {
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

ui::detector::detector() : _impl(std::make_shared<impl>()) {
}

ui::detector::~detector() = default;

ui::collider_ptr ui::detector::detect(ui::point const &location) const {
    return this->_impl->detect(location);
}

bool ui::detector::detect(ui::point const &location, ui::collider_ptr const &collider) const {
    return this->_impl->detect(location, collider);
}

ui::updatable_detector &ui::detector::updatable() {
    if (!this->_updatable) {
        this->_updatable = ui::updatable_detector{this->_impl};
    }
    return this->_updatable;
}

ui::detector_ptr ui::detector::make_shared() {
    return std::shared_ptr<detector>(new detector{});
}
