//
//  yas_ui_color.cpp
//

#include "yas_ui_color.h"

using namespace yas;

bool ui::color::operator==(ui::color const &rhs) const {
    return red == rhs.red && green == rhs.green && blue == rhs.blue;
}

bool ui::color::operator!=(ui::color const &rhs) const {
    return red != rhs.red || green != rhs.green || blue != rhs.blue;
}

ui::color::operator bool() const {
    return red != 0 || green != 0 || blue != 0;
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
