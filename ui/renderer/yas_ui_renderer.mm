//
//  yas_ui_renderer.mm
//

#include "yas_ui_renderer.h"
#include <cpp_utils/yas_each_index.h>
#include <cpp_utils/yas_objc_cast.h>
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_to_bool.h>
#include <simd/simd.h>
#include <ui/yas_ui_action.h>
#include <ui/yas_ui_background.h>
#include <ui/yas_ui_color.h>
#include <ui/yas_ui_detector.h>
#include <ui/yas_ui_math.h>
#include <ui/yas_ui_matrix.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_metal_view.h>
#include <ui/yas_ui_node.h>
#include <ui/yas_ui_types.h>
#include <ui/yas_ui_view_look.h>
#include <chrono>

#if TARGET_OS_IPHONE
#include <UIKit/UIView.h>
#endif

using namespace yas;
using namespace yas::ui;

#pragma mark - renderer

renderer::renderer(std::shared_ptr<ui::metal_system> const &metal_system,
                   std::shared_ptr<ui::view_look> const &view_look, std::shared_ptr<ui::node> const &root_node,
                   std::shared_ptr<ui::detector> const &detector,
                   std::shared_ptr<ui::renderer_action_manager> const &action_manager)
    : _metal_system(metal_system),
      _view_look(view_look),
      _root_node(root_node),
      _detector(detector),
      _action_manager(action_manager),
      _will_render_notifier(observing::notifier<std::nullptr_t>::make_shared()) {
}

renderer::~renderer() = default;

std::shared_ptr<metal_system> const &renderer::metal_system() const {
    return this->_metal_system;
}

observing::endable renderer::observe_will_render(observing::caller<std::nullptr_t>::handler_f &&handler) {
    return this->_will_render_notifier->observe(std::move(handler));
}

void renderer::view_configure(yas_objc_view *const view) {
    if (auto const metalView = objc_cast<YASUIMetalView>(view)) {
        if (this->_metal_system) {
            renderable_metal_system::cast(this->_metal_system)->view_configure(view);
        }
    } else {
        throw std::runtime_error("view not for metal.");
    }
}

void renderer::view_render(yas_objc_view *const view) {
    if (!this->_metal_system) {
        throw std::runtime_error("metal_system not found.");
    }

    this->_will_render_notifier->notify(nullptr);

    if (to_bool(this->_pre_render())) {
        renderable_metal_system::cast(this->_metal_system)
            ->view_render(view, this->_detector, this->_view_look->projection_matrix(), this->_root_node);
    }

    this->_post_render();
}

renderer::pre_render_result renderer::_pre_render() {
    this->_action_manager->update(std::chrono::system_clock::now());

    tree_updates tree_updates;
    renderable_node::cast(this->_root_node)->fetch_updates(tree_updates);

    if (tree_updates.is_collider_updated()) {
        renderer_detector_interface::cast(this->_detector)->begin_update();
    }

    if (this->_updates.flags.any() || tree_updates.is_any_updated()) {
        return pre_render_result::updated;
    }

    return pre_render_result::none;
}

void renderer::_post_render() {
    renderable_node::cast(this->_root_node)->clear_updates();
    renderer_detector_interface::cast(this->_detector)->end_update();
    this->_updates.flags.reset();
}

std::shared_ptr<renderer> renderer::make_shared(std::shared_ptr<ui::metal_system> const &system,
                                                std::shared_ptr<ui::view_look> const &view_look,
                                                std::shared_ptr<ui::node> const &root_node,
                                                std::shared_ptr<ui::detector> const &detector,
                                                std::shared_ptr<ui::renderer_action_manager> const &action_manager) {
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
