//
//  yas_ui_renderer.mm
//

#include "yas_ui_renderer.h"
#include <cpp_utils/yas_each_index.h>
#include <cpp_utils/yas_objc_cast.h>
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_to_bool.h>
#include <simd/simd.h>
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
#include "yas_ui_render_info.h"
#include "yas_ui_types.h"

#if TARGET_OS_IPHONE
#include <UIKit/UIView.h>
#endif

using namespace yas;
using namespace yas::ui;

@interface yas_objc_view (yas_ui_renderer)

- (void)set_event_manager:(event_manager_ptr)manager;

@end

#pragma mark - renderer

renderer::renderer(metal_system_ptr const &metal_system)
    : _metal_system(metal_system),
      _view_size({.width = 0, .height = 0}),
      _drawable_size({.width = 0, .height = 0}),
      _scale_factor_notify(observing::value::holder<double>::make_shared(0.0f)),
      _safe_area_insets({.top = 0, .left = 0, .bottom = 0, .right = 0}),
      _appearance(observing::value::holder<ui::appearance>::make_shared(appearance::normal)),
      _projection_matrix(matrix_identity_float4x4),
      _background(background::make_shared()),
      _root_node(node::make_shared()),
      _parallel_action(parallel_action::make_shared({})),
      _detector(detector::make_shared()),
      _event_manager(event_manager::make_shared()),
      _view_layout_guide_rect(layout_guide_rect::make_shared()),
      _safe_area_layout_guide_rect(layout_guide_rect::make_shared()),
      _will_render_notifier(observing::notifier<std::nullptr_t>::make_shared()) {
}

renderer::~renderer() = default;

uint_size const &renderer::view_size() const {
    return this->_view_size;
}

uint_size const &renderer::drawable_size() const {
    return this->_drawable_size;
}

double renderer::scale_factor() const {
    return this->_scale_factor;
}

simd::float4x4 const &renderer::projection_matrix() const {
    return this->_projection_matrix;
}

background_ptr const &renderer::background() const {
    return this->_background;
}

node_ptr const &renderer::root_node() const {
    return this->_root_node;
}

system_type renderer::system_type() const {
    if (this->_metal_system) {
        return system_type::metal;
    }
    return system_type::none;
}

metal_system_ptr const &renderer::metal_system() const {
    return this->_metal_system;
}

event_manager_ptr const &renderer::event_manager() const {
    return this->_event_manager;
}

std::vector<std::shared_ptr<action>> renderer::actions() const {
    return this->_parallel_action->actions();
}

void renderer::insert_action(std::shared_ptr<action> const &action) {
    this->_parallel_action->insert_action(action);
}

void renderer::erase_action(std::shared_ptr<action> const &action) {
    this->_parallel_action->erase_action(action);
}

void renderer::erase_action(std::shared_ptr<action_target> const &target) {
    for (auto const &action : this->_parallel_action->actions()) {
        if (action->target() == target) {
            this->_parallel_action->erase_action(action);
        }
    }
}

detector_ptr const &renderer::detector() const {
    return this->_detector;
}

layout_guide_rect_ptr const &renderer::view_layout_guide_rect() const {
    return this->_view_layout_guide_rect;
}

layout_guide_rect_ptr const &renderer::safe_area_layout_guide_rect() const {
    return this->_safe_area_layout_guide_rect;
}

appearance renderer::appearance() const {
    return this->_appearance->value();
}

observing::endable renderer::observe_will_render(observing::caller<std::nullptr_t>::handler_f &&handler) {
    return this->_will_render_notifier->observe(std::move(handler));
}

observing::syncable renderer::observe_scale_factor(observing::caller<double>::handler_f &&handler) {
    return this->_scale_factor_notify->observe(std::move(handler));
}

observing::syncable renderer::observe_appearance(observing::caller<ui::appearance>::handler_f &&handler) {
    return this->_appearance->observe(std::move(handler));
}

void renderer::_prepare(renderer_ptr const &shared) {
    renderable_node::cast(this->_root_node)->set_renderer(shared);
}

void renderer::view_configure(yas_objc_view *const view) {
    switch (this->system_type()) {
        case system_type::metal: {
            if (auto metalView = objc_cast<YASUIMetalView>(view)) {
                renderable_metal_system::cast(this->_metal_system)->view_configure(view);
                this->_safe_area_insets = metalView.uiSafeAreaInsets;
                auto const drawable_size = metalView.drawableSize;
                this->view_size_will_change(view, drawable_size);
                this->_appearance->set_value(metalView.uiAppearance);
            } else {
                throw std::runtime_error("view not for metal.");
            }
        } break;

        case system_type::none: {
            throw std::runtime_error("system not found.");
        } break;
    }

    [view set_event_manager:this->_event_manager];
}

void renderer::view_size_will_change(yas_objc_view *const view, CGSize const drawable_size) {
    if (!to_bool(this->system_type())) {
        throw std::runtime_error("system not found.");
    }

    auto const view_size = view.bounds.size;
    auto const update_view_size_result = this->_update_view_size(view_size, drawable_size);
    auto const update_scale_result = this->_update_scale_factor();
    update_result update_safe_area_result = update_result::no_change;

    if ([view isKindOfClass:[YASUIMetalView class]]) {
        auto const metalView = (YASUIMetalView *)view;
        update_safe_area_result = this->_update_safe_area_insets(metalView.uiSafeAreaInsets);
    }

    if (to_bool(update_view_size_result) || to_bool(update_safe_area_result)) {
        this->_update_layout_guide_rect();
        this->_update_safe_area_layout_guide_rect();

        if (to_bool(update_scale_result)) {
            this->_scale_factor_notify->set_value(this->_scale_factor);
        }
    }
}

void renderer::view_safe_area_insets_did_change(yas_objc_view *const view, yas_edge_insets const insets) {
    if (!to_bool(this->system_type())) {
        throw std::runtime_error("system not found.");
    }

    auto const update_result = this->_update_safe_area_insets(insets);

    if (to_bool(update_result)) {
        this->_update_safe_area_layout_guide_rect();
    }
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

        renderable_metal_system::cast(this->_metal_system)->view_render(view, this);
    }

    this->_post_render();
}

void renderer::view_appearance_did_change(yas_objc_view *const view, ui::appearance const appearance) {
    this->_appearance->set_value(appearance);
}

renderer::pre_render_result renderer::_pre_render() {
    this->_parallel_action->raw_action()->update(std::chrono::system_clock::now());

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

renderer::update_result renderer::_update_view_size(CGSize const v_size, CGSize const d_size) {
    auto const prev_view_size = this->_view_size;
    auto const prev_drawable_size = this->_drawable_size;

    float const half_width = v_size.width * 0.5f;
    float const half_height = v_size.height * 0.5f;

    this->_view_size = {static_cast<uint32_t>(v_size.width), static_cast<uint32_t>(v_size.height)};
    this->_drawable_size = {static_cast<uint32_t>(d_size.width), static_cast<uint32_t>(d_size.height)};

    if (this->_view_size == prev_view_size && this->_drawable_size == prev_drawable_size) {
        return update_result::no_change;
    } else {
        this->_projection_matrix = matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
        return update_result::changed;
    }
}

renderer::update_result renderer::_update_scale_factor() {
    auto const prev_scale_factor = this->_scale_factor;

    if (this->_view_size.width > 0 && this->_drawable_size.width > 0) {
        this->_scale_factor =
            static_cast<double>(this->_drawable_size.width) / static_cast<double>(this->_view_size.width);
    } else if (this->_view_size.height > 0 && this->_drawable_size.height > 0) {
        this->_scale_factor =
            static_cast<double>(this->_drawable_size.height) / static_cast<double>(this->_view_size.height);
    } else {
        this->_scale_factor = 0.0;
    }

    if (std::abs(this->_scale_factor - prev_scale_factor) < std::numeric_limits<double>::epsilon()) {
        return update_result::no_change;
    } else {
        return update_result::changed;
    }
}

renderer::update_result renderer::_update_safe_area_insets(yas_edge_insets const insets) {
    auto const prev_insets = this->_safe_area_insets;

    this->_safe_area_insets = insets;

    if (this->_is_equal_edge_insets(this->_safe_area_insets, prev_insets)) {
        return update_result::no_change;
    } else {
        return update_result::changed;
    }
}

void renderer::_update_layout_guide_rect() {
    float const view_width = this->_view_size.width;
    float const view_height = this->_view_size.height;

    this->_view_layout_guide_rect->set_region(
        {.origin = {-view_width * 0.5f, -view_height * 0.5f}, .size = {view_width, view_height}});

    this->_updates.set(renderer_update_reason::view_rect);
}

void renderer::_update_safe_area_layout_guide_rect() {
    float const view_width = this->_view_size.width;
    float const view_height = this->_view_size.height;
    float const origin_x = -view_width * 0.5f + this->_safe_area_insets.left;
    float const origin_y = -view_height * 0.5f + this->_safe_area_insets.bottom;
    float const width = view_width - this->_safe_area_insets.left - this->_safe_area_insets.right;
    float const height = view_height - this->_safe_area_insets.bottom - this->_safe_area_insets.top;

    this->_safe_area_layout_guide_rect->set_region({.origin = {origin_x, origin_y}, .size = {width, height}});

    this->_updates.set(renderer_update_reason::safe_area_rect);
}

bool renderer::_is_equal_edge_insets(yas_edge_insets const &insets1, yas_edge_insets const &insets2) {
    return insets1.top == insets2.top && insets1.left == insets2.left && insets1.bottom == insets2.bottom &&
           insets1.right == insets2.right;
}

renderer_ptr renderer::make_shared() {
    return make_shared(nullptr);
}

renderer_ptr renderer::make_shared(metal_system_ptr const &system) {
    auto shared = std::shared_ptr<renderer>(new renderer{system});
    shared->_prepare(shared);
    return shared;
}

bool yas::ui::operator==(yas::ui::renderer_wptr const &lhs, yas::ui::renderer_wptr const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (locked_lhs && locked_rhs && locked_lhs == locked_rhs);
}

bool yas::ui::operator!=(yas::ui::renderer_wptr const &lhs, yas::ui::renderer_wptr const &rhs) {
    auto locked_lhs = lhs.lock();
    auto locked_rhs = rhs.lock();
    return (!locked_lhs || !locked_rhs || locked_lhs != locked_rhs);
}
