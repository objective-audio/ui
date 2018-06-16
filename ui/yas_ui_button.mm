//
//  yas_ui_button.mm
//

#include "yas_ui_button.h"
#include "yas_fast_each.h"
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
        this->_rect_plane.node().set_collider(ui::collider{});

        this->_update_rect_positions(this->_layout_guide_rect.region(), state_count);
        this->_update_rect_index();
    }

    void prepare(ui::button &button) {
        auto const weak_button = to_weak(button);
        auto &node = this->_rect_plane.node();

        this->_renderer_flow = node.begin_renderer_flow()
                                   .perform([event_flow = base{nullptr}, leave_observer = flow::observer{nullptr},
                                             collider_flows = std::vector<flow::observer>(),
                                             weak_button](ui::renderer const &value) mutable {
                                       if (auto renderer = value) {
                                           event_flow =
                                               renderer.event_manager()
                                                   .begin_flow(ui::event_manager::method::touch_changed)
                                                   .filter([weak_button](ui::event const &) { return !!weak_button; })
                                                   .perform([weak_button](ui::event const &event) {
                                                       weak_button.lock().impl_ptr<impl>()->_update_tracking(event);
                                                   })
                                                   .end();
                                           if (auto button = weak_button.lock()) {
                                               leave_observer = button.impl_ptr<impl>()->_make_leave_flow();
                                               collider_flows = button.impl_ptr<impl>()->_make_collider_flows();
                                           }
                                       } else {
                                           event_flow = nullptr;
                                           leave_observer = nullptr;
                                           collider_flows.clear();
                                       }
                                   })
                                   .end();

        this->_rect_observer = this->_layout_guide_rect.begin_flow()
                                   .filter([weak_button](ui::region const &) { return !!weak_button; })
                                   .perform([weak_button, state_count = this->_state_count](ui::region const &value) {
                                       weak_button.lock().impl_ptr<impl>()->_update_rect_positions(value, state_count);
                                   })
                                   .end();
    }

    ui::texture &texture() {
        return this->_rect_plane.node().mesh().texture();
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

    void cancel_tracking() {
        if (this->_tracking_event) {
            this->_cancel_tracking(this->_tracking_event);
        }
    }

    ui::rect_plane _rect_plane;
    ui::layout_guide_rect _layout_guide_rect;
    flow::sender<flow_pair_t> _notify_sender;
    std::size_t _state_idx = 0;
    std::size_t _state_count;

   private:
    void _update_rect_positions(ui::region const &region, std::size_t const state_count) {
        auto each = make_fast_each(state_count * 2);
        while (yas_each_next(each)) {
            this->_rect_plane.data().set_rect_position(region, yas_each_index(each));
        }

        ui::collider &collider = this->_rect_plane.node().collider();
        if (!collider.shape() || (collider.shape().type_info() == typeid(ui::shape::rect))) {
            this->_rect_plane.node().collider().set_shape(ui::shape{{.rect = region}});
        }
    }

    void _update_rect_index() {
        std::size_t const idx = to_rect_index(this->_state_idx, this->is_tracking());
        this->_rect_plane.data().set_rect_index(0, idx);
    }

    flow::observer _make_leave_flow() {
        std::vector<ui::node::method> methods{ui::node::method::position_changed, ui::node::method::angle_changed,
                                              ui::node::method::scale_changed, ui::node::method::collider_changed,
                                              ui::node::method::enabled_changed};

        return this->_rect_plane.node()
            .begin_flow(methods)
            .perform([weak_button = to_weak(cast<ui::button>())](auto const &pair) {
                if (auto button = weak_button.lock()) {
                    if (auto const &tracking_event = button.impl_ptr<impl>()->_tracking_event) {
                        ui::node::method const &method = pair.first;
                        switch (method) {
                            case ui::node::method::position_changed:
                            case ui::node::method::angle_changed:
                            case ui::node::method::scale_changed: {
                                button.impl_ptr<impl>()->_leave_or_enter_or_move_tracking(tracking_event);
                            } break;
                            case ui::node::method::collider_changed: {
                                ui::node const &node = pair.second;
                                if (!node.collider()) {
                                    node.impl_ptr<impl>()->_cancel_tracking(tracking_event);
                                }
                            } break;
                            case ui::node::method::enabled_changed: {
                                ui::node const &node = pair.second;
                                if (!node.is_enabled()) {
                                    node.impl_ptr<impl>()->_cancel_tracking(tracking_event);
                                }
                            } break;

                            default:
                                break;
                        }
                    }
                }
            })
            .end();
    }

    std::vector<flow::observer> _make_collider_flows() {
        auto &node = this->_rect_plane.node();
        auto weak_button = to_weak(cast<ui::button>());

        auto shape_flow = node.collider()
                              .begin_shape_flow()
                              .perform([weak_button](ui::shape const &shape) {
                                  if (auto button = weak_button.lock()) {
                                      if (auto const &tracking_event = button.impl_ptr<impl>()->_tracking_event) {
                                          if (!shape) {
                                              button.impl_ptr<impl>()->_cancel_tracking(tracking_event);
                                          }
                                      }
                                  }
                              })
                              .end();

        auto enabled_flow = node.collider()
                                .begin_enabled_flow()
                                .perform([weak_button](bool const &enabled) {
                                    if (auto button = weak_button.lock()) {
                                        if (auto const &tracking_event = button.impl_ptr<impl>()->_tracking_event) {
                                            if (!enabled) {
                                                button.impl_ptr<impl>()->_cancel_tracking(tracking_event);
                                            }
                                        }
                                    }
                                })
                                .end();

        return std::vector<flow::observer>{std::move(shape_flow), std::move(enabled_flow)};
    }

    void _update_tracking(ui::event const &event) {
        auto &node = this->_rect_plane.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.detector();
            auto button = cast<ui::button>();

            auto const &touch_event = event.get<ui::touch>();
            switch (event.phase()) {
                case ui::event_phase::began:
                    if (!this->is_tracking()) {
                        if (detector.detect(touch_event.position(), node.collider())) {
                            this->set_tracking_event(event);
                            this->_send_notify(method::began, event);
                        }
                    }
                    break;
                case ui::event_phase::stationary:
                case ui::event_phase::changed: {
                    this->_leave_or_enter_or_move_tracking(event);
                } break;
                case ui::event_phase::ended:
                    if (this->is_tracking(event)) {
                        this->set_tracking_event(nullptr);
                        this->_send_notify(method::ended, event);
                    }
                    break;
                case ui::event_phase::canceled:
                    this->_cancel_tracking(event);
                    break;
                default:
                    break;
            }
        }
    }

    void _leave_or_enter_or_move_tracking(ui::event const &event) {
        auto &node = this->_rect_plane.node();
        if (auto renderer = node.renderer()) {
            auto const &detector = renderer.detector();
            auto const &touch_event = event.get<ui::touch>();
            bool const is_event_tracking = this->is_tracking(event);
            bool is_detected = detector.detect(touch_event.position(), node.collider());
            auto button = cast<ui::button>();
            if (!is_event_tracking && is_detected) {
                this->set_tracking_event(event);
                this->_send_notify(method::entered, event);
            } else if (is_event_tracking && !is_detected) {
                this->set_tracking_event(nullptr);
                this->_send_notify(method::leaved, event);
            } else if (is_event_tracking) {
                this->_send_notify(method::moved, event);
            }
        }
    }

    void _cancel_tracking(ui::event const &event) {
        if (this->is_tracking(event)) {
            this->set_tracking_event(nullptr);
            this->_send_notify(method::canceled, event);
        }
    }

    void _send_notify(method const method, ui::event const &event) {
        this->_notify_sender.send_value(
            std::make_pair(method, context{.button = cast<ui::button>(), .touch = event.get<ui::touch>()}));
    }

    flow::observer _renderer_flow = nullptr;
    ui::event _tracking_event = nullptr;
    flow::observer _rect_observer = nullptr;
};

#pragma mark - ui::button

ui::button::button(ui::region const &region) : button(region, 1) {
}

ui::button::button(ui::region const &region, std::size_t const state_count)
    : base(std::make_shared<impl>(region, state_count)) {
    impl_ptr<impl>()->prepare(*this);
}

ui::button::button(std::nullptr_t) : base(nullptr) {
}

ui::button::~button() = default;

void ui::button::set_texture(ui::texture texture) {
    this->rect_plane().node().mesh().set_texture(std::move(texture));
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
    impl_ptr<impl>()->cancel_tracking();
}

flow::node_t<ui::button::flow_pair_t, false> ui::button::begin_flow() const {
    return impl_ptr<impl>()->_notify_sender.begin();
}

flow::node<ui::button::context, ui::button::flow_pair_t, ui::button::flow_pair_t, false> ui::button::begin_flow(
    method const method) const {
    return impl_ptr<impl>()
        ->_notify_sender.begin()
        .filter([method](flow_pair_t const &pair) { return pair.first == method; })
        .map([](flow_pair_t const &pair) { return pair.second; });
}

ui::rect_plane &ui::button::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}

ui::layout_guide_rect &ui::button::layout_guide_rect() {
    return impl_ptr<impl>()->_layout_guide_rect;
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
