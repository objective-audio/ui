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
        _updates.flags.set();
    }

    void set_updated(ui::collider_update_reason const reason) override {
        _updates.set(reason);
    }

    void clear_colliders_if_needed() override {
        if (_needs_update(ui::collider_update_reason::existence)) {
            _colliders.clear();
        }
    }

    void push_front_collider_if_needed(ui::collider &&collider) override {
        if (_needs_update(ui::collider_update_reason::existence)) {
            _colliders.emplace_front(std::move(collider));
        }
    }

    void finalize() override {
        _updates.flags.reset();
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
    ui::collider_updates_t _updates;

    bool _needs_update(ui::collider_update_reason const reason) {
        return _updates.test(reason);
    }
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
