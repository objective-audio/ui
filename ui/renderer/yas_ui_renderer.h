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
#include <ui/yas_ui_ptr.h>
#include <vector>

namespace yas::ui {
class uint_size;
class action;
class metal_system;
class action_target;
enum class system_type;

struct renderer final : view_renderable {
    virtual ~renderer();

    [[nodiscard]] ui::uint_size const &view_size() const;
    [[nodiscard]] ui::uint_size const &drawable_size() const;
    [[nodiscard]] double scale_factor() const;
    [[nodiscard]] simd::float4x4 const &projection_matrix() const;

    [[nodiscard]] ui::system_type system_type() const;
    [[nodiscard]] std::shared_ptr<ui::metal_system> const &metal_system() const;

    [[nodiscard]] ui::background_ptr const &background() const;

    [[nodiscard]] ui::node_ptr const &root_node() const;

    [[nodiscard]] ui::event_manager_ptr const &event_manager() const;

    [[nodiscard]] std::vector<std::shared_ptr<ui::action>> actions() const;
    void insert_action(std::shared_ptr<ui::action> const &);
    void erase_action(std::shared_ptr<ui::action> const &);
    void erase_action(std::shared_ptr<ui::action_target> const &target);

    [[nodiscard]] ui::detector_ptr const &detector() const;

    [[nodiscard]] ui::layout_guide_rect_ptr const &view_layout_guide_rect() const;
    [[nodiscard]] ui::layout_guide_rect_ptr &view_layout_guide_rect();
    [[nodiscard]] ui::layout_guide_rect_ptr const &safe_area_layout_guide_rect() const;
    [[nodiscard]] ui::layout_guide_rect_ptr &safe_area_layout_guide_rect();

    [[nodiscard]] ui::appearance appearance() const;

    [[nodiscard]] observing::endable observe_will_render(observing::caller<std::nullptr_t>::handler_f &&);
    [[nodiscard]] observing::syncable observe_scale_factor(observing::caller<double>::handler_f &&);
    [[nodiscard]] observing::syncable observe_appearance(observing::caller<ui::appearance>::handler_f &&);

    [[nodiscard]] static renderer_ptr make_shared();
    [[nodiscard]] static renderer_ptr make_shared(ui::metal_system_ptr const &);

   private:
    enum class update_result {
        no_change,
        changed,
    };

    enum class pre_render_result {
        none,
        updated,
    };

    ui::metal_system_ptr _metal_system;

    ui::uint_size _view_size;
    ui::uint_size _drawable_size;
    double _scale_factor{0.0f};
    observing::value::holder_ptr<double> _scale_factor_notify;
    yas_edge_insets _safe_area_insets;
    observing::value::holder_ptr<ui::appearance> _appearance;
    simd::float4x4 _projection_matrix;
    renderer_updates_t _updates;

    ui::background_ptr const _background;
    ui::node_ptr const _root_node;
    parallel_action_ptr const _parallel_action;
    ui::detector_ptr const _detector;
    ui::event_manager_ptr const _event_manager;
    ui::layout_guide_rect_ptr const _view_layout_guide_rect;
    ui::layout_guide_rect_ptr const _safe_area_layout_guide_rect;

    observing::notifier_ptr<std::nullptr_t> const _will_render_notifier;

    explicit renderer(std::shared_ptr<ui::metal_system> const &);

    renderer(renderer const &) = delete;
    renderer(renderer &&) = delete;
    renderer &operator=(renderer const &) = delete;
    renderer &operator=(renderer &&) = delete;

    void _prepare(renderer_ptr const &);

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
    void _update_layout_guide_rect();
    void _update_safe_area_layout_guide_rect();
    bool _is_equal_edge_insets(yas_edge_insets const &insets1, yas_edge_insets const &insets2);
};
}  // namespace yas::ui

namespace yas::ui {
bool operator==(yas::ui::renderer_wptr const &, yas::ui::renderer_wptr const &);
bool operator!=(yas::ui::renderer_wptr const &, yas::ui::renderer_wptr const &);
}  // namespace yas::ui
