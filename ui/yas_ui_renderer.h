//
//  yas_ui_renderer.h
//

#pragma once

#include <Metal/Metal.h>
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_base.h>
#include <simd/simd.h>
#include <vector>
#include "yas_ui_renderer_protocol.h"

namespace yas::ui {
class view_renderable;
class event_manager;
class uint_size;
class node;
class action;
class detector;
class layout_guide_rect;
class metal_system;
enum class system_type;

struct renderer : base {
    class impl;

    enum class method {
        will_render,
        view_size_changed,
        scale_factor_changed,
        safe_area_insets_changed,
    };

    renderer();
    explicit renderer(ui::metal_system);
    renderer(std::nullptr_t);

    virtual ~renderer() final;

    ui::uint_size const &view_size() const;
    ui::uint_size const &drawable_size() const;
    double scale_factor() const;
    simd::float4x4 const &projection_matrix() const;

    ui::system_type system_type() const;
    ui::metal_system const &metal_system() const;
    ui::metal_system &metal_system();

    ui::node const &root_node() const;
    ui::node &root_node();

    ui::view_renderable &view_renderable();

    ui::event_manager &event_manager();

    std::vector<std::shared_ptr<ui::action>> actions() const;
    void insert_action(std::shared_ptr<ui::action>);
    void erase_action(std::shared_ptr<ui::action> const &);
    void erase_action(base const &target);

    ui::detector const &detector() const;
    ui::detector &detector();

    ui::layout_guide_rect const &view_layout_guide_rect() const;
    ui::layout_guide_rect &view_layout_guide_rect();
    ui::layout_guide_rect const &safe_area_layout_guide_rect() const;
    ui::layout_guide_rect &safe_area_layout_guide_rect();

    ui::appearance appearance() const;

    [[nodiscard]] chaining::chain_unsync_t<std::nullptr_t> chain_will_render() const;
    [[nodiscard]] chaining::chain_sync_t<double> chain_scale_factor() const;
    [[nodiscard]] chaining::chain_sync_t<ui::appearance> chain_appearance() const;

   private:
    ui::view_renderable _view_renderable = nullptr;

    explicit renderer(std::shared_ptr<impl> &&);
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::renderer::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::renderer::method const &);
