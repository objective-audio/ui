//
//  yas_ui_renderer.mm
//

#include "yas_ui_renderer.h"

#include <cpp-utils/to_bool.h>
#include <ui/background/yas_ui_background.h>
#include <ui/node/yas_ui_node.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - renderer

renderer::renderer(std::shared_ptr<ui::system_for_renderer> const &system,
                   std::shared_ptr<ui::view_look_for_renderer> const &view_look,
                   std::shared_ptr<ui::node> const &root_node,
                   std::shared_ptr<ui::detector_for_renderer> const &detector,
                   std::shared_ptr<ui::action_manager_for_renderer> const &action_manager)
    : _system(system),
      _view_look(view_look),
      _root_node(root_node),
      _detector(detector),
      _action_manager(action_manager) {
}

observing::endable renderer::observe_will_render(std::function<void(std::nullptr_t const &)> &&handler) {
    if (!this->_will_render_notifier) {
        this->_will_render_notifier = observing::notifier<std::nullptr_t>::make_shared();
    }
    return this->_will_render_notifier->observe(std::move(handler));
}

observing::endable renderer::observe_did_render(std::function<void(std::nullptr_t const &)> &&handler) {
    if (!this->_did_render_notifier) {
        this->_did_render_notifier = observing::notifier<std::nullptr_t>::make_shared();
    }
    return this->_did_render_notifier->observe(std::move(handler));
}

void renderer::view_render() {
    if (!this->_system) {
        throw std::runtime_error("metal_system not found.");
    }

    if (this->_will_render_notifier) {
        this->_will_render_notifier->notify(nullptr);
    }

    if (to_bool(this->_pre_render())) {
        if (this->_background_color_notifier) {
            this->_background_color_notifier->notify(this->_view_look->background()->color());
        }

        this->_system->view_render(this->_detector, this->_view_look->projection_matrix(), this->_root_node);
    }

    this->_post_render();

    if (this->_did_render_notifier) {
        this->_did_render_notifier->notify(nullptr);
    }
}

observing::endable renderer::observe_background_color(std::function<void(ui::color const &)> &&handler) {
    if (!this->_background_color_notifier) {
        this->_background_color_notifier = observing::notifier<ui::color>::make_shared();
    }
    return this->_background_color_notifier->observe(std::move(handler));
}

renderer::pre_render_result renderer::_pre_render() {
    this->_action_manager->update(std::chrono::system_clock::now());

    tree_updates tree_updates;
    renderable_node::cast(this->_root_node)->fetch_updates(tree_updates);
    renderable_background::cast(this->_view_look->background())->fetch_updates(tree_updates);

    if (tree_updates.is_collider_updated()) {
        this->_detector->begin_update();
    }

    if (this->_updates.flags.any() || tree_updates.is_any_updated()) {
        return pre_render_result::updated;
    }

    return pre_render_result::none;
}

void renderer::_post_render() {
    renderable_node::cast(this->_root_node)->clear_updates();
    renderable_background::cast(this->_view_look->background())->clear_updates();
    this->_detector->end_update();
    this->_updates.flags.reset();
}

std::shared_ptr<renderer> renderer::make_shared(
    std::shared_ptr<ui::system_for_renderer> const &system,
    std::shared_ptr<ui::view_look_for_renderer> const &view_look, std::shared_ptr<ui::node> const &root_node,
    std::shared_ptr<ui::detector_for_renderer> const &detector,
    std::shared_ptr<ui::action_manager_for_renderer> const &action_manager) {
    return std::shared_ptr<renderer>(new renderer{system, view_look, root_node, detector, action_manager});
}

bool yas::ui::operator==(std::weak_ptr<yas::ui::renderer> const &lhs, std::weak_ptr<yas::ui::renderer> const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (locked_lhs && locked_rhs && locked_lhs == locked_rhs);
}

bool yas::ui::operator!=(std::weak_ptr<yas::ui::renderer> const &lhs, std::weak_ptr<yas::ui::renderer> const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (!locked_lhs || !locked_rhs || locked_lhs != locked_rhs);
}
