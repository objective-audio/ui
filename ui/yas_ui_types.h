//
//  yas_ui_types.h
//

#pragma once

#include <CoreGraphics/CoreGraphics.h>
#include <Metal/Metal.h>
#include <simd/simd.h>
#include <ostream>
#include <string>
#include "yas_ui_shared_types.h"

namespace yas {
namespace ui {
    struct vertex2d_square_t {
        vertex2d_t v[4];
    };

    struct index_square_t {
        uint16_t v[6];
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
    };

    struct float_origin {
        float x = 0.0f;
        float y = 0.0f;
    };

    struct float_size {
        float width = 0.0f;
        float height = 0.0f;
    };

    struct float_region {
        float_origin origin;
        float_size size;
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
        point(float const v);
        point(float const x, float const y);
        point(simd::float2 const v);

        bool operator==(point const &rhs) const;
        bool operator!=(point const &rhs) const;

        explicit operator bool() const;
    };

    struct size {
        union {
            struct {
                float w = 0.0f;
                float h = 0.0f;
            };
            simd::float2 v;
        };

        size();
        size(float const v);
        size(float const w, float const h);
        size(simd::float2);

        bool operator==(size const &rhs) const;
        bool operator!=(size const &rhs) const;

        explicit operator bool() const;
    };

    struct color {
        union {
            struct {
                float r = 1.0f;
                float g = 1.0f;
                float b = 1.0f;
            };
            simd::float3 v;
        };

        color();
        color(float const);
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

ui::uint_origin to_uint_origin(MTLOrigin const);
ui::uint_size to_uint_size(MTLSize const);
ui::uint_region to_uint_region(MTLRegion const);

MTLOrigin to_mtl_origin(ui::uint_origin const);
MTLSize to_mtl_size(ui::uint_size const);
MTLRegion to_mtl_region(ui::uint_region const);

MTLPrimitiveType to_mtl_primitive_type(ui::primitive_type const type);

simd::float2 to_float2(CGPoint const &);

bool contains(ui::float_region const &, ui::float_origin const &);
bool contains(ui::float_region const &, simd::float2 const &);

std::string to_string(ui::pivot const &);
std::string to_string(ui::uint_origin const &);
std::string to_string(ui::uint_size const &);
std::string to_string(ui::uint_region const &);
std::string to_string(ui::float_origin const &);
std::string to_string(ui::float_size const &);
std::string to_string(ui::float_region const &);
std::string to_string(simd::float2 const &);
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
