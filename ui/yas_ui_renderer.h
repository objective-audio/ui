//
//  yas_ui_renderer.h
//

#pragma once

#include <Metal/Metal.h>
#include <chaining/yas_chaining_umbrella.h>
#include <simd/simd.h>
#include <vector>
#include "yas_ui_detector.h"
#include "yas_ui_event.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_node.h"
#include "yas_ui_ptr.h"
#include "yas_ui_renderer_protocol.h"

namespace yas::ui {
class uint_size;
class action;
class metal_system;
class action_target;
enum class system_type;

struct renderer final : view_renderable, std::enable_shared_from_this<renderer> {
    enum class method {
        will_render,
        view_size_changed,
        scale_factor_changed,
        safe_area_insets_changed,
    };

    virtual ~renderer();

    ui::uint_size const &view_size() const;
    ui::uint_size const &drawable_size() const;
    double scale_factor() const;
    simd::float4x4 const &projection_matrix() const;

    ui::system_type system_type() const;
    std::shared_ptr<ui::metal_system> const &metal_system() const;

    ui::node_ptr const &root_node() const;
    ui::node_ptr &root_node();

    ui::view_renderable_ptr view_renderable();

    ui::event_manager_ptr &event_manager();

    std::vector<std::shared_ptr<ui::action>> actions() const;
    void insert_action(std::shared_ptr<ui::action>);
    void erase_action(std::shared_ptr<ui::action> const &);
    void erase_action(std::shared_ptr<ui::action_target> const &target);

    ui::detector_ptr const &detector() const;
    ui::detector_ptr &detector();

    ui::layout_guide_rect_ptr const &view_layout_guide_rect() const;
    ui::layout_guide_rect_ptr &view_layout_guide_rect();
    ui::layout_guide_rect_ptr const &safe_area_layout_guide_rect() const;
    ui::layout_guide_rect_ptr &safe_area_layout_guide_rect();

    ui::appearance appearance() const;

    [[nodiscard]] chaining::chain_unsync_t<std::nullptr_t> chain_will_render() const;
    [[nodiscard]] chaining::chain_sync_t<double> chain_scale_factor() const;
    [[nodiscard]] chaining::chain_sync_t<ui::appearance> chain_appearance() const;

    [[nodiscard]] static renderer_ptr make_shared();
    [[nodiscard]] static renderer_ptr make_shared(ui::metal_system_ptr const &);

   private:
    class impl;

    std::unique_ptr<impl> _impl;

    explicit renderer(std::shared_ptr<ui::metal_system> const &);

    void _prepare(renderer_ptr const &);

    void view_configure(yas_objc_view *const view) override;
    void view_size_will_change(yas_objc_view *const view, CGSize const size) override;
    void view_safe_area_insets_did_change(yas_objc_view *const view, yas_edge_insets const insets) override;
    void view_render(yas_objc_view *const view) override;
    void view_appearance_did_change(yas_objc_view *const view, ui::appearance const) override;
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::renderer::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::renderer::method const &);

namespace yas::ui {
bool operator==(yas::ui::renderer_wptr const &, yas::ui::renderer_wptr const &);
bool operator!=(yas::ui::renderer_wptr const &, yas::ui::renderer_wptr const &);
}  // namespace yas::ui
