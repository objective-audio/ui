//
//  yas_ui_color.cpp
//

#include "yas_ui_color.h"

using namespace yas;

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

bool ui::color::operator==(ui::color const &rhs) const {
    return this->red == rhs.red && this->green == rhs.green && this->blue == rhs.blue;
}

bool ui::color::operator!=(ui::color const &rhs) const {
    return this->red != rhs.red || this->green != rhs.green || this->blue != rhs.blue;
}

ui::color ui::color::operator*(ui::color const &rhs) const {
    return {.red = this->red * rhs.red, .green = this->green * rhs.green, .blue = this->blue * rhs.blue};
}

ui::color ui::color::operator*(float const &rhs) const {
    return {.red = this->red * rhs, .green = this->green * rhs, .blue = this->blue * rhs};
}

ui::color::operator bool() const {
    return this->red != 0 || this->green != 0 || this->blue != 0;
}

simd::float4 yas::to_float4(ui::color const &color, float alpha) {
    return simd::float4{color.red, color.green, color.blue, alpha};
}

std::string yas::to_string(ui::color const &color) {
    return "{" + std::to_string(color.red) + ", " + std::to_string(color.green) + ", " + std::to_string(color.blue) +
           "}";
}

std::ostream &operator<<(std::ostream &os, yas::ui::color const &color) {
    os << to_string(color);
    return os;
}

#pragma mark - static colors

ui::color const &yas::ui::white_color() {
    static ui::color const _color{.red = 1.0f, .green = 1.0f, .blue = 1.0f};
    return _color;
}

ui::color const &yas::ui::gray_color() {
    static ui::color const _color{.red = 0.5f, .green = 0.5f, .blue = 0.5f};
    return _color;
}

ui::color const &yas::ui::dark_gray_color() {
    static ui::color const _color{.red = 0.333f, .green = 0.333f, .blue = 0.333f};
    return _color;
}

ui::color const &yas::ui::light_gray_color() {
    static ui::color const _color{.red = 0.667f, .green = 0.667f, .blue = 0.667f};
    return _color;
}

ui::color const &yas::ui::black_color() {
    static ui::color const _color{.red = 0.0f, .green = 0.0f, .blue = 0.0f};
    return _color;
}

ui::color const &yas::ui::red_color() {
    static ui::color const _color{.red = 1.0f, .green = 0.0f, .blue = 0.0f};
    return _color;
}

ui::color const &yas::ui::green_color() {
    static ui::color const _color{.red = 0.0f, .green = 1.0f, .blue = 0.0f};
    return _color;
}

ui::color const &yas::ui::blue_color() {
    static ui::color const _color{.red = 0.0f, .green = 0.0f, .blue = 1.0f};
    return _color;
}

ui::color const &yas::ui::cyan_color() {
    static ui::color const _color{.red = 0.0f, .green = 1.0f, .blue = 1.0f};
    return _color;
}

ui::color const &yas::ui::yellow_color() {
    static ui::color const _color{.red = 1.0f, .green = 1.0f, .blue = 0.0f};
    return _color;
}

ui::color const &yas::ui::magenta_color() {
    static ui::color const _color{.red = 1.0f, .green = 0.0f, .blue = 1.0f};
    return _color;
}

ui::color const &yas::ui::orange_color() {
    static ui::color const _color{.red = 1.0f, .green = 0.5f, .blue = 0.0f};
    return _color;
}

ui::color const &yas::ui::purple_color() {
    static ui::color const _color{.red = 0.5f, .green = 0.0f, .blue = 0.5f};
    return _color;
}

ui::color const &yas::ui::brown_color() {
    static ui::color const _color{.red = 0.6f, .green = 0.4f, .blue = 0.2f};
    return _color;
}

ui::color yas::ui::hsb_color(float const hue, float const saturation, float const brightness) {
    float const hue_times_six = ui::limit_value(hue) * 6.0f;
    float const hue_fraction = hue_times_six - std::floor(hue_times_six);
    int64_t const int_hue = (int64_t)hue_times_six % 6;
    float const limited_saturation = ui::limit_value(saturation);

    float const max = ui::limit_value(brightness);
    float const min = max * (1.0f - limited_saturation);
    float const fraction = (int_hue % 2) ? (1.0f - hue_fraction) : hue_fraction;
    float const interpolation = min + (max - min) * fraction;

    switch (int_hue) {
        case 0:
            return ui::color{.red = max, .green = interpolation, .blue = min};
        case 1:
            return ui::color{.red = interpolation, .green = max, .blue = min};
        case 2:
            return ui::color{.red = min, .green = max, .blue = interpolation};
        case 3:
            return ui::color{.red = min, .green = interpolation, .blue = max};
        case 4:
            return ui::color{.red = interpolation, .green = min, .blue = max};
        case 5:
            return ui::color{.red = max, .green = min, .blue = interpolation};
        default:
            throw std::runtime_error("unreachable");
    }
}

ui::color yas::ui::hsl_color(float const hue, float const saturation, float const lightness) {
    float const hue_times_six = ui::limit_value(hue) * 6.0f;
    float const hue_fraction = hue_times_six - std::floor(hue_times_six);
    int64_t const int_hue = (int64_t)hue_times_six % 6;
    float const limited_saturation = ui::limit_value(saturation);
    float const limited_lightness = ui::limit_value(lightness);

    float const lightness_multiplier = limited_lightness >= 0.5f ? 1.0f - limited_lightness : limited_lightness;
    float const max = 2.55f * (limited_lightness + lightness_multiplier * limited_saturation);
    float const min = 2.55f * (limited_lightness - lightness_multiplier * limited_saturation);

    float const fraction = (int_hue % 2) ? (1.0f - hue_fraction) : hue_fraction;
    float const interpolation = min + (max - min) * fraction;

    switch (int_hue) {
        case 0:
            return ui::color{.red = max, .green = interpolation, .blue = min};
        case 1:
            return ui::color{.red = interpolation, .green = max, .blue = min};
        case 2:
            return ui::color{.red = min, .green = max, .blue = interpolation};
        case 3:
            return ui::color{.red = min, .green = interpolation, .blue = max};
        case 4:
            return ui::color{.red = interpolation, .green = min, .blue = max};
        case 5:
            return ui::color{.red = max, .green = min, .blue = interpolation};
        default:
            throw std::runtime_error("unreachable");
    }
}
