//
//  yas_ui_node_impl.h
//

#pragma once

#include <simd/simd.h>
#include <vector>
#include "yas_objc_ptr.h"
#include "yas_ui_mesh.h"

class yas::ui::node::impl : public base::impl, public renderable_node::impl, public metal_object::impl {
   public:
    impl();
    virtual ~impl();

    std::vector<ui::node> children;
    weak<node> parent;

    simd::float2 position();
    float angle();
    simd::float2 scale();
    simd::float3 color();
    float alpha();
    ui::mesh mesh();
    bool is_enabled();

    void set_position(simd::float2 const);
    void set_angle(float const);
    void set_scale(simd::float2 const);
    void set_color(simd::float3 const);
    void set_alpha(float const);
    void set_mesh(ui::mesh &&);
    void set_enabled(bool const);

    void add_sub_node(ui::node &&sub_node);
    void remove_sub_node(ui::node const &sub_node);
    void remove_from_super_node();

    void update_render_info(render_info &info);

    ui::setup_metal_result setup(id<MTLDevice> const) override;

    virtual void update_matrix_for_render(simd::float4x4 const matrix);

    ui::node_renderer renderer() override;
    void set_renderer(ui::node_renderer &&) override;

    simd::float2 convert_position(simd::float2 const &);

   private:
    weak<ui::node_renderer> _node_renderer;

    simd::float2 _position;
    float _angle;
    simd::float2 _scale;
    simd::float3 _color;
    float _alpha;
    ui::mesh _mesh{nullptr};
    bool _enabled;

    simd::float4x4 _render_matrix;
    simd::float4x4 _local_matrix;
    bool _needs_update_matrix;

    void _update_mesh_color();
};
