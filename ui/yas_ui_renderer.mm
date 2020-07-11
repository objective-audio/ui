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

@interface yas_objc_view (yas_ui_renderer)

- (void)set_event_manager:(ui::event_manager_ptr)manager;

@end

#pragma mark - renderer

ui::renderer::renderer(ui::metal_system_ptr const &metal_system)
    : _metal_system(metal_system),
      _view_size({.width = 0, .height = 0}),
      _drawable_size({.width = 0, .height = 0}),
      _scale_factor_notify(chaining::value::holder<double>::make_shared(0.0f)),
      _safe_area_insets({.top = 0, .left = 0, .bottom = 0, .right = 0}),
      _appearance(chaining::value::holder<ui::appearance>::make_shared(ui::appearance::normal)),
      _projection_matrix(matrix_identity_float4x4),
      _background(ui::background::make_shared()),
      _root_node(ui::node::make_shared()),
      _action(ui::parallel_action::make_shared()),
      _detector(ui::detector::make_shared()),
      _event_manager(ui::event_manager::make_shared()),
      _view_layout_guide_rect(ui::layout_guide_rect::make_shared()),
      _safe_area_layout_guide_rect(ui::layout_guide_rect::make_shared()),
      _will_render_notifier(chaining::notifier<std::nullptr_t>::make_shared()) {
}

ui::renderer::~renderer() = default;

ui::uint_size const &ui::renderer::view_size() const {
    return this->_view_size;
}

ui::uint_size const &ui::renderer::drawable_size() const {
    return this->_drawable_size;
}

double ui::renderer::scale_factor() const {
    return this->_scale_factor;
}

simd::float4x4 const &ui::renderer::projection_matrix() const {
    return this->_projection_matrix;
}

ui::background_ptr const &ui::renderer::background() const {
    return this->_background;
}

ui::node_ptr const &ui::renderer::root_node() const {
    return this->_root_node;
}

ui::system_type ui::renderer::system_type() const {
    if (this->_metal_system) {
        return ui::system_type::metal;
    }
    return ui::system_type::none;
}

ui::metal_system_ptr const &ui::renderer::metal_system() const {
    return this->_metal_system;
}

ui::event_manager_ptr const &ui::renderer::event_manager() const {
    return this->_event_manager;
}

std::vector<std::shared_ptr<ui::action>> ui::renderer::actions() const {
    return this->_action->actions();
}

void ui::renderer::insert_action(std::shared_ptr<ui::action> const &action) {
    this->_action->insert_action(action);
}

void ui::renderer::erase_action(std::shared_ptr<ui::action> const &action) {
    this->_action->erase_action(action);
}

void ui::renderer::erase_action(ui::action_target_ptr const &target) {
    for (auto const &action : this->_action->actions()) {
        if (action->target() == target) {
            this->_action->erase_action(action);
        }
    }
}

ui::detector_ptr const &ui::renderer::detector() const {
    return this->_detector;
}

ui::detector_ptr &ui::renderer::detector() {
    return this->_detector;
}

ui::layout_guide_rect_ptr const &ui::renderer::view_layout_guide_rect() const {
    return this->_view_layout_guide_rect;
}

ui::layout_guide_rect_ptr &ui::renderer::view_layout_guide_rect() {
    return this->_view_layout_guide_rect;
}

ui::layout_guide_rect_ptr const &ui::renderer::safe_area_layout_guide_rect() const {
    return this->_safe_area_layout_guide_rect;
}

ui::layout_guide_rect_ptr &ui::renderer::safe_area_layout_guide_rect() {
    return this->_safe_area_layout_guide_rect;
}

ui::appearance ui::renderer::appearance() const {
    return this->_appearance->raw();
}

chaining::chain_unsync_t<std::nullptr_t> ui::renderer::chain_will_render() const {
    return this->_will_render_notifier->chain();
}

chaining::chain_sync_t<double> ui::renderer::chain_scale_factor() const {
    return this->_scale_factor_notify->chain();
}

chaining::chain_sync_t<ui::appearance> ui::renderer::chain_appearance() const {
    return this->_appearance->chain();
}

void ui::renderer::_prepare(renderer_ptr const &shared) {
    this->_weak_renderer = shared;
    ui::renderable_node::cast(this->_root_node)->set_renderer(shared);
}

void ui::renderer::view_configure(yas_objc_view *const view) {
    switch (this->system_type()) {
        case ui::system_type::metal: {
            if (auto metalView = objc_cast<YASUIMetalView>(view)) {
                ui::renderable_metal_system::cast(this->_metal_system)->view_configure(view);
                this->_safe_area_insets = metalView.uiSafeAreaInsets;
                auto const drawable_size = metalView.drawableSize;
                this->view_size_will_change(view, drawable_size);
                this->_appearance->set_value(metalView.uiAppearance);
            } else {
                throw std::runtime_error("view not for metal.");
            }
        } break;

        case ui::system_type::none: {
            throw std::runtime_error("system not found.");
        } break;
    }

    [view set_event_manager:this->_event_manager];
}

void ui::renderer::view_size_will_change(yas_objc_view *const view, CGSize const drawable_size) {
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

    if (to_bool(update_view_size_result)) {
        this->_update_layout_guide_rect();
        this->_update_safe_area_layout_guide_rect();

        if (to_bool(update_scale_result)) {
            this->_scale_factor_notify->set_value(this->_scale_factor);
        }
    }
}

void ui::renderer::view_safe_area_insets_did_change(yas_objc_view *const view, yas_edge_insets const insets) {
    if (!to_bool(this->system_type())) {
        throw std::runtime_error("system not found.");
    }

    auto const update_result = this->_update_safe_area_insets(insets);

    if (to_bool(update_result)) {
        this->_update_safe_area_layout_guide_rect();
    }
}

void ui::renderer::view_render(yas_objc_view *const view) {
    if (!this->_metal_system) {
        throw std::runtime_error("metal_system not found.");
    }

    this->_will_render_notifier->notify(nullptr);

    if (to_bool(_pre_render())) {
        if ([view isKindOfClass:[YASUIMetalView class]]) {
            auto const metalView = (YASUIMetalView *)view;
            auto const &color = this->background()->color()->raw();
            auto const &alpha = this->background()->alpha()->raw();
            metalView.clearColor = MTLClearColorMake(color.red, color.green, color.blue, alpha);
        }

        if (auto renderer = this->_weak_renderer.lock()) {
            ui::renderable_metal_system::cast(this->_metal_system)->view_render(view, renderer);
        }
    }

    _post_render();
}

void ui::renderer::view_appearance_did_change(yas_objc_view *const view, ui::appearance const appearance) {
    this->_appearance->set_value(appearance);
}

ui::renderer::pre_render_result ui::renderer::_pre_render() {
    ui::updatable_action::cast(this->_action)->update(std::chrono::system_clock::now());

    auto const bg_updates = ui::renderable_background::cast(this->_background)->updates();

    ui::tree_updates tree_updates;
    ui::renderable_node::cast(this->_root_node)->fetch_updates(tree_updates);

    if (tree_updates.is_collider_updated()) {
        updatable_detector::cast(this->_detector)->begin_update();
    }

    if (bg_updates.flags.any() || tree_updates.is_any_updated()) {
        return pre_render_result::updated;
    }

    return pre_render_result::none;
}

void ui::renderer::_post_render() {
    ui::renderable_background::cast(this->_background)->clear_updates();
    ui::renderable_node::cast(this->_root_node)->clear_updates();
    ui::updatable_detector::cast(this->_detector)->end_update();
}

ui::renderer::update_result ui::renderer::_update_view_size(CGSize const v_size, CGSize const d_size) {
    auto const prev_view_size = this->_view_size;
    auto const prev_drawable_size = this->_drawable_size;

    float const half_width = v_size.width * 0.5f;
    float const half_height = v_size.height * 0.5f;

    this->_view_size = {static_cast<uint32_t>(v_size.width), static_cast<uint32_t>(v_size.height)};
    this->_drawable_size = {static_cast<uint32_t>(d_size.width), static_cast<uint32_t>(d_size.height)};

    if (this->_view_size == prev_view_size && this->_drawable_size == prev_drawable_size) {
        return update_result::no_change;
    } else {
        this->_projection_matrix = ui::matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
        return update_result::changed;
    }
}

ui::renderer::update_result ui::renderer::_update_scale_factor() {
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

ui::renderer::update_result ui::renderer::_update_safe_area_insets(yas_edge_insets const insets) {
    auto const prev_insets = this->_safe_area_insets;

    this->_safe_area_insets = insets;

    if (this->_is_equal_edge_insets(this->_safe_area_insets, prev_insets)) {
        return update_result::no_change;
    } else {
        return update_result::changed;
    }
}

void ui::renderer::_update_layout_guide_rect() {
    float const view_width = this->_view_size.width;
    float const view_height = this->_view_size.height;

    this->_view_layout_guide_rect->set_region(
        {.origin = {-view_width * 0.5f, -view_height * 0.5f}, .size = {view_width, view_height}});
}

void ui::renderer::_update_safe_area_layout_guide_rect() {
    float const view_width = this->_view_size.width;
    float const view_height = this->_view_size.height;
    float const origin_x = -view_width * 0.5f + this->_safe_area_insets.left;
    float const origin_y = -view_height * 0.5f + this->_safe_area_insets.bottom;
    float const width = view_width - this->_safe_area_insets.left - this->_safe_area_insets.right;
    float const height = view_height - this->_safe_area_insets.bottom - this->_safe_area_insets.top;

    this->_safe_area_layout_guide_rect->set_region({.origin = {origin_x, origin_y}, .size = {width, height}});
}

bool ui::renderer::_is_equal_edge_insets(yas_edge_insets const &insets1, yas_edge_insets const &insets2) {
    return insets1.top == insets2.top && insets1.left == insets2.left && insets1.bottom == insets2.bottom &&
           insets1.right == insets2.right;
}

ui::renderer_ptr ui::renderer::make_shared() {
    return make_shared(nullptr);
}

ui::renderer_ptr ui::renderer::make_shared(ui::metal_system_ptr const &system) {
    auto shared = std::shared_ptr<renderer>(new renderer{system});
    shared->_prepare(shared);
    return shared;
}

#pragma mark -

std::string yas::to_string(ui::renderer::method const &method) {
    switch (method) {
        case ui::renderer::method::will_render:
            return "will_render";
        case ui::renderer::method::view_size_changed:
            return "view_size_changed";
        case ui::renderer::method::scale_factor_changed:
            return "scale_factor_changed";
        case ui::renderer::method::safe_area_insets_changed:
            return "safe_area_insets_changed";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::renderer::method const &method) {
    os << to_string(method);
    return os;
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
