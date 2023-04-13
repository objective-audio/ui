//
//  yas_ui_button.mm
//

#include "yas_ui_button.h"
#include <cpp_utils/yas_fast_each.h>
#include <ui/yas_ui_angle.h>
#include <ui/yas_ui_collider.h>
#include <ui/yas_ui_detector.h>
#include <ui/yas_ui_event.h>
#include <ui/yas_ui_event_manager.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_node.h>
#include <ui/yas_ui_rect_plane.h>
#include <ui/yas_ui_standard.h>
#include <ui/yas_ui_texture.h>
#include <ui/yas_ui_touch_tracker.h>

using namespace yas;
using namespace yas::ui;

std::shared_ptr<button> button::make_shared(ui::region const &region, std::shared_ptr<ui::standard> const &standard,
                                            std::size_t const state_count) {
    return make_shared(region, standard->event_manager(), standard->detector(), standard->renderer(), state_count);
}

std::shared_ptr<button> button::make_shared(region const &region,
                                            std::shared_ptr<ui::event_observable> const &event_manager,
                                            std::shared_ptr<ui::collider_detectable> const &detector,
                                            std::shared_ptr<ui::renderer_observable> const &renderer,
                                            std::size_t const state_count) {
    return std::shared_ptr<button>(new button{region, event_manager, detector, renderer, state_count});
}

button::button(region const &region, std::shared_ptr<ui::event_observable> const &event_manager,
               std::shared_ptr<ui::collider_detectable> const &detector,
               std::shared_ptr<ui::renderer_observable> const &renderer, std::size_t const state_count)
    : _rect_plane(rect_plane::make_shared(state_count * 2, 1)),
      _layout_guide(layout_region_guide::make_shared(region)),
      _state_count(state_count),
      _touch_tracker(touch_tracker::make_shared(detector, event_manager, renderer, this->_rect_plane->node())) {
    this->_rect_plane->node()->set_colliders({collider::make_shared()});

    this->_update_rect_positions(this->_layout_guide->region(), state_count);
    this->_update_rect_index();

    this->_layout_guide
        ->observe([this, state_count = this->_state_count](ui::region const &value) {
            this->_update_rect_positions(value, state_count);
        })
        .end()
        ->add_to(this->_pool);

    this->_touch_tracker->observe([this](auto const &) { this->_update_rect_index(); }).end()->add_to(this->_pool);
}

void button::set_texture(std::shared_ptr<ui::texture> const &texture) {
    this->rect_plane()->node()->meshes().at(0)->set_texture(texture);
}

std::shared_ptr<texture> const &button::texture() const {
    return this->_rect_plane->node()->meshes().at(0)->texture();
}

std::size_t button::state_count() const {
    return this->_state_count;
}

void button::set_state_index(std::size_t const idx) {
    if (idx >= this->_state_count) {
        throw std::invalid_argument("idx greater than or equal state count.");
    }

    this->_state_idx = idx;

    this->_update_rect_index();
}

std::size_t button::state_index() const {
    return this->_state_idx;
}

void button::set_can_begin_tracking(std::function<bool(std::shared_ptr<event> const &)> &&handler) {
    this->_touch_tracker->set_can_begin_tracking(std::move(handler));
}

void button::set_can_indicate_tracking(std::function<bool(std::shared_ptr<event> const &)> &&handler) {
    this->_can_indicate_tracking = std::move(handler);
}

void button::cancel_tracking() {
    this->_touch_tracker->cancel_tracking();
}

observing::endable button::observe(std::function<void(context const &)> &&handler) {
    return this->_touch_tracker->observe([handler = std::move(handler)](touch_tracker_context const &context) {
        handler({.phase = context.phase, .touch = context.touch_event});
    });
}

std::shared_ptr<rect_plane> const &button::rect_plane() {
    return this->_rect_plane;
}

std::shared_ptr<layout_region_guide> const &button::layout_guide() {
    return this->_layout_guide;
}

bool button::_is_tracking() {
    return this->_touch_tracker->tracking().has_value();
}

void button::_update_rect_positions(region const &region, std::size_t const state_count) {
    auto each = make_fast_each(state_count * 2);
    while (yas_each_next(each)) {
        this->_rect_plane->data()->set_rect_position(region, yas_each_index(each));
    }

    std::shared_ptr<collider> const &collider = this->_rect_plane->node()->colliders().at(0);
    if (!collider->shape() || (collider->shape()->type_info() == typeid(shape::rect))) {
        collider->set_shape(shape::make_shared({.rect = region}));
    }
}

void button::_update_rect_index() {
    auto const &tracking = this->_touch_tracker->tracking();
    bool const can_indicate =
        !this->_can_indicate_tracking || (tracking.has_value() && this->_can_indicate_tracking(tracking.value().event));
    std::size_t const idx = to_rect_index(this->_state_idx, this->_is_tracking() && can_indicate);
    this->_rect_plane->data()->set_rect_index(0, idx);
}

bool button::_can_indicate_tracking_value(std::shared_ptr<event> const &event) const {
    return !this->_can_indicate_tracking || (this->_can_indicate_tracking && this->_can_indicate_tracking(event));
}

#pragma mark -

std::size_t yas::to_rect_index(std::size_t const state_idx, bool is_tracking) {
    return state_idx * 2 + (is_tracking ? 1 : 0);
}
