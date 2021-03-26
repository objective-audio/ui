//
//  yas_ui_types.cpp
//

#include "yas_ui_types.h"

using namespace yas;
using namespace yas::ui;

#pragma mark - uint_point

bool uint_point::operator==(uint_point const &rhs) const {
    return this->x == rhs.x && this->y == rhs.y;
}

bool uint_point::operator!=(uint_point const &rhs) const {
    return this->x != rhs.x || this->y != rhs.y;
}

uint_point const &uint_point::zero() {
    static uint_point const _zero{.x = 0, .y = 0};
    return _zero;
}

#pragma mark - uint_size

bool uint_size::operator==(uint_size const &rhs) const {
    return this->width == rhs.width && this->height == rhs.height;
}

bool uint_size::operator!=(uint_size const &rhs) const {
    return this->width != rhs.width || this->height != rhs.height;
}

uint_size const &uint_size::zero() {
    static uint_size const _zero{.width = 0, .height = 0};
    return _zero;
}

#pragma mark - uint_region

bool uint_region::operator==(uint_region const &rhs) const {
    return this->origin == rhs.origin && this->size == rhs.size;
}

bool uint_region::operator!=(uint_region const &rhs) const {
    return this->origin != rhs.origin || this->size != rhs.size;
}

uint32_t uint_region::left() const {
    return std::min(this->origin.x, origin.x + this->size.width);
}

uint32_t uint_region::right() const {
    return std::max(this->origin.x, origin.x + this->size.width);
}

uint32_t uint_region::bottom() const {
    return std::min(this->origin.y, origin.y + this->size.height);
}

uint32_t uint_region::top() const {
    return std::max(this->origin.y, origin.y + this->size.height);
}

uint_region const &uint_region::zero() {
    static uint_region const _zero{.origin = uint_point::zero(), .size = uint_size::zero()};
    return _zero;
}

#pragma mark - ui:uint_range

bool uint_range::operator==(uint_range const &rhs) const {
    return this->location == rhs.location && this->length == rhs.length;
}

bool uint_range::operator!=(uint_range const &rhs) const {
    return this->location != rhs.location || this->length != rhs.length;
}

uint32_t uint_range::min() const {
    return std::min(this->location, this->location + this->length);
}

uint32_t uint_range::max() const {
    return std::max(this->location, this->location + this->length);
}

uint_range const &uint_range::zero() {
    static uint_range const _zero{.location = 0, .length = 0};
    return _zero;
}

#pragma mark - point

bool point::operator==(point const &rhs) const {
    return this->x == rhs.x && this->y == rhs.y;
}

bool point::operator!=(point const &rhs) const {
    return this->x != rhs.x || this->y != rhs.y;
}

point point::operator+(point const &rhs) const {
    return {.x = this->x + rhs.x, .y = this->y + rhs.y};
}

point point::operator-(point const &rhs) const {
    return {.x = this->x - rhs.x, .y = this->y - rhs.y};
}

point &point::operator+=(point const &rhs) {
    this->x += rhs.x;
    this->y += rhs.y;
    return *this;
}

point &point::operator-=(point const &rhs) {
    this->x -= rhs.x;
    this->y -= rhs.y;
    return *this;
}

point::operator bool() const {
    return this->x != 0.0f || this->y != 0.0f;
}

point const &point::zero() {
    static point const _zero{.x = 0.0f, .y = 0.0f};
    return _zero;
}

#pragma mark - size

bool size::operator==(size const &rhs) const {
    return this->width == rhs.width && this->height == rhs.height;
}

bool size::operator!=(size const &rhs) const {
    return this->width != rhs.width || this->height != rhs.height;
}

size::operator bool() const {
    return this->width != 0.0f || this->height != 0.0f;
}

size const &size::zero() {
    static size const _zero{.width = 0.0f, .height = 0.0f};
    return _zero;
}

#pragma mark - range

bool range::operator==(range const &rhs) const {
    return this->location == rhs.location && this->length == rhs.length;
}

bool range::operator!=(range const &rhs) const {
    return this->location != rhs.location || this->length != rhs.length;
}

range::operator bool() const {
    return this->location != 0.0f || this->length != 0.0f;
}

float range::min() const {
    return std::min(this->location, this->location + this->length);
}

float range::max() const {
    return std::max(this->location, this->location + this->length);
}

range const &range::zero() {
    static range const _zero{.location = 0.0f, .length = 0.0f};
    return _zero;
}

#pragma mark - insets

bool insets::operator==(insets const &rhs) const {
    return this->left == rhs.left && this->right == rhs.right && this->bottom == rhs.bottom && this->top == rhs.top;
}

bool insets::operator!=(insets const &rhs) const {
    return this->left != rhs.left || this->right != rhs.right || this->bottom != rhs.bottom || this->top != rhs.top;
}

insets::operator bool() const {
    return this->left != 0.0f || this->right != 0.0f || this->bottom != 0.0f || this->top != 0.0f;
}

insets const &insets::zero() {
    static insets const _zero{.left = 0.0f, .right = 0.0f, .bottom = 0.0f, .top = 0.0f};
    return _zero;
}

#pragma mark - region

bool region::operator==(region const &rhs) const {
    return this->origin == rhs.origin && this->size == rhs.size;
}

bool region::operator!=(region const &rhs) const {
    return this->origin != rhs.origin || this->size != rhs.size;
}

region region::operator+(ui::insets const &rhs) const {
    float const left = this->left() + rhs.left;
    float const right = this->right() + rhs.right;
    float const bottom = this->bottom() + rhs.bottom;
    float const top = this->top() + rhs.top;
    return region{.origin = {left, bottom}, .size = {right - left, top - bottom}};
}

region region::operator-(ui::insets const &rhs) const {
    float const left = this->left() - rhs.left;
    float const right = this->right() - rhs.right;
    float const bottom = this->bottom() - rhs.bottom;
    float const top = this->top() - rhs.top;
    return region{.origin = {left, bottom}, .size = {right - left, top - bottom}};
}

region &region::operator+=(ui::insets const &rhs) {
    *this = *this + rhs;
    return *this;
}

region &region::operator-=(ui::insets const &rhs) {
    *this = *this - rhs;
    return *this;
}

region::operator bool() const {
    return this->origin || this->size;
}

range region::horizontal_range() const {
    return range{.location = this->origin.x, .length = this->size.width};
}

range region::vertical_range() const {
    return range{.location = this->origin.y, .length = this->size.height};
}

float region::left() const {
    return std::min(this->origin.x, this->origin.x + this->size.width);
}

float region::right() const {
    return std::max(this->origin.x, this->origin.x + this->size.width);
}

float region::bottom() const {
    return std::min(this->origin.y, this->origin.y + this->size.height);
}

float region::top() const {
    return std::max(this->origin.y, this->origin.y + this->size.height);
}

insets region::insets() const {
    return ui::insets{.left = this->left(), .right = this->right(), .bottom = this->bottom(), .top = this->top()};
}

point region::center() const {
    return point{.x = this->origin.x + this->size.width * 0.5f, .y = this->origin.y + this->size.height * 0.5f};
}

region const &region::zero() {
    static region const _zero{.origin = point::zero(), .size = size::zero()};
    return _zero;
}

region region::zero_centered(ui::size const &size) {
    return region{.origin = {.x = -size.width * 0.5f, .y = -size.height * 0.5f}, .size = size};
}

region ui::make_region(range const &horizontal, range const &vertical) {
    return region{.origin = {horizontal.location, vertical.location}, .size = {horizontal.length, vertical.length}};
}

#pragma mark - vertex2d_rect_t

void vertex2d_rect_t::set_position(region const &region) {
    this->v[0].position.x = this->v[2].position.x = region.left();
    this->v[0].position.y = this->v[1].position.y = region.bottom();
    this->v[1].position.x = this->v[3].position.x = region.right();
    this->v[2].position.y = this->v[3].position.y = region.top();
}

void vertex2d_rect_t::set_tex_coord(uint_region const &region) {
    this->v[0].tex_coord.x = this->v[2].tex_coord.x = region.left();
    this->v[0].tex_coord.y = this->v[1].tex_coord.y = region.top();
    this->v[1].tex_coord.x = this->v[3].tex_coord.x = region.right();
    this->v[2].tex_coord.y = this->v[3].tex_coord.y = region.bottom();
}

#pragma mark -

point ui::to_point(uint_point const &uint_point) {
    return point{.x = static_cast<float>(uint_point.x), .y = static_cast<float>(uint_point.y)};
}

size ui::to_size(uint_size const &uint_size) {
    return size{.width = static_cast<float>(uint_size.width), .height = static_cast<float>(uint_size.height)};
}

range ui::to_range(uint_range const &uint_range) {
    return range{.location = static_cast<float>(uint_range.location), .length = static_cast<float>(uint_range.length)};
}

region ui::to_region(uint_region const &uint_region) {
    return region{.origin = ui::to_point(uint_region.origin), .size = ui::to_size(uint_region.size)};
}

#pragma mark -

simd::float2 yas::to_float2(CGPoint const &point) {
    return simd::float2{static_cast<float>(point.x), static_cast<float>(point.y)};
}

simd::float2 yas::to_float2(simd::float4 const &vec) {
    return simd::float2{vec.x, vec.y};
}

simd::float4 yas::to_float4(simd::float2 const &vec) {
    return simd::float4{vec.x, vec.y, 0.0f, 1.0f};
}

bool yas::contains(region const &region, point const &pos) {
    float const sum_x = region.origin.x + region.size.width;
    float const min_x = std::min(region.origin.x, sum_x);
    float const max_x = std::max(region.origin.x, sum_x);
    float const sum_y = region.origin.y + region.size.height;
    float const min_y = std::min(region.origin.y, sum_y);
    float const max_y = std::max(region.origin.y, sum_y);

    return min_x <= pos.x && pos.x < max_x && min_y <= pos.y && pos.y < max_y;
}

std::string yas::to_string(pivot const &pivot) {
    switch (pivot) {
        case pivot::left:
            return "left";
        case pivot::center:
            return "center";
        case pivot::right:
            return "right";
    }
}

std::string yas::to_string(uint_point const &point) {
    return "{" + std::to_string(point.x) + ", " + std::to_string(point.y) + "}";
}

std::string yas::to_string(uint_size const &size) {
    return "{" + std::to_string(size.width) + ", " + std::to_string(size.height) + "}";
}

std::string yas::to_string(uint_region const &region) {
    return "{" + to_string(region.origin) + ", " + to_string(region.size) + "}";
}

std::string yas::to_string(insets const &insets) {
    return "{" + std::to_string(insets.left) + ", " + std::to_string(insets.right) + ", " +
           std::to_string(insets.bottom) + ", " + std::to_string(insets.top) + "}";
}

std::string yas::to_string(region const &region) {
    return "{" + to_string(region.origin) + ", " + to_string(region.size) + "}";
}

std::string yas::to_string(point const &point) {
    return "{" + std::to_string(point.x) + ", " + std::to_string(point.y) + "}";
}

std::string yas::to_string(size const &size) {
    return "{" + std::to_string(size.width) + ", " + std::to_string(size.height) + "}";
}

std::string yas::to_string(range const &range) {
    return "{" + std::to_string(range.location) + ", " + std::to_string(range.length) + "}";
}

std::string yas::to_string(appearance const &appearance) {
    switch (appearance) {
        case appearance::normal:
            return "normal";
        case appearance::dark:
            return "dark";
    }
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

std::ostream &operator<<(std::ostream &os, yas::ui::appearance const &appearance) {
    os << to_string(appearance);
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