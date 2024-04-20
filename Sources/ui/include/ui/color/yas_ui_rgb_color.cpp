//
//  yas_ui_rgb_color.cpp
//

#include "yas_ui_rgb_color.h"

using namespace yas;
using namespace yas::ui;

namespace yas::ui {
static float limit_value(float const value) {
    if (value < 0.0f) {
        return 0.0f;
    } else if (value > 1.0f) {
        return 1.0f;
    } else {
        return value;
    }
}
}  // namespace yas::ui

bool rgb_color::operator==(rgb_color const &rhs) const {
    return this->red == rhs.red && this->green == rhs.green && this->blue == rhs.blue;
}

bool rgb_color::operator!=(rgb_color const &rhs) const {
    return this->red != rhs.red || this->green != rhs.green || this->blue != rhs.blue;
}

rgb_color rgb_color::operator*(rgb_color const &rhs) const {
    return {.red = this->red * rhs.red, .green = this->green * rhs.green, .blue = this->blue * rhs.blue};
}

rgb_color rgb_color::operator*(float const &rhs) const {
    return {.red = this->red * rhs, .green = this->green * rhs, .blue = this->blue * rhs};
}

rgb_color::operator bool() const {
    return this->red != 0 || this->green != 0 || this->blue != 0;
}

simd::float4 yas::to_float4(rgb_color const &color, float alpha) {
    return simd::float4{color.red, color.green, color.blue, alpha};
}

std::string yas::to_string(rgb_color const &color) {
    return "{" + std::to_string(color.red) + ", " + std::to_string(color.green) + ", " + std::to_string(color.blue) +
           "}";
}

std::ostream &operator<<(std::ostream &os, yas::ui::rgb_color const &color) {
    os << to_string(color);
    return os;
}

#pragma mark - static colors

rgb_color const &yas::ui::white_color() {
    static rgb_color const _color{.red = 1.0f, .green = 1.0f, .blue = 1.0f};
    return _color;
}

rgb_color const &yas::ui::gray_color() {
    static rgb_color const _color{.red = 0.5f, .green = 0.5f, .blue = 0.5f};
    return _color;
}

rgb_color const &yas::ui::dark_gray_color() {
    static rgb_color const _color{.red = 0.333f, .green = 0.333f, .blue = 0.333f};
    return _color;
}

rgb_color const &yas::ui::light_gray_color() {
    static rgb_color const _color{.red = 0.667f, .green = 0.667f, .blue = 0.667f};
    return _color;
}

rgb_color const &yas::ui::black_color() {
    static rgb_color const _color{.red = 0.0f, .green = 0.0f, .blue = 0.0f};
    return _color;
}

rgb_color const &yas::ui::red_color() {
    static rgb_color const _color{.red = 1.0f, .green = 0.0f, .blue = 0.0f};
    return _color;
}

rgb_color const &yas::ui::green_color() {
    static rgb_color const _color{.red = 0.0f, .green = 1.0f, .blue = 0.0f};
    return _color;
}

rgb_color const &yas::ui::blue_color() {
    static rgb_color const _color{.red = 0.0f, .green = 0.0f, .blue = 1.0f};
    return _color;
}

rgb_color const &yas::ui::cyan_color() {
    static rgb_color const _color{.red = 0.0f, .green = 1.0f, .blue = 1.0f};
    return _color;
}

rgb_color const &yas::ui::yellow_color() {
    static rgb_color const _color{.red = 1.0f, .green = 1.0f, .blue = 0.0f};
    return _color;
}

rgb_color const &yas::ui::magenta_color() {
    static rgb_color const _color{.red = 1.0f, .green = 0.0f, .blue = 1.0f};
    return _color;
}

rgb_color const &yas::ui::orange_color() {
    static rgb_color const _color{.red = 1.0f, .green = 0.5f, .blue = 0.0f};
    return _color;
}

rgb_color const &yas::ui::purple_color() {
    static rgb_color const _color{.red = 0.5f, .green = 0.0f, .blue = 0.5f};
    return _color;
}

rgb_color const &yas::ui::brown_color() {
    static rgb_color const _color{.red = 0.6f, .green = 0.4f, .blue = 0.2f};
    return _color;
}

rgb_color yas::ui::hsb_color(float const hue, float const saturation, float const brightness) {
    float const hue_times_six = limit_value(hue) * 6.0f;
    float const hue_fraction = hue_times_six - std::floor(hue_times_six);
    int64_t const int_hue = (int64_t)hue_times_six % 6;
    float const limited_saturation = limit_value(saturation);

    float const max = limit_value(brightness);
    float const min = max * (1.0f - limited_saturation);
    float const fraction = (int_hue % 2) ? (1.0f - hue_fraction) : hue_fraction;
    float const interpolation = min + (max - min) * fraction;

    switch (int_hue) {
        case 0:
            return rgb_color{.red = max, .green = interpolation, .blue = min};
        case 1:
            return rgb_color{.red = interpolation, .green = max, .blue = min};
        case 2:
            return rgb_color{.red = min, .green = max, .blue = interpolation};
        case 3:
            return rgb_color{.red = min, .green = interpolation, .blue = max};
        case 4:
            return rgb_color{.red = interpolation, .green = min, .blue = max};
        case 5:
            return rgb_color{.red = max, .green = min, .blue = interpolation};
        default:
            throw std::runtime_error("unreachable");
    }
}

rgb_color yas::ui::hsl_color(float const hue, float const saturation, float const lightness) {
    float const hue_times_six = limit_value(hue) * 6.0f;
    float const hue_fraction = hue_times_six - std::floor(hue_times_six);
    int64_t const int_hue = (int64_t)hue_times_six % 6;
    float const limited_saturation = limit_value(saturation);
    float const limited_lightness = limit_value(lightness);

    float const abs = std::fabs(2.0f * limited_lightness - 1.0f);
    float const diff = limited_saturation * (1.0f - abs) * 0.5f;
    float const max = limited_lightness + diff;
    float const min = limited_lightness - diff;

    float const fraction = (int_hue % 2) ? (1.0f - hue_fraction) : hue_fraction;
    float const interpolation = min + (max - min) * fraction;

    switch (int_hue) {
        case 0:
            return rgb_color{.red = max, .green = interpolation, .blue = min};
        case 1:
            return rgb_color{.red = interpolation, .green = max, .blue = min};
        case 2:
            return rgb_color{.red = min, .green = max, .blue = interpolation};
        case 3:
            return rgb_color{.red = min, .green = interpolation, .blue = max};
        case 4:
            return rgb_color{.red = interpolation, .green = min, .blue = max};
        case 5:
            return rgb_color{.red = max, .green = min, .blue = interpolation};
        default:
            throw std::runtime_error("unreachable");
    }
}
