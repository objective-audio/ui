//
//  yas_ui_collision_detector.cpp
//

#include <deque>
#include "yas_ui_collider.h"
#include "yas_ui_collision_detector.h"

using namespace yas;

#pragma mark - ui::collision_detector::impl

struct ui::collision_detector::impl : base::impl, updatable_collision_detector::impl {
    impl() {
        _updating = true;
    }

    bool is_updating() override {
        return _updating;
    }

    void begin_update() override {
        _updating = true;
        _colliders.clear();
    }

    void push_front_collider(ui::collider &&collider) override {
        if (!_updating) {
            throw "collision_detector is not updating.";
        }

        _colliders.emplace_front(std::move(collider));
    }

    void end_update() override {
        _updating = false;
    }

    ui::collider detect(ui::point const &location) {
        for (auto const &collider : _colliders) {
            if (collider.hit_test(location)) {
                return collider;
            }
        }
        return nullptr;
    }

    bool detect(ui::point const &location, ui::collider const &collider) {
        if (auto detected_collider = detect(location)) {
            if (detected_collider == collider) {
                return true;
            }
        }
        return false;
    }

   private:
    std::deque<ui::collider> _colliders;
    bool _updating = false;
};

#pragma mark - ui::collision_detector

ui::collision_detector::collision_detector() : base(std::make_shared<impl>()) {
}

ui::collision_detector::collision_detector(std::nullptr_t) : base(nullptr) {
}

ui::collider ui::collision_detector::detect(ui::point const &location) const {
    return impl_ptr<impl>()->detect(location);
}

bool ui::collision_detector::detect(ui::point const &location, ui::collider const &collider) const {
    return impl_ptr<impl>()->detect(location, collider);
}

ui::updatable_collision_detector &ui::collision_detector::updatable() {
    if (!_updatable) {
        _updatable = ui::updatable_collision_detector{impl_ptr<ui::updatable_collision_detector::impl>()};
    }
    return _updatable;
}
