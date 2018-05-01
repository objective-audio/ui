//
//  yas_ui_types.cpp
//

#include "yas_ui_types.h"

using namespace yas;

#pragma mark - ui::uint_point

bool ui::uint_point::operator==(ui::uint_point const &rhs) const {
    return this->x == rhs.x && this->y == rhs.y;
}

bool ui::uint_point::operator!=(ui::uint_point const &rhs) const {
    return this->x != rhs.x || this->y != rhs.y;
}

ui::uint_point const &ui::uint_point::zero() {
    static ui::uint_point const _zero{.x = 0, .y = 0};
    return _zero;
}

#pragma mark - ui::uint_size

bool ui::uint_size::operator==(ui::uint_size const &rhs) const {
    return this->width == rhs.width && this->height == rhs.height;
}

bool ui::uint_size::operator!=(ui::uint_size const &rhs) const {
    return this->width != rhs.width || this->height != rhs.height;
}

ui::uint_size const &ui::uint_size::zero() {
    static ui::uint_size const _zero{.width = 0, .height = 0};
    return _zero;
}

#pragma mark - ui::uint_region

bool ui::uint_region::operator==(ui::uint_region const &rhs) const {
    return this->origin == rhs.origin && this->size == rhs.size;
}

bool ui::uint_region::operator!=(ui::uint_region const &rhs) const {
    return this->origin != rhs.origin || this->size != rhs.size;
}

uint32_t ui::uint_region::left() const {
    return std::min(this->origin.x, origin.x + this->size.width);
}

uint32_t ui::uint_region::right() const {
    return std::max(this->origin.x, origin.x + this->size.width);
}

uint32_t ui::uint_region::bottom() const {
    return std::min(this->origin.y, origin.y + this->size.height);
}

uint32_t ui::uint_region::top() const {
    return std::max(this->origin.y, origin.y + this->size.height);
}

ui::uint_region const &ui::uint_region::zero() {
    static ui::uint_region const _zero{.origin = ui::uint_point::zero(), .size = ui::uint_size::zero()};
    return _zero;
}

#pragma mark - ui:uint_range

bool ui::uint_range::operator==(uint_range const &rhs) const {
    return this->location == rhs.location && this->length == rhs.length;
}

bool ui::uint_range::operator!=(uint_range const &rhs) const {
    return this->location != rhs.location || this->length != rhs.length;
}

uint32_t ui::uint_range::min() const {
    return std::min(this->location, this->location + this->length);
}

uint32_t ui::uint_range::max() const {
    return std::max(this->location, this->location + this->length);
}

ui::uint_range const &ui::uint_range::zero() {
    static ui::uint_range const _zero{.location = 0, .length = 0};
    return _zero;
}

#pragma mark - ui::point

bool ui::point::operator==(ui::point const &rhs) const {
    return this->x == rhs.x && this->y == rhs.y;
}

bool ui::point::operator!=(ui::point const &rhs) const {
    return this->x != rhs.x || this->y != rhs.y;
}

ui::point ui::point::operator+(point const &rhs) const {
    return {.x = this->x + rhs.x, .y = this->y + rhs.y};
}

ui::point ui::point::operator-(point const &rhs) const {
    return {.x = this->x - rhs.x, .y = this->y - rhs.y};
}

ui::point &ui::point::operator+=(point const &rhs) {
    this->x += rhs.x;
    this->y += rhs.y;
    return *this;
}

ui::point &ui::point::operator-=(point const &rhs) {
    this->x -= rhs.x;
    this->y -= rhs.y;
    return *this;
}

ui::point::operator bool() const {
    return this->x != 0.0f || this->y != 0.0f;
}

ui::point const &ui::point::zero() {
    static ui::point const _zero{.x = 0.0f, .y = 0.0f};
    return _zero;
}

#pragma mark - ui::size

bool ui::size::operator==(ui::size const &rhs) const {
    return this->width == rhs.width && this->height == rhs.height;
}

bool ui::size::operator!=(ui::size const &rhs) const {
    return this->width != rhs.width || this->height != rhs.height;
}

ui::size::operator bool() const {
    return this->width != 0.0f || this->height != 0.0f;
}

ui::size const &ui::size::zero() {
    static ui::size const _zero{.width = 0.0f, .height = 0.0f};
    return _zero;
}

#pragma mark - ui::range

bool ui::range::operator==(ui::range const &rhs) const {
    return this->location == rhs.location && this->length == rhs.length;
}

bool ui::range::operator!=(ui::range const &rhs) const {
    return this->location != rhs.location || this->length != rhs.length;
}

ui::range::operator bool() const {
    return this->location != 0.0f || this->length != 0.0f;
}

float ui::range::min() const {
    return std::min(this->location, this->location + this->length);
}

float ui::range::max() const {
    return std::max(this->location, this->location + this->length);
}

ui::range const &ui::range::zero() {
    static ui::range const _zero{.location = 0.0f, .length = 0.0f};
    return _zero;
}

#pragma mark - insets

bool ui::insets::operator==(insets const &rhs) const {
    return this->left == rhs.left && this->right == rhs.right && this->bottom == rhs.bottom && this->top == rhs.top;
}

bool ui::insets::operator!=(insets const &rhs) const {
    return this->left != rhs.left || this->right != rhs.right || this->bottom != rhs.bottom || this->top != rhs.top;
}

ui::insets::operator bool() const {
    return this->left != 0.0f || this->right != 0.0f || this->bottom != 0.0f || this->top != 0.0f;
}

ui::insets const &ui::insets::zero() {
    static ui::insets const _zero{.left = 0.0f, .right = 0.0f, .bottom = 0.0f, .top = 0.0f};
    return _zero;
}

#pragma mark - ui::region

bool ui::region::operator==(ui::region const &rhs) const {
    return this->origin == rhs.origin && this->size == rhs.size;
}

bool ui::region::operator!=(ui::region const &rhs) const {
    return this->origin != rhs.origin || this->size != rhs.size;
}

ui::region::operator bool() const {
    return this->origin || this->size;
}

ui::range ui::region::horizontal_range() const {
    return ui::range{.location = this->origin.x, .length = this->size.width};
}

ui::range ui::region::vertical_range() const {
    return ui::range{.location = this->origin.y, .length = this->size.height};
}

float ui::region::left() const {
    return std::min(this->origin.x, this->origin.x + this->size.width);
}

float ui::region::right() const {
    return std::max(this->origin.x, this->origin.x + this->size.width);
}

float ui::region::bottom() const {
    return std::min(this->origin.y, this->origin.y + this->size.height);
}

float ui::region::top() const {
    return std::max(this->origin.y, this->origin.y + this->size.height);
}

ui::insets ui::region::insets() const {
    return ui::insets{.left = this->left(), .right = this->right(), .bottom = this->bottom(), .top = this->top()};
}

ui::point ui::region::center() const {
    return ui::point{.x = this->origin.x + this->size.width * 0.5f, .y = this->origin.y + this->size.height * 0.5f};
}

ui::region const &ui::region::zero() {
    static ui::region const _zero{.origin = ui::point::zero(), .size = ui::size::zero()};
    return _zero;
}

ui::region ui::region::zero_centered(ui::size const &size) {
    return ui::region{.origin = {.x = -size.width * 0.5f, .y = -size.height * 0.5f}, .size = size};
}

#pragma mark - vertex2d_rect_t

void ui::vertex2d_rect_t::set_position(ui::region const &region) {
    this->v[0].position.x = this->v[2].position.x = region.left();
    this->v[0].position.y = this->v[1].position.y = region.bottom();
    this->v[1].position.x = this->v[3].position.x = region.right();
    this->v[2].position.y = this->v[3].position.y = region.top();
}

void ui::vertex2d_rect_t::set_tex_coord(ui::uint_region const &region) {
    this->v[0].tex_coord.x = this->v[2].tex_coord.x = region.left();
    this->v[0].tex_coord.y = this->v[1].tex_coord.y = region.top();
    this->v[1].tex_coord.x = this->v[3].tex_coord.x = region.right();
    this->v[2].tex_coord.y = this->v[3].tex_coord.y = region.bottom();
}

#pragma mark -

ui::region yas::make_region(ui::range const &horizontal, ui::range const &vertical) {
    return ui::region{.origin = {horizontal.location, vertical.location}, .size = {horizontal.length, vertical.length}};
}

simd::float2 yas::to_float2(CGPoint const &point) {
    return simd::float2{static_cast<float>(point.x), static_cast<float>(point.y)};
}

simd::float2 yas::to_float2(simd::float4 const &vec) {
    return simd::float2{vec.x, vec.y};
}

simd::float4 yas::to_float4(simd::float2 const &vec) {
    return simd::float4{vec.x, vec.y, 0.0f, 1.0f};
}

bool yas::contains(ui::region const &region, ui::point const &pos) {
    float const sum_x = region.origin.x + region.size.width;
    float const min_x = std::min(region.origin.x, sum_x);
    float const max_x = std::max(region.origin.x, sum_x);
    float const sum_y = region.origin.y + region.size.height;
    float const min_y = std::min(region.origin.y, sum_y);
    float const max_y = std::max(region.origin.y, sum_y);

    return min_x <= pos.x && pos.x < max_x && min_y <= pos.y && pos.y < max_y;
}

std::string yas::to_string(ui::pivot const &pivot) {
    switch (pivot) {
        case ui::pivot::left:
            return "left";
        case ui::pivot::center:
            return "center";
        case ui::pivot::right:
            return "right";
    }
}

std::string yas::to_string(ui::uint_point const &point) {
    return "{" + std::to_string(point.x) + ", " + std::to_string(point.y) + "}";
}

std::string yas::to_string(ui::uint_size const &size) {
    return "{" + std::to_string(size.width) + ", " + std::to_string(size.height) + "}";
}

std::string yas::to_string(ui::uint_region const &region) {
    return "{" + to_string(region.origin) + ", " + to_string(region.size) + "}";
}

std::string yas::to_string(ui::insets const &insets) {
    return "{" + std::to_string(insets.left) + ", " + std::to_string(insets.right) + ", " +
           std::to_string(insets.bottom) + ", " + std::to_string(insets.top) + "}";
}

std::string yas::to_string(ui::region const &region) {
    return "{" + to_string(region.origin) + ", " + to_string(region.size) + "}";
}

std::string yas::to_string(ui::point const &point) {
    return "{" + std::to_string(point.x) + ", " + std::to_string(point.y) + "}";
}

std::string yas::to_string(ui::size const &size) {
    return "{" + std::to_string(size.width) + ", " + std::to_string(size.height) + "}";
}

std::string yas::to_string(ui::range const &range) {
    return "{" + std::to_string(range.location) + ", " + std::to_string(range.length) + "}";
}

std::string yas::to_string(simd::float2 const &value) {
    return "{" + std::to_string(value.x) + ", " + std::to_string(value.y) + "}";
}

std::string yas::to_string(simd::float3 const &value) {
    return "{" + std::to_string(value.x) + ", " + std::to_string(value.y) + ", " + std::to_string(value.z) + "}";
}

std::string yas::to_string(simd::float4 const &value) {
    return "{" + std::to_string(value.x) + ", " + std::to_string(value.y) + ", " + std::to_string(value.z) + ", " +
           std::to_string(value.w) + "}";
}

std::string yas::to_string(simd::float4x4 const &matrix) {
    return "{" + to_string(matrix.columns[0]) + ", " + to_string(matrix.columns[1]) + ", " +
           to_string(matrix.columns[2]) + ", " + to_string(matrix.columns[3]) + "}";
}

#pragma mark -

bool yas::is_equal(simd::float2 const &lhs, simd::float2 const &rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y;
}

bool yas::is_equal(simd::float3 const &lhs, simd::float3 const &rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z;
}

bool yas::is_equal(simd::float4 const &lhs, simd::float4 const &rhs) {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w;
}

bool yas::is_equal(simd::float4x4 const &lhs, simd::float4x4 const &rhs) {
    return (&lhs == &rhs) || memcmp(&lhs, &rhs, sizeof(simd::float4x4)) == 0;
}

#pragma mark -

std::ostream &operator<<(std::ostream &os, yas::ui::uint_point const &point) {
    os << to_string(point);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::uint_size const &size) {
    os << to_string(size);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::uint_region const &region) {
    os << to_string(region);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::insets const &insets) {
    os << to_string(insets);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::region const &region) {
    os << to_string(region);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::point const &point) {
    os << to_string(point);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::size const &size) {
    os << to_string(size);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::range const &range) {
    os << to_string(range);
    return os;
}

std::ostream &operator<<(std::ostream &os, simd::float2 const &vec) {
    os << to_string(vec);
    return os;
}

std::ostream &operator<<(std::ostream &os, simd::float3 const &vec) {
    os << to_string(vec);
    return os;
}

std::ostream &operator<<(std::ostream &os, simd::float4 const &vec) {
    os << to_string(vec);
    return os;
}

std::ostream &operator<<(std::ostream &os, simd::float4x4 const &mat) {
    os << to_string(mat);
    return os;
}
