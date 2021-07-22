//
//  yas_ui_view_look.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_common_dependency.h>
#include <ui/yas_ui_node_dependency.h>
#include <ui/yas_ui_renderer_dependency.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
struct view_look final : node_parent_interface, renderer_view_look_interface, scale_factor_observable_interface {
    void set_view_sizes(ui::uint_size const view_size, ui::uint_size const drawable_size,
                        region_insets const safe_area_insets);
    void set_safe_area_insets(region_insets const);
    void set_appearance(ui::appearance const);

    [[nodiscard]] ui::uint_size const &view_size() const;
    [[nodiscard]] ui::uint_size const &drawable_size() const;
    [[nodiscard]] double scale_factor() const override;
    [[nodiscard]] simd::float4x4 const &projection_matrix() const override;

    [[nodiscard]] std::shared_ptr<layout_region_guide> const &view_layout_guide() const;
    [[nodiscard]] std::shared_ptr<layout_region_guide> const &safe_area_layout_guide() const;

    [[nodiscard]] ui::appearance appearance() const;
    [[nodiscard]] std::shared_ptr<ui::background> background() const;

    [[nodiscard]] observing::syncable observe_scale_factor(observing::caller<double>::handler_f &&) override;
    [[nodiscard]] observing::syncable observe_appearance(observing::caller<ui::appearance>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<view_look> make_shared();

   private:
    enum class update_result {
        no_change,
        changed,
    };

    ui::uint_size _view_size;
    ui::uint_size _drawable_size;
    double _scale_factor{0.0f};
    observing::value::holder_ptr<double> const _scale_factor_notify;
    region_insets _safe_area_insets;
    observing::value::holder_ptr<ui::appearance> const _appearance;
    std::shared_ptr<ui::background> const _background;
    simd::float4x4 _projection_matrix;

    std::shared_ptr<layout_region_guide> const _view_layout_guide;
    std::shared_ptr<layout_region_guide> const _safe_area_layout_guide;

    view_look();

    simd::float4x4 const &matrix_as_parent() const override;

    update_result _update_view_size(ui::uint_size const v_size, ui::uint_size const d_size);
    update_result _update_scale_factor();
    update_result _update_safe_area_insets(ui::region_insets const insets);
    void _update_view_layout_guide();
    void _update_safe_area_layout_guide();
};
}  // namespace yas::ui
