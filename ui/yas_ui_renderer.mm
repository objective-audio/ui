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
#include "yas_ui_detector.h"
#include "yas_ui_event.h"
#include "yas_ui_layout_guide.h"
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

- (void)set_event_manager:(ui::event_manager)manager;

@end

struct yas::ui::renderer::impl : yas::base::impl, yas::ui::view_renderable::impl {
    enum class update_result {
        no_change,
        changed,
    };

    enum class pre_render_result {
        none,
        updated,
    };

    ui::metal_system _metal_system = nullptr;

    ui::uint_size _view_size = {.width = 0, .height = 0};
    ui::uint_size _drawable_size = {.width = 0, .height = 0};
    double _scale_factor{0.0f};
    chaining::holder<double> _scale_factor_notify{0.0f};
    yas_edge_insets _safe_area_insets = {.top = 0, .left = 0, .bottom = 0, .right = 0};
    simd::float4x4 _projection_matrix = matrix_identity_float4x4;

    ui::node _root_node;
    ui::parallel_action _action;
    ui::detector _detector;
    ui::event_manager _event_manager;
    ui::layout_guide_rect _view_layout_guide_rect;
    ui::layout_guide_rect _safe_area_layout_guide_rect;

    chaining::notifier<std::nullptr_t> _will_render_notifier;

    impl() {
    }

    impl(ui::metal_system &&system) : _metal_system(std::move(system)) {
    }

    ui::system_type system_type() {
        if (this->_metal_system) {
            return ui::system_type::metal;
        }
        return ui::system_type::none;
    }

    void view_configure(yas_objc_view *const view) override {
        switch (this->system_type()) {
            case ui::system_type::metal: {
                if (auto metalView = objc_cast<YASUIMetalView>(view)) {
                    this->_metal_system.renderable().view_configure(view);
                    this->_safe_area_insets = metalView.uiSafeAreaInsets;
                    auto const drawable_size = metalView.drawableSize;
                    this->view_size_will_change(view, drawable_size);
                } else {
                    throw "view not for metal.";
                }
            } break;

            case ui::system_type::none: {
                throw "system not found.";
            } break;
        }

        [view set_event_manager:_event_manager];
    }

    void view_size_will_change(yas_objc_view *const view, CGSize const drawable_size) override {
        if (!to_bool(this->system_type())) {
            throw "system not found.";
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
                this->_scale_factor_notify.set_value(this->_scale_factor);
            }
        }
    }

    void view_safe_area_insets_did_change(yas_objc_view *const view) override {
        if (!to_bool(this->system_type())) {
            throw "system not found.";
        }

        if (![view isKindOfClass:[YASUIMetalView class]]) {
            return;
        }

        auto const metalView = (YASUIMetalView *)view;
        auto const update_result = this->_update_safe_area_insets(metalView.uiSafeAreaInsets);

        if (to_bool(update_result)) {
            this->_update_safe_area_layout_guide_rect();
        }
    }

    pre_render_result pre_render() {
        this->_action.updatable().update(std::chrono::system_clock::now());

        ui::tree_updates tree_updates;
        this->_root_node.renderable().fetch_updates(tree_updates);

        if (tree_updates.is_collider_updated()) {
            this->_detector.updatable().begin_update();
        }

        if (tree_updates.is_any_updated()) {
            return pre_render_result::updated;
        }

        return pre_render_result::none;
    }

    void view_render(yas_objc_view *const view) override {
        if (!this->_metal_system) {
            throw "metal_system not found.";
        }

        this->_will_render_notifier.notify(nullptr);

        if (to_bool(pre_render())) {
            if (auto renderer = cast<ui::renderer>()) {
                this->_metal_system.renderable().view_render(view, renderer);
            }
        }

        post_render();
    }

    void post_render() {
        this->_root_node.renderable().clear_updates();
        this->_detector.updatable().end_update();
    }

    void insert_action(ui::action action) {
        this->_action.insert_action(action);
    }

    void erase_action(ui::action const &action) {
        this->_action.erase_action(action);
    }

    void erase_action(base const &target) {
        for (auto const &action : this->_action.actions()) {
            if (action.target() == target) {
                this->_action.erase_action(action);
            }
        }
    }

   private:
    update_result _update_view_size(CGSize const v_size, CGSize const d_size) {
        auto const prev_view_size = this->_view_size;
        auto const prev_drawable_size = this->_drawable_size;

        float const half_width = v_size.width * 0.5f;
        float const half_height = v_size.height * 0.5f;

        this->_view_size = {static_cast<uint32_t>(v_size.width), static_cast<uint32_t>(v_size.height)};
        this->_drawable_size = {static_cast<uint32_t>(d_size.width), static_cast<uint32_t>(d_size.height)};

        if (this->_view_size == prev_view_size && this->_drawable_size == prev_drawable_size) {
            return update_result::no_change;
        } else {
            this->_projection_matrix =
                ui::matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
            return update_result::changed;
        }
    }

    update_result _update_scale_factor() {
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

    update_result _update_safe_area_insets(yas_edge_insets const insets) {
        auto const prev_insets = this->_safe_area_insets;

        this->_safe_area_insets = insets;

        if (this->_is_equal_edge_insets(this->_safe_area_insets, prev_insets)) {
            return update_result::no_change;
        } else {
            return update_result::changed;
        }
    }

    void _update_layout_guide_rect() {
        float const view_width = this->_view_size.width;
        float const view_height = this->_view_size.height;

        this->_view_layout_guide_rect.set_region(
            {.origin = {-view_width * 0.5f, -view_height * 0.5f}, .size = {view_width, view_height}});
    }

    void _update_safe_area_layout_guide_rect() {
        float const view_width = this->_view_size.width;
        float const view_height = this->_view_size.height;
        float const origin_x = -view_width * 0.5f + this->_safe_area_insets.left;
        float const origin_y = -view_height * 0.5f + this->_safe_area_insets.bottom;
        float const width = view_width - this->_safe_area_insets.left - this->_safe_area_insets.right;
        float const height = view_height - this->_safe_area_insets.bottom - this->_safe_area_insets.top;

        this->_safe_area_layout_guide_rect.set_region({.origin = {origin_x, origin_y}, .size = {width, height}});
    }

    bool _is_equal_edge_insets(yas_edge_insets const &insets1, yas_edge_insets const &insets2) {
        return insets1.top == insets2.top && insets1.left == insets2.left && insets1.bottom == insets2.bottom &&
               insets1.right == insets2.right;
    }
};

#pragma mark - renderer

ui::renderer::renderer(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
    impl_ptr<renderer::impl>()->_root_node.renderable().set_renderer(*this);
}

ui::renderer::renderer() : renderer(std::make_shared<impl>()) {
}

ui::renderer::renderer(ui::metal_system metal_system) : renderer(std::make_shared<impl>(std::move(metal_system))) {
}

ui::renderer::renderer(std::nullptr_t) : base(nullptr) {
}

ui::renderer::~renderer() = default;

ui::uint_size const &ui::renderer::view_size() const {
    return impl_ptr<impl>()->_view_size;
}

ui::uint_size const &ui::renderer::drawable_size() const {
    return impl_ptr<impl>()->_drawable_size;
}

double ui::renderer::scale_factor() const {
    return impl_ptr<impl>()->_scale_factor;
}

simd::float4x4 const &ui::renderer::projection_matrix() const {
    return impl_ptr<impl>()->_projection_matrix;
}

ui::node const &ui::renderer::root_node() const {
    return impl_ptr<impl>()->_root_node;
}

ui::node &ui::renderer::root_node() {
    return impl_ptr<impl>()->_root_node;
}

ui::system_type ui::renderer::system_type() const {
    return impl_ptr<impl>()->system_type();
}

ui::metal_system const &ui::renderer::metal_system() const {
    return impl_ptr<impl>()->_metal_system;
}

ui::metal_system &ui::renderer::metal_system() {
    return impl_ptr<impl>()->_metal_system;
}

ui::view_renderable &ui::renderer::view_renderable() {
    if (!this->_view_renderable) {
        this->_view_renderable = ui::view_renderable{impl_ptr<view_renderable::impl>()};
    }
    return this->_view_renderable;
}

ui::event_manager &ui::renderer::event_manager() {
    return impl_ptr<impl>()->_event_manager;
}

std::vector<ui::action> ui::renderer::actions() const {
    return impl_ptr<impl>()->_action.actions();
}

void ui::renderer::insert_action(ui::action action) {
    impl_ptr<impl>()->insert_action(std::move(action));
}

void ui::renderer::erase_action(ui::action const &action) {
    impl_ptr<impl>()->erase_action(action);
}

void ui::renderer::erase_action(base const &target) {
    impl_ptr<impl>()->erase_action(target);
}

ui::detector const &ui::renderer::detector() const {
    return impl_ptr<impl>()->_detector;
}

ui::detector &ui::renderer::detector() {
    return impl_ptr<impl>()->_detector;
}

ui::layout_guide_rect const &ui::renderer::view_layout_guide_rect() const {
    return impl_ptr<impl>()->_view_layout_guide_rect;
}

ui::layout_guide_rect &ui::renderer::view_layout_guide_rect() {
    return impl_ptr<impl>()->_view_layout_guide_rect;
}

ui::layout_guide_rect const &ui::renderer::safe_area_layout_guide_rect() const {
    return impl_ptr<impl>()->_safe_area_layout_guide_rect;
}

ui::layout_guide_rect &ui::renderer::safe_area_layout_guide_rect() {
    return impl_ptr<impl>()->_safe_area_layout_guide_rect;
}

chaining::chain_unsync_t<std::nullptr_t> ui::renderer::chain_will_render() const {
    return impl_ptr<impl>()->_will_render_notifier.chain();
}

chaining::chain_sync_t<double> ui::renderer::chain_scale_factor() const {
    return impl_ptr<impl>()->_scale_factor_notify.chain();
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
