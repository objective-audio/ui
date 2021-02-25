//
//  yas_ui_color.h
//

#pragma once

#include <simd/simd.h>

#include <ostream>
#include <string>

namespace yas::ui {
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
    color operator*(color const &rhs) const;
    color operator*(float const &rhs) const;

    explicit operator bool() const;
};

[[nodiscard]] ui::color const &white_color();
[[nodiscard]] ui::color const &black_color();
[[nodiscard]] ui::color const &gray_color();
[[nodiscard]] ui::color const &dark_gray_color();
[[nodiscard]] ui::color const &light_gray_color();
[[nodiscard]] ui::color const &red_color();
[[nodiscard]] ui::color const &green_color();
[[nodiscard]] ui::color const &blue_color();
[[nodiscard]] ui::color const &cyan_color();
[[nodiscard]] ui::color const &yellow_color();
[[nodiscard]] ui::color const &magenta_color();
[[nodiscard]] ui::color const &orange_color();
[[nodiscard]] ui::color const &purple_color();
[[nodiscard]] ui::color const &brown_color();

ui::color hsb_color(float const hue, float const saturation, float const brightness);
ui::color hsl_color(float const hue, float const saturation, float const lightness);
}  // namespace yas::ui

namespace yas {
simd::float4 to_float4(ui::color const &, float alpha);

std::string to_string(ui::color const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::color const &);
