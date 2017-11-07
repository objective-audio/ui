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

    struct uint_point {
        uint32_t x = 0;
        uint32_t y = 0;

        bool operator==(uint_point const &rhs) const;
        bool operator!=(uint_point const &rhs) const;

        static uint_point const &zero();
    };

    struct uint_size {
        uint32_t width = 1;
        uint32_t height = 1;

        bool operator==(uint_size const &rhs) const;
        bool operator!=(uint_size const &rhs) const;

        static uint_size const &zero();
    };

    struct uint_region {
        uint_point origin;
        uint_size size;

        bool operator==(uint_region const &rhs) const;
        bool operator!=(uint_region const &rhs) const;

        uint32_t left() const;
        uint32_t right() const;
        uint32_t bottom() const;
        uint32_t top() const;

        static uint_region const &zero();
    };

    struct uint_range {
        uint32_t location;
        uint32_t length;

        bool operator==(uint_range const &rhs) const;
        bool operator!=(uint_range const &rhs) const;

        uint32_t min() const;
        uint32_t max() const;

        static uint_range const &zero();
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

        explicit operator bool() const;

        static point const &zero();
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

        static size const &zero();
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

        explicit operator bool() const;

        float min() const;
        float max() const;

        static range const &zero();
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

        explicit operator bool() const;

        range horizontal_range() const;
        range vertical_range() const;
        float left() const;
        float right() const;
        float bottom() const;
        float top() const;
        point center() const;

        static region const &zero();
        static region zero_centered(ui::size const &);
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

    struct vertex2d_rect_t {
        vertex2d_t v[4];

        void set_position(ui::region const &);
        void set_tex_coord(ui::uint_region const &);
    };

    using index2d_t = uint32_t;

    struct index2d_rect_t {
        index2d_t v[6];
    };
}

simd::float2 to_float2(CGPoint const &);
simd::float2 to_float2(simd::float4 const &);
simd::float4 to_float4(simd::float2 const &);

bool contains(ui::region const &, ui::point const &);

std::string to_string(ui::pivot const &);
std::string to_string(ui::uint_point const &);
std::string to_string(ui::uint_size const &);
std::string to_string(ui::uint_region const &);
std::string to_string(ui::region const &);
std::string to_string(ui::point const &);
std::string to_string(ui::size const &);
std::string to_string(simd::float2 const &);
std::string to_string(simd::float3 const &);
std::string to_string(simd::float4 const &);
std::string to_string(simd::float4x4 const &);

bool is_equal(simd::float2 const &, simd::float2 const &);
bool is_equal(simd::float3 const &, simd::float3 const &);
bool is_equal(simd::float4 const &, simd::float4 const &);

bool is_equal(simd::float4x4 const &, simd::float4x4 const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::uint_point const &);
std::ostream &operator<<(std::ostream &, yas::ui::uint_size const &);
std::ostream &operator<<(std::ostream &, yas::ui::uint_region const &);
std::ostream &operator<<(std::ostream &, yas::ui::region const &);
std::ostream &operator<<(std::ostream &, yas::ui::point const &);
std::ostream &operator<<(std::ostream &, yas::ui::size const &);

std::ostream &operator<<(std::ostream &, simd::float2 const &);
std::ostream &operator<<(std::ostream &, simd::float3 const &);
std::ostream &operator<<(std::ostream &, simd::float4 const &);
std::ostream &operator<<(std::ostream &, simd::float4x4 const &);
