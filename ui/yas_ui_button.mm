//
//  yas_ui_button.mm
//

#include "yas_ui_button.h"
#include <cpp_utils/yas_fast_each.h>
#include "yas_ui_angle.h"
#include "yas_ui_collider.h"
#include "yas_ui_detector.h"
#include "yas_ui_event.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

#pragma mark - ui::button::impl

struct ui::button::impl : base::impl {
    impl(ui::region const &region, std::size_t const state_count)
        : _rect_plane(state_count * 2, 1), _layout_guide_rect(region), _state_count(state_count) {
        this->_rect_plane.node().collider().set_value(ui::collider{});

        this->_update_rect_positions(this->_layout_guide_rect.region(), state_count);
        this->_update_rect_index();
    }

    void prepare(std::shared_ptr<ui::button> const &button) {
        auto const weak_button = to_weak(button);
        auto &node = this->_rect_plane.node();

        this->_leave_or_enter_or_move_tracking_receiver = chaining::perform_receiver<>{[weak_button] {
            if (auto button = weak_button.lock()) {
                auto button_impl = button->impl_ptr<impl>();
                if (auto tracking_event = button_impl->_tracking_event) {
                    button_impl->_leave_or_enter_or_move_tracking(tracking_event, button);
                }
            }
        }};

        this->_cancel_tracking_receiver = chaining::perform_receiver<>{[weak_button]() {
            if (auto button = weak_button.lock()) {
                auto button_impl = button->impl_ptr<impl>();
                if (auto tracking_event = button_impl->_tracking_event) {
                    button_impl->_cancel_tracking(tracking_event, button);
                }
            }
        }};

        this->_renderer_observer =
            node.chain_renderer()
                .perform([event_observer = chaining::any_observer_ptr{nullptr},
                          leave_observers = std::vector<chaining::any_observer_ptr>(),
                          collider_observers = std::vector<chaining::any_observer_ptr>(),
                          weak_button](ui::renderer const &value) mutable {
                    if (auto renderer = value) {
                        event_observer = renderer.event_manager()
                                             .chain(ui::event_manager::method::touch_changed)
                                             .guard([weak_button](ui::event const &) { return !weak_button.expired(); })
                                             .perform([weak_button](ui::event const &event) {
                                                 if (auto button = weak_button.lock()) {
                                                     button->impl_ptr<impl>()->_update_tracking(event, button);
                                                 }
                                             })
                                             .end();
                        if (auto button = weak_button.lock()) {
                            auto button_impl = button->impl_ptr<impl>();
                            leave_observers = button_impl->_make_leave_chains();
                            collider_observers = button_impl->_make_collider_chains();
                        }
                    } else {
                        event_observer = nullptr;
                        leave_observers.clear();
                        collider_observers.clear();
                    }
                })
                .end();

        this->_rect_observer = this->_layout_guide_rect.chain()
                                   .guard([weak_button](ui::region const &) { return !weak_button.expired(); })
                                   .perform([weak_button, state_count = this->_state_count](ui::region const &value) {
                                       weak_button.lock()->impl_ptr<impl>()->_update_rect_positions(value, state_count);
                                   })
                                   .end();
    }

    ui::texture &texture() {
        return this->_rect_plane.node().mesh().raw().texture();
    }

    void set_state_idx(std::size_t const idx) {
        if (idx >= this->_state_count) {
            throw std::invalid_argument("idx greater than or equal state count.");
        }

        this->_state_idx = idx;

        this->_update_rect_index();
    }

    bool is_tracking() {
        return !!this->_tracking_event;
    }

    bool is_tracking(ui::event const &event) {
        return event == this->_tracking_event;
    }

    void set_tracking_event(ui::event event) {
        this->_tracking_event = std::move(event);

        this->_update_rect_index();
    }

    void cancel_tracking(std::shared_ptr<button> const &button) {
        if (this->_tracking_event) {
            this->_cancel_tracking(this->_tracking_event, button);
        }
    }

    ui::rect_plane _rect_plane;
    ui::layout_guide_rect _layout_guide_rect;
    chaining::notifier<chain_pair_t> _notify_sender;
    std::size_t _state_idx = 0;
    std::size_t _state_count;

   private:
    void _update_rect_positions(ui::region const &region, std::size_t const state_count) {
        auto each = make_fast_each(state_count * 2);
        while (yas_each_next(each)) {
            this->_rect_plane.data().set_rect_position(region, yas_each_index(each));
        }

        ui::collider &collider = this->_rect_plane.node().collider().raw();
        if (!collider.shape() || (collider.shape().type_info() == typeid(ui::shape::rect))) {
            collider.set_shape(ui::shape{{.rect = region}});
        }
    }

    void _update_rect_index() {
        std::size_t const idx = to_rect_index(this->_state_idx, this->is_tracking());
        this->_rect_plane.data().set_rect_index(0, idx);
    }

    std::vector<chaining::any_observer_ptr> _make_leave_chains() {
        ui::node &node = this->_rect_plane.node();
        auto weak_node = to_weak(node);

        std::vector<chaining::any_observer_ptr> observers;
        observers.emplace_back(
            node.position().chain().send_null(*this->_leave_or_enter_or_move_tracking_receiver).end());
        observers.emplace_back(node.angle().chain().send_null(*this->_leave_or_enter_or_move_tracking_receiver).end());
        observers.emplace_back(node.scale().chain().send_null(*this->_leave_or_enter_or_move_tracking_receiver).end());

        observers.emplace_back(node.collider()
                                   .chain()
                                   .guard([](ui::collider const &value) { return !value; })
                                   .send_null(*this->_cancel_tracking_receiver)
                                   .end());
        observers.emplace_back(node.is_enabled()
                                   .chain()
                                   .guard([](bool const &value) { return !value; })
                                   .send_null(*this->_cancel_tracking_receiver)
                                   .end());

        return observers;
    }

    std::vector<chaining::any_observer_ptr> _make_collider_chains() {
        auto &node = this->_rect_plane.node();

        auto shape_observer = node.collider()
                                  .raw()
                                  .chain_shape()
                                  .guard([](ui::shape const &shape) { return !shape; })
                                  .send_null(*this->_cancel_tracking_receiver)
                                  .end();

        auto enabled_observer = node.collider()
                                    .raw()
                                    .chain_enabled()
                                    .guard([](bool const &enabled) { return !enabled; })
                                    .send_null(*this->_cancel_tracking_receiver)
                                    .end();

        return std::vector<chaining::any_observer_ptr>{std::move(shape_observer), std::move(enabled_observer)};
    }

    void _update_tracking(ui::event const &event, std::shared_ptr<button> const &button) {
        auto &node = this->_rect_plane.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.detector();

            auto const &touch_event = event.get<ui::touch>();
            switch (event.phase()) {
                case ui::event_phase::began:
                    if (!this->is_tracking()) {
                        if (detector.detect(touch_event.position(), node.collider().raw())) {
                            this->set_tracking_event(event);
                            this->_send_notify(method::began, event, button);
                        }
                    }
                    break;
                case ui::event_phase::stationary:
                case ui::event_phase::changed: {
                    this->_leave_or_enter_or_move_tracking(event, button);
                } break;
                case ui::event_phase::ended:
                    if (this->is_tracking(event)) {
                        this->set_tracking_event(nullptr);
                        this->_send_notify(method::ended, event, button);
                    }
                    break;
                case ui::event_phase::canceled:
                    this->_cancel_tracking(event, button);
                    break;
                default:
                    break;
            }
        }
    }

    void _leave_or_enter_or_move_tracking(ui::event const &event, std::shared_ptr<button> const &button) {
        auto &node = this->_rect_plane.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.detector();
            auto const &touch_event = event.get<ui::touch>();
            bool const is_event_tracking = this->is_tracking(event);
            bool is_detected = detector.detect(touch_event.position(), node.collider().raw());
            if (!is_event_tracking && is_detected) {
                this->set_tracking_event(event);
                this->_send_notify(method::entered, event, button);
            } else if (is_event_tracking && !is_detected) {
                this->set_tracking_event(nullptr);
                this->_send_notify(method::leaved, event, button);
            } else if (is_event_tracking) {
                this->_send_notify(method::moved, event, button);
            }
        }
    }

    void _cancel_tracking(ui::event const &event, std::shared_ptr<button> const &button) {
        if (this->is_tracking(event)) {
            this->set_tracking_event(nullptr);
            this->_send_notify(method::canceled, event, button);
        }
    }

    void _send_notify(method const method, ui::event const &event, std::shared_ptr<button> const &button) {
        this->_notify_sender.notify(std::make_pair(method, context{.button = button, .touch = event.get<ui::touch>()}));
    }

    chaining::any_observer_ptr _renderer_observer = nullptr;
    ui::event _tracking_event = nullptr;
    chaining::any_observer_ptr _rect_observer = nullptr;
    std::optional<chaining::perform_receiver<>> _leave_or_enter_or_move_tracking_receiver = std::nullopt;
    std::optional<chaining::perform_receiver<>> _cancel_tracking_receiver = std::nullopt;
};

#pragma mark - ui::button

ui::button::button(ui::region const &region, std::size_t const state_count)
    : base(std::make_shared<impl>(region, state_count)) {
}

ui::button::~button() = default;

void ui::button::set_texture(ui::texture texture) {
    this->rect_plane().node().mesh().raw().set_texture(std::move(texture));
}

ui::texture const &ui::button::texture() const {
    return impl_ptr<impl>()->texture();
}

std::size_t ui::button::state_count() const {
    return impl_ptr<impl>()->_state_count;
}

void ui::button::set_state_index(std::size_t const idx) {
    impl_ptr<impl>()->set_state_idx(idx);
}

std::size_t ui::button::state_index() const {
    return impl_ptr<impl>()->_state_idx;
}

void ui::button::cancel_tracking() {
    impl_ptr<impl>()->cancel_tracking(shared_from_this());
}

chaining::chain_unsync_t<ui::button::chain_pair_t> ui::button::chain() const {
    return impl_ptr<impl>()->_notify_sender.chain();
}

chaining::chain_relayed_unsync_t<ui::button::context, ui::button::chain_pair_t> ui::button::chain(
    method const method) const {
    return impl_ptr<impl>()
        ->_notify_sender.chain()
        .guard([method](chain_pair_t const &pair) { return pair.first == method; })
        .to([](chain_pair_t const &pair) { return pair.second; });
}

ui::rect_plane &ui::button::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}

ui::layout_guide_rect &ui::button::layout_guide_rect() {
    return impl_ptr<impl>()->_layout_guide_rect;
}

void ui::button::_prepare() {
    impl_ptr<impl>()->prepare(shared_from_this());
}

std::shared_ptr<ui::button> ui::button::make_shared(ui::region const &region) {
    return make_shared(region, 1);
}

std::shared_ptr<ui::button> ui::button::make_shared(ui::region const &region, std::size_t const state_count) {
    auto shared = std::shared_ptr<button>(new button{region, state_count});
    shared->_prepare();
    return shared;
}

#pragma mark -

std::size_t yas::to_rect_index(std::size_t const state_idx, bool is_tracking) {
    return state_idx * 2 + (is_tracking ? 1 : 0);
}

std::string yas::to_string(ui::button::method const &method) {
    switch (method) {
        case ui::button::method::began:
            return "began";
        case ui::button::method::entered:
            return "entered";
        case ui::button::method::moved:
            return "moved";
        case ui::button::method::leaved:
            return "leaved";
        case ui::button::method::ended:
            return "ended";
        case ui::button::method::canceled:
            return "canceled";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::button::method const &method) {
    os << to_string(method);
    return os;
}
