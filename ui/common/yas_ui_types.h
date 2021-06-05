//
//  yas_ui_types.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <cpp_utils/yas_flagset.h>
#include <simd/simd.h>
#include <ui/yas_ui_shared_types.h>
#include <optional>
#include <ostream>
#include <string>

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
class layout_guide_value;
class layout_guide_point;
class layout_guide_range;
class layout_guide_rect;
class layout_value_source;
class layout_point_source;
class layout_range_source;
class layout_region_source;
class layout_value_target;
class layout_point_target;
class layout_range_target;
class layout_region_target;
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
class color;
class background;
class angle;

class renderable_render_target;
class updatable_action;
class renderable_batch;
class renderable_collider;
class renderer_detector_interface;
class renderable_effect;
class encodable_effect;
class metal_view_event_manager_interface;
class manageable_event;
class renderable_mesh;
class renderable_mesh_data;
class metal_object;
class renderable_metal_system;
class makable_metal_system;
class testable_metal_system;
class renderable_node;
class render_encodable;
class render_effectable;
class render_stackable;
class view_renderer_interface;
class renderer_background_interface;

enum class system_type {
    none,
    metal,
    //        open_gl,
};

enum class pixel_format { rgba8_unorm, bgra8_unorm };

enum class texture_usage {
    shader_read,
    shader_write,
    render_target,

    count,
};

using texture_usages_t = flagset<texture_usage>;

struct uint_point {
    uint32_t x = 0;
    uint32_t y = 0;

    bool operator==(uint_point const &rhs) const;
    bool operator!=(uint_point const &rhs) const;

    [[nodiscard]] static uint_point const &zero();
};

struct uint_size {
    uint32_t width = 1;
    uint32_t height = 1;

    bool operator==(uint_size const &rhs) const;
    bool operator!=(uint_size const &rhs) const;

    [[nodiscard]] static uint_size const &zero();
};

struct uint_region {
    uint_point origin;
    uint_size size;

    bool operator==(uint_region const &rhs) const;
    bool operator!=(uint_region const &rhs) const;

    [[nodiscard]] uint32_t left() const;
    [[nodiscard]] uint32_t right() const;
    [[nodiscard]] uint32_t bottom() const;
    [[nodiscard]] uint32_t top() const;

    [[nodiscard]] static uint_region const &zero();
};

struct uint_range {
    uint32_t location;
    uint32_t length;

    bool operator==(uint_range const &rhs) const;
    bool operator!=(uint_range const &rhs) const;

    [[nodiscard]] uint32_t min() const;
    [[nodiscard]] uint32_t max() const;

    [[nodiscard]] static uint_range const &zero();
};

struct point {
    union {
        struct {
            float x;
            float y;
        };
        simd::float2 v;
    };

    bool operator==(point const &rhs) const;
    bool operator!=(point const &rhs) const;
    point operator+(point const &rhs) const;
    point operator-(point const &rhs) const;
    point &operator+=(point const &rhs);
    point &operator-=(point const &rhs);

    explicit operator bool() const;

    [[nodiscard]] static point const &zero();
};

struct size {
    union {
        struct {
            float width;
            float height;
        };
        simd::float2 v;
    };

    bool operator==(size const &rhs) const;
    bool operator!=(size const &rhs) const;

    explicit operator bool() const;

    [[nodiscard]] static size const &zero();
};

struct range_insets {
    float min;
    float max;

    bool operator==(range_insets const &rhs) const;
    bool operator!=(range_insets const &rhs) const;

    explicit operator bool() const;

    [[nodiscard]] static range_insets const &zero();
};

struct range {
    union {
        struct {
            float location;
            float length;
        };
        simd::float2 v;
    };

    bool operator==(range const &rhs) const;
    bool operator!=(range const &rhs) const;
    range operator+(range_insets const &rhs) const;
    range operator-(range_insets const &rhs) const;
    range &operator+=(range_insets const &rhs);
    range &operator-=(range_insets const &rhs);

    explicit operator bool() const;

    [[nodiscard]] float min() const;
    [[nodiscard]] float max() const;
    [[nodiscard]] range_insets insets() const;

    [[nodiscard]] range combined(range const &) const;
    [[nodiscard]] std::optional<range> intersected(range const &) const;

    [[nodiscard]] static range const &zero();
};

struct region_insets {
    union {
        struct {
            float left;
            float right;
            float bottom;
            float top;
        };
        simd::float4 v;
    };

    bool operator==(region_insets const &rhs) const;
    bool operator!=(region_insets const &rhs) const;

    explicit operator bool() const;

    [[nodiscard]] static region_insets const &zero();
};

struct region {
    union {
        struct {
            ui::point origin;
            ui::size size;
        };
        simd::float4 v;
    };

    bool operator==(region const &rhs) const;
    bool operator!=(region const &rhs) const;
    region operator+(region_insets const &rhs) const;
    region operator-(region_insets const &rhs) const;
    region &operator+=(region_insets const &rhs);
    region &operator-=(region_insets const &rhs);

    explicit operator bool() const;

    [[nodiscard]] range horizontal_range() const;
    [[nodiscard]] range vertical_range() const;
    [[nodiscard]] float left() const;
    [[nodiscard]] float right() const;
    [[nodiscard]] float bottom() const;
    [[nodiscard]] float top() const;
    [[nodiscard]] region_insets insets() const;
    [[nodiscard]] point center() const;

    [[nodiscard]] region combined(region const &) const;
    [[nodiscard]] std::optional<region> intersected(region const &) const;

    [[nodiscard]] static region const &zero();
    [[nodiscard]] static region zero_centered(ui::size const &);
};

struct region_ranges_args final {
    ui::range horizontal;
    ui::range vertical;
};

ui::region make_region(region_ranges_args &&);

enum class pivot {
    left,
    center,
    right,
};

enum class primitive_type {
    point,
    line,
    line_strip,
    triangle,
    triangle_strip,
};

struct vertex2d_rect_t {
    vertex2d_t v[4];

    void set_position(ui::region const &);
    void set_tex_coord(ui::uint_region const &);
};

using index2d_t = uint32_t;

struct index2d_rect_t {
    index2d_t v[6];
};

ui::point to_point(ui::uint_point const &);
ui::size to_size(ui::uint_size const &);
ui::range to_range(ui::uint_range const &);
ui::region to_region(ui::uint_region const &);

enum class appearance {
    normal,
    dark,
};

using draw_handler_f = std::function<void(CGContextRef const)>;
using draw_pair_t = std::pair<uint_size, draw_handler_f>;
}  // namespace yas::ui

namespace yas {
simd::float2 to_float2(CGPoint const &);
simd::float2 to_float2(simd::float4 const &);
simd::float4 to_float4(simd::float2 const &);

bool contains(ui::region const &, ui::point const &);

std::string to_string(ui::pivot const &);
std::string to_string(ui::uint_point const &);
std::string to_string(ui::uint_size const &);
std::string to_string(ui::uint_region const &);
std::string to_string(ui::region_insets const &);
std::string to_string(ui::region const &);
std::string to_string(ui::point const &);
std::string to_string(ui::size const &);
std::string to_string(ui::range_insets const &);
std::string to_string(ui::range const &);
std::string to_string(ui::appearance const &);
std::string to_string(simd::float2 const &);
std::string to_string(simd::float3 const &);
std::string to_string(simd::float4 const &);
std::string to_string(simd::float4x4 const &);

bool is_equal(simd::float2 const &, simd::float2 const &);
bool is_equal(simd::float3 const &, simd::float3 const &);
bool is_equal(simd::float4 const &, simd::float4 const &);

bool is_equal(simd::float4x4 const &, simd::float4x4 const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::uint_point const &);
std::ostream &operator<<(std::ostream &, yas::ui::uint_size const &);
std::ostream &operator<<(std::ostream &, yas::ui::uint_region const &);
std::ostream &operator<<(std::ostream &, yas::ui::region_insets const &);
std::ostream &operator<<(std::ostream &, yas::ui::region const &);
std::ostream &operator<<(std::ostream &, yas::ui::point const &);
std::ostream &operator<<(std::ostream &, yas::ui::size const &);
std::ostream &operator<<(std::ostream &, yas::ui::range_insets const &);
std::ostream &operator<<(std::ostream &, yas::ui::range const &);
std::ostream &operator<<(std::ostream &, yas::ui::appearance const &);

std::ostream &operator<<(std::ostream &, simd::float2 const &);
std::ostream &operator<<(std::ostream &, simd::float3 const &);
std::ostream &operator<<(std::ostream &, simd::float4 const &);
std::ostream &operator<<(std::ostream &, simd::float4x4 const &);
