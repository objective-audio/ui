//
//  yas_ui_color.h
//

#pragma once

#include <simd/simd.h>
#include <ostream>
#include <string>

namespace yas {
namespace ui {
    struct color {
        union {
            struct {
                float red;
                float green;
                float blue;
            };
            simd::float3 v;
        };

        bool operator==(color const &rhs) const;
        bool operator!=(color const &rhs) const;

        explicit operator bool() const;
    };

    ui::color const &white_color();
    ui::color const &black_color();
    ui::color const &gray_color();
    ui::color const &dark_gray_color();
    ui::color const &light_gray_color();
    ui::color const &red_color();
    ui::color const &green_color();
    ui::color const &blue_color();
    ui::color const &cyan_color();
    ui::color const &yellow_color();
    ui::color const &magenta_color();
    ui::color const &orange_color();
    ui::color const &purple_color();
    ui::color const &brown_color();
}

std::string to_string(ui::color const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::color const &);
