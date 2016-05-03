//
//  yas_ui_collision_detector.mm
//

#include <deque>
#include "yas_ui_collider.h"
#include "yas_ui_collision_detector.h"

using namespace yas;

#pragma mark - ui::updatable_collision_detector

ui::updatable_collision_detector::updatable_collision_detector(std::shared_ptr<impl> impl)
    : yas::protocol(std::move(impl)) {
}

void ui::updatable_collision_detector::clear_colliders() {
    impl_ptr<impl>()->clear_colliders();
}

void ui::updatable_collision_detector::push_front_collider(ui::collider collider) {
    impl_ptr<impl>()->push_front_collider(std::move(collider));
}

#pragma mark - ui::collision_detector::impl

struct ui::collision_detector::impl : base::impl, updatable_collision_detector::impl {
    void clear_colliders() override {
        _colliders.clear();
    }

    void push_front_collider(ui::collider &&collider) override {
        _colliders.emplace_front(collider);
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
};

#pragma mark - ui::collision_detector

ui::collision_detector::collision_detector() : base(std::make_shared<impl>()) {
}

ui::collision_detector::collision_detector(std::nullptr_t) : base(nullptr) {
}

ui::collider ui::collision_detector::detect(ui::point const &location) {
    return impl_ptr<impl>()->detect(location);
}

bool ui::collision_detector::detect(ui::point const &location, ui::collider const &collider) {
    return impl_ptr<impl>()->detect(location, collider);
}

ui::updatable_collision_detector ui::collision_detector::updatable() {
    return ui::updatable_collision_detector{impl_ptr<ui::updatable_collision_detector::impl>()};
}
