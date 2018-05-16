//
//  yas_ui_renderer.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <vector>
#include "yas_base.h"
#include "yas_flow.h"
#include "yas_ui_renderer_protocol.h"

namespace yas {
template <typename K, typename T>
class subject;
template <typename K, typename T>
class observer;
}  // namespace yas

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

class renderer : public base {
   public:
    class impl;

    enum class method {
        will_render,
        view_size_changed,
        scale_factor_changed,
        safe_area_insets_changed,
    };

    using subject_t = subject<ui::renderer::method, ui::renderer>;
    using observer_t = observer<ui::renderer::method, ui::renderer>;

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

    subject_t &subject();

    ui::event_manager &event_manager();

    std::vector<ui::action> actions() const;
    void insert_action(ui::action);
    void erase_action(ui::action const &);
    void erase_action(base const &target);

    ui::detector const &detector() const;
    ui::detector &detector();

    ui::layout_guide_rect const &view_layout_guide_rect() const;
    ui::layout_guide_rect &view_layout_guide_rect();
    ui::layout_guide_rect const &safe_area_layout_guide_rect() const;
    ui::layout_guide_rect &safe_area_layout_guide_rect();

    flow::node<std::nullptr_t> begin_will_render_flow() const;

   private:
    ui::view_renderable _view_renderable = nullptr;

    explicit renderer(std::shared_ptr<impl> &&);
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::renderer::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::renderer::method const &);
