//
//  yas_ui_types.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <simd/simd.h>
#include <ostream>
#include <string>
#include "yas_ui_shared_types.h"

namespace yas {
namespace ui {
    enum class system_type {
        none,
        metal,
        //        open_gl,
    };

    struct vertex2d_rect_t {
        vertex2d_t v[4];
    };

    using index2d_t = uint32_t;

    struct index2d_rect_t {
        index2d_t v[6];
    };

    struct uint_origin {
        uint32_t x = 0;
        uint32_t y = 0;
    };

    struct uint_size {
        uint32_t width = 1;
        uint32_t height = 1;
    };

    struct uint_region {
        uint_origin origin;
        uint_size size;

        uint32_t left() const;
        uint32_t right() const;
        uint32_t bottom() const;
        uint32_t top() const;
    };

    struct uint_range {
        uint32_t location;
        uint32_t length;

        uint32_t min() const;
        uint32_t max() const;
    };

    struct float_origin {
        float x = 0.0f;
        float y = 0.0f;
    };

    struct float_size {
        float width = 0.0f;
        float height = 0.0f;
    };

    struct float_range {
        float location;
        float length;

        float min() const;
        float max() const;
    };

    struct float_region {
        float_origin origin;
        float_size size;

        float_range horizontal_range() const;
        float_range vertical_range() const;
        float left() const;
        float right() const;
        float bottom() const;
        float top() const;
    };

    struct point {
        union {
            struct {
                float x = 0.0f;
                float y = 0.0f;
            };
            simd::float2 v;
        };

        point();
        point(float const x, float const y);
        point(simd::float2);

        bool operator==(point const &rhs) const;
        bool operator!=(point const &rhs) const;

        explicit operator bool() const;
    };

    struct size {
        union {
            struct {
                float width = 0.0f;
                float height = 0.0f;
            };
            simd::float2 v;
        };

        size();
        size(float const w, float const h);
        size(simd::float2);

        bool operator==(size const &rhs) const;
        bool operator!=(size const &rhs) const;

        explicit operator bool() const;
    };

    struct color {
        union {
            struct {
                float red = 1.0f;
                float green = 1.0f;
                float blue = 1.0f;
            };
            simd::float3 v;
        };

        color();
        color(float const r, float const g, float const b);
        color(simd::float3);

        bool operator==(color const &) const;
        bool operator!=(color const &) const;

        explicit operator bool() const;
    };

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
}

simd::float2 to_float2(CGPoint const &);
simd::float2 to_float2(simd::float4 const &);
simd::float4 to_float4(simd::float2 const &);

bool contains(ui::float_region const &, ui::point const &);

std::string to_string(ui::pivot const &);
std::string to_string(ui::uint_origin const &);
std::string to_string(ui::uint_size const &);
std::string to_string(ui::uint_region const &);
std::string to_string(ui::float_origin const &);
std::string to_string(ui::float_size const &);
std::string to_string(ui::float_region const &);
std::string to_string(ui::point const &);
std::string to_string(ui::size const &);
std::string to_string(ui::color const &);
std::string to_string(simd::float2 const &);
std::string to_string(simd::float3 const &);
std::string to_string(simd::float4 const &);
std::string to_string(simd::float4x4 const &);

bool is_equal(simd::float2 const &, simd::float2 const &);
bool is_equal(simd::float3 const &, simd::float3 const &);
bool is_equal(simd::float4 const &, simd::float4 const &);

bool is_equal(simd::float4x4 const &, simd::float4x4 const &);
}

bool operator==(yas::ui::uint_origin const &lhs, yas::ui::uint_origin const &rhs);
bool operator!=(yas::ui::uint_origin const &lhs, yas::ui::uint_origin const &rhs);
bool operator==(yas::ui::uint_size const &lhs, yas::ui::uint_size const &rhs);
bool operator!=(yas::ui::uint_size const &lhs, yas::ui::uint_size const &rhs);
bool operator==(yas::ui::uint_region const &lhs, yas::ui::uint_region const &rhs);
bool operator!=(yas::ui::uint_region const &lhs, yas::ui::uint_region const &rhs);
bool operator==(yas::ui::float_origin const &lhs, yas::ui::float_origin const &rhs);
bool operator!=(yas::ui::float_origin const &lhs, yas::ui::float_origin const &rhs);
bool operator==(yas::ui::float_size const &lhs, yas::ui::float_size const &rhs);
bool operator!=(yas::ui::float_size const &lhs, yas::ui::float_size const &rhs);
bool operator==(yas::ui::float_region const &lhs, yas::ui::float_region const &rhs);
bool operator!=(yas::ui::float_region const &lhs, yas::ui::float_region const &rhs);

std::ostream &operator<<(std::ostream &, yas::ui::uint_origin const &);
std::ostream &operator<<(std::ostream &, yas::ui::uint_size const &);
std::ostream &operator<<(std::ostream &, yas::ui::uint_region const &);
std::ostream &operator<<(std::ostream &, yas::ui::float_origin const &);
std::ostream &operator<<(std::ostream &, yas::ui::float_size const &);
std::ostream &operator<<(std::ostream &, yas::ui::float_region const &);
std::ostream &operator<<(std::ostream &, yas::ui::point const &);
std::ostream &operator<<(std::ostream &, yas::ui::size const &);
std::ostream &operator<<(std::ostream &, yas::ui::color const &);

std::ostream &operator<<(std::ostream &, simd::float2 const &);
std::ostream &operator<<(std::ostream &, simd::float3 const &);
std::ostream &operator<<(std::ostream &, simd::float4 const &);
std::ostream &operator<<(std::ostream &, simd::float4x4 const &);
