//
//  yas_ui_renderer.mm
//

#include "yas_ui_renderer.h"
#include <cpp_utils/yas_each_index.h>
#include <cpp_utils/yas_objc_cast.h>
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_to_bool.h>
#include <simd/simd.h>
#include <ui/yas_ui_view_look.h>
#include <chrono>
#include "yas_ui_action.h"
#include "yas_ui_background.h"
#include "yas_ui_color.h"
#include "yas_ui_detector.h"
#include "yas_ui_math.h"
#include "yas_ui_matrix.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_node.h"
#include "yas_ui_types.h"

#if TARGET_OS_IPHONE
#include <UIKit/UIView.h>
#endif

using namespace yas;
using namespace yas::ui;

#pragma mark - renderer

renderer::renderer(std::shared_ptr<ui::metal_system> const &metal_system,
                   std::shared_ptr<ui::view_look> const &view_look, std::shared_ptr<ui::detector> const &detector,
                   std::shared_ptr<ui::renderer_action_manager> const &action_manager)
    : _metal_system(metal_system),
      _view_look(view_look),
      _background(background::make_shared()),
      _root_node(node::make_shared()),
      _detector(detector),
      _action_manager(action_manager),
      _will_render_notifier(observing::notifier<std::nullptr_t>::make_shared()) {
}

renderer::~renderer() = default;

std::shared_ptr<background> const &renderer::background() const {
    return this->_background;
}

std::shared_ptr<node> const &renderer::root_node() const {
    return this->_root_node;
}

system_type renderer::system_type() const {
    if (this->_metal_system) {
        return system_type::metal;
    }
    return system_type::none;
}

std::shared_ptr<metal_system> const &renderer::metal_system() const {
    return this->_metal_system;
}

observing::endable renderer::observe_will_render(observing::caller<std::nullptr_t>::handler_f &&handler) {
    return this->_will_render_notifier->observe(std::move(handler));
}

void renderer::_prepare(std::shared_ptr<renderer> const &shared) {
    renderable_node::cast(this->_root_node)->set_parent(shared);
}

simd::float4x4 const &renderer::matrix_as_parent() const {
    return this->_view_look->projection_matrix();
}

void renderer::view_configure(yas_objc_view *const view) {
    switch (this->system_type()) {
        case system_type::metal: {
            if (auto metalView = objc_cast<YASUIMetalView>(view)) {
                renderable_metal_system::cast(this->_metal_system)->view_configure(view);
                this->_view_look->set_safe_area_insets(metalView.uiSafeAreaInsets);
                auto const drawable_size = metalView.drawableSize;
                this->view_size_will_change(view, drawable_size);
                this->_view_look->set_appearance(metalView.uiAppearance);
            } else {
                throw std::runtime_error("view not for metal.");
            }
        } break;

        case system_type::none: {
            throw std::runtime_error("system not found.");
        } break;
    }
}

void renderer::view_size_will_change(yas_objc_view *const view, CGSize const drawable_size) {
    if (!to_bool(this->system_type())) {
        throw std::runtime_error("system not found.");
    }

    ui::uint_size const view_size{.width = static_cast<uint32_t>(view.bounds.size.width),
                                  .height = static_cast<uint32_t>(view.bounds.size.height)};
    ui::uint_size const drawable_usize{.width = static_cast<uint32_t>(drawable_size.width),
                                       .height = static_cast<uint32_t>(drawable_size.height)};

    auto safe_area_insets = ui::region_insets::zero();
    if ([view isKindOfClass:[YASUIMetalView class]]) {
        auto const metalView = (YASUIMetalView *)view;
        safe_area_insets = metalView.uiSafeAreaInsets;
    }

    this->_view_look->set_view_sizes(view_size, drawable_usize, safe_area_insets);
}

void renderer::view_safe_area_insets_did_change(yas_objc_view *const view, ui::region_insets const insets) {
    if (!to_bool(this->system_type())) {
        throw std::runtime_error("system not found.");
    }

    this->_view_look->set_safe_area_insets(insets);
}

void renderer::view_render(yas_objc_view *const view) {
    if (!this->_metal_system) {
        throw std::runtime_error("metal_system not found.");
    }

    this->_will_render_notifier->notify(nullptr);

    if (to_bool(this->_pre_render())) {
        if ([view isKindOfClass:[YASUIMetalView class]]) {
            auto const metalView = (YASUIMetalView *)view;
            auto const &color = this->background()->color();
            auto const &alpha = this->background()->alpha();
            metalView.clearColor = MTLClearColorMake(color.red, color.green, color.blue, alpha);
        }

        renderable_metal_system::cast(this->_metal_system)
            ->view_render(view, this->_detector, this->_view_look->projection_matrix(), this->_root_node);
    }

    this->_post_render();
}

void renderer::view_appearance_did_change(yas_objc_view *const view, ui::appearance const appearance) {
    this->_view_look->set_appearance(appearance);
}

renderer::pre_render_result renderer::_pre_render() {
    this->_action_manager->update(std::chrono::system_clock::now());

    auto const bg_updates = renderer_background_interface::cast(this->_background)->updates();

    tree_updates tree_updates;
    renderable_node::cast(this->_root_node)->fetch_updates(tree_updates);

    if (tree_updates.is_collider_updated()) {
        renderer_detector_interface::cast(this->_detector)->begin_update();
    }

    if (this->_updates.flags.any() || bg_updates.flags.any() || tree_updates.is_any_updated()) {
        return pre_render_result::updated;
    }

    return pre_render_result::none;
}

void renderer::_post_render() {
    renderer_background_interface::cast(this->_background)->clear_updates();
    renderable_node::cast(this->_root_node)->clear_updates();
    renderer_detector_interface::cast(this->_detector)->end_update();
    this->_updates.flags.reset();
}

std::shared_ptr<renderer> renderer::make_shared(std::shared_ptr<ui::metal_system> const &system,
                                                std::shared_ptr<ui::view_look> const &view_look,
                                                std::shared_ptr<ui::detector> const &detector,
                                                std::shared_ptr<ui::renderer_action_manager> const &action_manager) {
    auto shared = std::shared_ptr<renderer>(new renderer{system, view_look, detector, action_manager});
    shared->_prepare(shared);
    return shared;
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
