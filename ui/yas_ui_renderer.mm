//
//  yas_ui_renderer.mm
//

#include <simd/simd.h>
#include <chrono>
#include "yas_each_index.h"
#include "yas_objc_cast.h"
#include "yas_objc_ptr.h"
#include "yas_observing.h"
#include "yas_to_bool.h"
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
#include "yas_ui_renderer.h"
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

    impl() {
    }

    impl(ui::metal_system &&system) : _metal_system(std::move(system)) {
    }

    ui::system_type system_type() {
        if (_metal_system) {
            return ui::system_type::metal;
        }
        return ui::system_type::none;
    }

    void view_configure(yas_objc_view *const view) override {
        switch (system_type()) {
            case ui::system_type::metal: {
                if (auto metalView = objc_cast<YASUIMetalView>(view)) {
                    _metal_system.renderable().view_configure(view);
                    auto const drawable_size = metalView.drawableSize;
                    view_size_will_change(view, drawable_size);
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
        if (!to_bool(system_type())) {
            throw "system not found.";
        }

        auto const view_size = view.bounds.size;
        auto const update_view_size_result = _update_view_size(view_size, drawable_size);
        auto const update_scale_result = _update_scale_factor();

        if (to_bool(update_view_size_result)) {
            _update_layout_rect();

            if (_subject.has_observer()) {
                _subject.notify(renderer::method::view_size_changed, cast<ui::renderer>());
            }

            if (to_bool(update_scale_result)) {
                if (_subject.has_observer()) {
                    _subject.notify(renderer::method::scale_factor_changed, cast<ui::renderer>());
                }
            }
        }
    }

    pre_render_result pre_render() {
        _action.updatable().update(std::chrono::system_clock::now());

        ui::tree_updates tree_updates;
        _root_node.renderable().fetch_updates(tree_updates);

        if (tree_updates.is_collider_updated()) {
            _detector.updatable().begin_update();
        }

        if (tree_updates.is_any_updated()) {
            return pre_render_result::updated;
        }

        return pre_render_result::none;
    }

    void view_render(yas_objc_view *const view) override {
        if (!_metal_system) {
            throw "metal_system not found.";
        }

        if (_subject.has_observer()) {
            _subject.notify(renderer::method::will_render, cast<ui::renderer>());
        }

        if (to_bool(pre_render())) {
            if (auto renderer = cast<ui::renderer>()) {
                _metal_system.renderable().view_render(view, renderer);
            }
        }

        post_render();
    }

    void post_render() {
        _root_node.renderable().clear_updates();
        _detector.updatable().end_update();
    }

    void insert_action(ui::action action) {
        _action.insert_action(action);
    }

    void erase_action(ui::action const &action) {
        _action.erase_action(action);
    }

    void erase_action(ui::node const &target) {
        for (auto const &action : _action.actions()) {
            if (action.target() == target) {
                _action.erase_action(action);
            }
        }
    }

    ui::metal_system _metal_system = nullptr;

    ui::uint_size _view_size = {.width = 0, .height = 0};
    ui::uint_size _drawable_size = {.width = 0, .height = 0};
    double _scale_factor = 0.0;
    simd::float4x4 _projection_matrix = matrix_identity_float4x4;

    yas::ui::renderer::subject_t _subject;

    ui::node _root_node;
    ui::parallel_action _action;
    ui::detector _detector;
    ui::event_manager _event_manager;
    ui::layout_rect _view_layout_rect;

   private:
    update_result _update_view_size(CGSize const v_size, CGSize const d_size) {
        auto const prev_view_size = _view_size;
        auto const prev_drawable_size = _drawable_size;

        float const half_width = v_size.width * 0.5f;
        float const half_height = v_size.height * 0.5f;

        _view_size = {static_cast<uint32_t>(v_size.width), static_cast<uint32_t>(v_size.height)};
        _drawable_size = {static_cast<uint32_t>(d_size.width), static_cast<uint32_t>(d_size.height)};

        if (_view_size == prev_view_size && _drawable_size == prev_drawable_size) {
            return update_result::no_change;
        } else {
            _projection_matrix = ui::matrix::ortho(-half_width, half_width, -half_height, half_height, -1.0f, 1.0f);
            return update_result::changed;
        }
    }

    update_result _update_scale_factor() {
        auto const prev_scale_factor = _scale_factor;

        if (_view_size.width > 0 && _drawable_size.width > 0) {
            _scale_factor = static_cast<double>(_drawable_size.width) / static_cast<double>(_view_size.width);
        } else if (_view_size.height > 0 && _drawable_size.height > 0) {
            _scale_factor = static_cast<double>(_drawable_size.height) / static_cast<double>(_view_size.height);
        } else {
            _scale_factor = 0.0;
        }

        if (std::abs(_scale_factor - prev_scale_factor) < std::numeric_limits<double>::epsilon()) {
            return update_result::no_change;
        } else {
            return update_result::changed;
        }
    }

    void _update_layout_rect() {
        float const view_width = _view_size.width;
        float const view_height = _view_size.height;

        _view_layout_rect.set_region(
            {.origin = {-view_width * 0.5f, -view_height * 0.5f}, .size = {view_width, view_height}});
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
    if (!_view_renderable) {
        _view_renderable = ui::view_renderable{impl_ptr<view_renderable::impl>()};
    }
    return _view_renderable;
}

yas::ui::renderer::subject_t &ui::renderer::subject() {
    return impl_ptr<impl>()->_subject;
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

void ui::renderer::erase_action(ui::node const &target) {
    impl_ptr<impl>()->erase_action(target);
}

ui::detector const &ui::renderer::detector() const {
    return impl_ptr<impl>()->_detector;
}

ui::detector &ui::renderer::detector() {
    return impl_ptr<impl>()->_detector;
}

ui::layout_rect &ui::renderer::view_layout_rect() {
    return impl_ptr<impl>()->_view_layout_rect;
}
