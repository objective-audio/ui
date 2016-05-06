//
//  yas_ui_node_impl.h
//

#pragma once

#include <simd/simd.h>
#include <vector>
#include "yas_objc_ptr.h"
#include "yas_property.h"
#include "yas_ui_collider.h"
#include "yas_ui_mesh.h"
#include "yas_ui_renderer.h"

class yas::ui::node::impl : public base::impl, public renderable_node::impl, public metal_object::impl {
   public:
    impl();
    virtual ~impl();

    std::vector<ui::node> const &children();
    property<weak<ui::node>> parent_property{{.value = ui::node{nullptr}}};
    property<weak<ui::renderer>> renderer_property{{.value = ui::renderer{nullptr}}};

    property<ui::point> position_property{{.value = 0.0f}};
    property<float> angle_property{{.value = 0.0f}};
    property<ui::size> scale_property{{.value = 1.0f}};
    property<ui::color> color_property{{.value = 1.0f}};
    property<float> alpha_property{{.value = 1.0f}};
    property<ui::mesh> mesh_property{{.value = nullptr}};
    property<ui::collider> collider_property{{.value = nullptr}};
    property<bool> enabled_property{{.value = true}};

    void add_sub_node(ui::node &&sub_node);
    void remove_sub_node(ui::node const &sub_node);
    void remove_from_super_node();

    void update_render_info(render_info &info);

    ui::setup_metal_result setup(id<MTLDevice> const) override;

    ui::renderer renderer() override;
    void set_renderer(ui::renderer &&) override;

    node::subject_t subject;

    ui::point convert_position(ui::point const &);

    void _set_renderer_recursively(ui::renderer const &renderer);
    void _update_mesh_color();
    void _set_needs_update_matrix();

    std::vector<base> _property_observers;

   private:
    std::vector<ui::node> _children;

    simd::float4x4 _render_matrix = matrix_identity_float4x4;
    simd::float4x4 _local_matrix = matrix_identity_float4x4;

    bool _needs_update_matrix = true;
};
