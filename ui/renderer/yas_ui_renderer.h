//
//  yas_ui_renderer.h
//

#pragma once

#include <Metal/Metal.h>
#include <objc_utils/yas_objc_macros.h>
#include <observing/yas_observing_umbrella.h>
#include <simd/simd.h>
#include <ui/yas_ui_detector.h>
#include <ui/yas_ui_event.h>
#include <ui/yas_ui_layout_guide.h>
#include <ui/yas_ui_metal_view_controller_dependency.h>
#include <ui/yas_ui_node.h>

#include <vector>

namespace yas::ui {
struct renderer final : view_renderer_interface, node_parent_interface {
    virtual ~renderer();

    [[nodiscard]] ui::uint_size const &view_size() const;
    [[nodiscard]] ui::uint_size const &drawable_size() const;
    [[nodiscard]] double scale_factor() const;
    [[nodiscard]] simd::float4x4 const &projection_matrix() const;

    [[nodiscard]] ui::system_type system_type() const;
    [[nodiscard]] std::shared_ptr<ui::metal_system> const &metal_system() const;

    [[nodiscard]] std::shared_ptr<background> const &background() const;

    [[nodiscard]] std::shared_ptr<node> const &root_node() const;

    [[nodiscard]] std::shared_ptr<detector> const &detector() const;

    [[nodiscard]] std::shared_ptr<layout_region_guide> const &view_layout_guide() const;
    [[nodiscard]] std::shared_ptr<layout_region_guide> const &safe_area_layout_guide() const;

    [[nodiscard]] ui::appearance appearance() const;

    [[nodiscard]] observing::endable observe_will_render(observing::caller<std::nullptr_t>::handler_f &&);
    [[nodiscard]] observing::syncable observe_scale_factor(observing::caller<double>::handler_f &&);
    [[nodiscard]] observing::syncable observe_appearance(observing::caller<ui::appearance>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<renderer> make_shared();
    [[nodiscard]] static std::shared_ptr<renderer> make_shared(std::shared_ptr<ui::metal_system> const &,
                                                               std::shared_ptr<ui::detector> const &,
                                                               std::shared_ptr<ui::renderer_action_manager> const &);

   private:
    enum class update_result {
        no_change,
        changed,
    };

    enum class pre_render_result {
        none,
        updated,
    };

    std::shared_ptr<ui::metal_system> _metal_system;

    ui::uint_size _view_size;
    ui::uint_size _drawable_size;
    double _scale_factor{0.0f};
    observing::value::holder_ptr<double> _scale_factor_notify;
    yas_edge_insets _safe_area_insets;
    observing::value::holder_ptr<ui::appearance> _appearance;
    simd::float4x4 _projection_matrix;
    renderer_updates_t _updates;

    std::shared_ptr<ui::background> const _background;
    std::shared_ptr<node> const _root_node;
    std::shared_ptr<ui::detector> const _detector;
    std::shared_ptr<ui::renderer_action_manager> const _action_manager;
    std::shared_ptr<layout_region_guide> const _view_layout_guide;
    std::shared_ptr<layout_region_guide> const _safe_area_layout_guide;

    observing::notifier_ptr<std::nullptr_t> const _will_render_notifier;

    explicit renderer(std::shared_ptr<ui::metal_system> const &, std::shared_ptr<ui::detector> const &,
                      std::shared_ptr<ui::renderer_action_manager> const &);

    renderer(renderer const &) = delete;
    renderer(renderer &&) = delete;
    renderer &operator=(renderer const &) = delete;
    renderer &operator=(renderer &&) = delete;

    void _prepare(std::shared_ptr<renderer> const &);

    simd::float4x4 const &matrix_as_parent() const override;

    void view_configure(yas_objc_view *const view) override;
    void view_size_will_change(yas_objc_view *const view, CGSize const size) override;
    void view_safe_area_insets_did_change(yas_objc_view *const view, yas_edge_insets const insets) override;
    void view_render(yas_objc_view *const view) override;
    void view_appearance_did_change(yas_objc_view *const view, ui::appearance const) override;

    pre_render_result _pre_render();
    void _post_render();
    update_result _update_view_size(CGSize const v_size, CGSize const d_size);
    update_result _update_scale_factor();
    update_result _update_safe_area_insets(yas_edge_insets const insets);
    void _update_view_layout_guide();
    void _update_safe_area_layout_guide();
    bool _is_equal_edge_insets(yas_edge_insets const &insets1, yas_edge_insets const &insets2);
};
}  // namespace yas::ui

namespace yas::ui {
bool operator==(std::weak_ptr<yas::ui::renderer> const &, std::weak_ptr<yas::ui::renderer> const &);
bool operator!=(std::weak_ptr<yas::ui::renderer> const &, std::weak_ptr<yas::ui::renderer> const &);
}  // namespace yas::ui
