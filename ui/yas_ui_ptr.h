//
//  yas_ui_ptr.h
//

#pragma once

#include <memory>

namespace yas::ui {
class action_target;
class action;
class parallel_action;
class continuous_action;
class batch;
class blur;
class button;
class collection_layout;
class shape;
class collider;
class detector;
class effect;
class event;
class event_manager;
class font_atlas;
class image;
class layout_animator;
class layout_guide;
class layout_guide_point;
class layout_guide_range;
class layout_guide_rect;
class mesh_data;
class dynamic_mesh_data;
class mesh;
class metal_encode_info;
class metal_render_encoder;
class metal_system;
class metal_texture;
class node;
class rect_plane_data;
class rect_plane;
class render_target;
class renderer;
class strings;
class texture_element;
class texture;

using action_target_ptr = std::shared_ptr<action_target>;
using action_target_wptr = std::weak_ptr<action_target>;
using action_ptr = std::shared_ptr<action>;
using parallel_action_ptr = std::shared_ptr<parallel_action>;
using continuous_action_ptr = std::shared_ptr<continuous_action>;
using batch_ptr = std::shared_ptr<batch>;
using blur_ptr = std::shared_ptr<blur>;
using button_ptr = std::shared_ptr<button>;
using collection_layout_ptr = std::shared_ptr<collection_layout>;
using shape_ptr = std::shared_ptr<shape>;
using collider_ptr = std::shared_ptr<collider>;
using detector_ptr = std::shared_ptr<detector>;
using effect_ptr = std::shared_ptr<effect>;
using event_ptr = std::shared_ptr<event>;
using event_manager_ptr = std::shared_ptr<event_manager>;
using font_atlas_ptr = std::shared_ptr<font_atlas>;
using image_ptr = std::shared_ptr<image>;
using layout_animator_ptr = std::shared_ptr<layout_animator>;
using layout_guide_ptr = std::shared_ptr<layout_guide>;
using layout_guide_wptr = std::weak_ptr<layout_guide>;
using layout_guide_point_ptr = std::shared_ptr<layout_guide_point>;
using layout_guide_point_wptr = std::weak_ptr<layout_guide_point>;
using layout_guide_range_ptr = std::shared_ptr<layout_guide_range>;
using layout_guide_range_wptr = std::weak_ptr<layout_guide_range>;
using layout_guide_rect_ptr = std::shared_ptr<layout_guide_rect>;
using layout_guide_rect_wptr = std::weak_ptr<layout_guide_rect>;
using mesh_data_ptr = std::shared_ptr<mesh_data>;
using dynamic_mesh_data_ptr = std::shared_ptr<dynamic_mesh_data>;
using mesh_ptr = std::shared_ptr<mesh>;
using metal_encode_info_ptr = std::shared_ptr<metal_encode_info>;
using metal_render_encoder_ptr = std::shared_ptr<metal_render_encoder>;
using metal_system_ptr = std::shared_ptr<metal_system>;
using metal_texture_ptr = std::shared_ptr<metal_texture>;
using node_ptr = std::shared_ptr<node>;
using node_wptr = std::weak_ptr<node>;
using rect_plane_data_ptr = std::shared_ptr<rect_plane_data>;
using rect_plane_ptr = std::shared_ptr<rect_plane>;
using render_target_ptr = std::shared_ptr<render_target>;
using renderer_ptr = std::shared_ptr<renderer>;
using renderer_wptr = std::weak_ptr<renderer>;
using strings_ptr = std::shared_ptr<strings>;
using strings_wptr = std::weak_ptr<strings>;
using texture_element_ptr = std::shared_ptr<texture_element>;
using texture_ptr = std::shared_ptr<texture>;
}  // namespace yas::ui