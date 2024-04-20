//
//  yas_ui_types.cpp
//

#include "yas_ui_types.h"

#include <cpp-utils/yas_fast_each.h>

#include <ui/common/yas_ui_shared_type_operators.hpp>

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

uint_size const &uint_size::one() {
    static uint_size const _one{.width = 1, .height = 1};
    return _one;
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

region_positions uint_region::positions() const {
    return region_positions{*this};
}

region_positions uint_region::positions(simd::float4x4 const &matrix) const {
    region_positions positions{*this};
    auto each = make_fast_each(4);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        positions.v[idx] = to_float2(matrix * to_float4(positions.v[idx]));
    }
    return positions;
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

size const &size::one() {
    static size const _one{.width = 1.0f, .height = 1.0f};
    return _one;
}

#pragma mark - range_insets

bool range_insets::operator==(range_insets const &rhs) const {
    return this->min == rhs.min && this->max == rhs.max;
}

bool range_insets::operator!=(range_insets const &rhs) const {
    return !(*this == rhs);
}

range_insets::operator bool() const {
    return this->min != 0.0f && this->max != 0.0f;
}

range_insets const &range_insets::zero() {
    static range_insets const _zero{.min = 0.0f, .max = 0.0f};
    return _zero;
}

#pragma mark - range

bool range::operator==(range const &rhs) const {
    return this->location == rhs.location && this->length == rhs.length;
}

bool range::operator!=(range const &rhs) const {
    return this->location != rhs.location || this->length != rhs.length;
}

range range::operator+(range_insets const &rhs) const {
    float const min = this->min() + rhs.min;
    float const max = this->max() + rhs.max;
    return range{.location = min, .length = max - min};
}

range range::operator-(range_insets const &rhs) const {
    float const min = this->min() - rhs.min;
    float const max = this->max() - rhs.max;
    return range{.location = min, .length = max - min};
}

range &range::operator+=(range_insets const &rhs) {
    *this = *this + rhs;
    return *this;
}

range &range::operator-=(range_insets const &rhs) {
    *this = *this - rhs;
    return *this;
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

range_insets range::insets() const {
    return {.min = this->min(), .max = this->max()};
}

range range::combined(range const &rhs) const {
    float const min = std::min(this->min(), rhs.min());
    float const max = std::max(this->max(), rhs.max());
    return {min, max - min};
}

std::optional<range> range::intersected(range const &rhs) const {
    float const min = std::max(this->min(), rhs.min());
    float const max = std::min(this->max(), rhs.max());

    if (min <= max) {
        return range{min, max - min};
    } else {
        return std::nullopt;
    }
}

range const &range::zero() {
    static range const _zero{.location = 0.0f, .length = 0.0f};
    return _zero;
}

#pragma mark - region_insets

bool region_insets::operator==(region_insets const &rhs) const {
    return this->left == rhs.left && this->right == rhs.right && this->bottom == rhs.bottom && this->top == rhs.top;
}

bool region_insets::operator!=(region_insets const &rhs) const {
    return this->left != rhs.left || this->right != rhs.right || this->bottom != rhs.bottom || this->top != rhs.top;
}

region_insets::operator bool() const {
    return this->left != 0.0f || this->right != 0.0f || this->bottom != 0.0f || this->top != 0.0f;
}

region_insets const &region_insets::zero() {
    static region_insets const _zero{.left = 0.0f, .right = 0.0f, .bottom = 0.0f, .top = 0.0f};
    return _zero;
}

#pragma mark - region

bool region::operator==(region const &rhs) const {
    return this->origin == rhs.origin && this->size == rhs.size;
}

bool region::operator!=(region const &rhs) const {
    return this->origin != rhs.origin || this->size != rhs.size;
}

region region::operator+(ui::region_insets const &rhs) const {
    float const left = this->left() + rhs.left;
    float const right = this->right() + rhs.right;
    float const bottom = this->bottom() + rhs.bottom;
    float const top = this->top() + rhs.top;
    return region{.origin = {left, bottom}, .size = {right - left, top - bottom}};
}

region region::operator-(ui::region_insets const &rhs) const {
    float const left = this->left() - rhs.left;
    float const right = this->right() - rhs.right;
    float const bottom = this->bottom() - rhs.bottom;
    float const top = this->top() - rhs.top;
    return region{.origin = {left, bottom}, .size = {right - left, top - bottom}};
}

region &region::operator+=(ui::region_insets const &rhs) {
    *this = *this + rhs;
    return *this;
}

region &region::operator-=(ui::region_insets const &rhs) {
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

region_insets region::insets() const {
    return ui::region_insets{
        .left = this->left(), .right = this->right(), .bottom = this->bottom(), .top = this->top()};
}

point region::center() const {
    return point{.x = this->origin.x + this->size.width * 0.5f, .y = this->origin.y + this->size.height * 0.5f};
}

region region::combined(region const &rhs) const {
    auto const h_range = this->horizontal_range().combined(rhs.horizontal_range());
    auto const v_range = this->vertical_range().combined(rhs.vertical_range());
    return make_region({.horizontal = h_range, .vertical = v_range});
}

std::optional<region> region::intersected(region const &rhs) const {
    auto const h_range = this->horizontal_range().intersected(rhs.horizontal_range());
    if (!h_range.has_value()) {
        return std::nullopt;
    }

    auto const v_range = this->vertical_range().intersected(rhs.vertical_range());
    if (!v_range.has_value()) {
        return std::nullopt;
    }

    return make_region({.horizontal = h_range.value(), .vertical = v_range.value()});
}

region const &region::zero() {
    static region const _zero{.origin = point::zero(), .size = size::zero()};
    return _zero;
}

region region::zero_centered(ui::size const &size) {
    return region{.origin = {.x = -size.width * 0.5f, .y = -size.height * 0.5f}, .size = size};
}

region region::normalized() const {
    auto const left = this->left();
    auto const bottom = this->bottom();
    return region{.origin = {.x = left, .y = bottom},
                  .size = {.width = this->right() - left, .height = this->top() - bottom}};
}

region_positions region::positions() const {
    return region_positions{*this};
}

region_positions region::positions(simd::float4x4 const &matrix) const {
    region_positions positions{*this};
    auto each = make_fast_each(4);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        positions.v[idx] = to_float2(matrix * to_float4(positions.v[idx]));
    }
    return positions;
}

region ui::make_region(region_ranges_args &&ranges) {
    return region{.origin = {std::move(ranges.horizontal.location), std::move(ranges.vertical.location)},
                  .size = {std::move(ranges.horizontal.length), std::move(ranges.vertical.length)}};
}

#pragma mark - region_positions

region_positions::region_positions(ui::region const &region) {
    this->v[0].x = this->v[2].x = region.origin.x;
    this->v[0].y = this->v[1].y = region.origin.y;
    this->v[1].x = this->v[3].x = region.origin.x + region.size.width;
    this->v[2].y = this->v[3].y = region.origin.y + region.size.height;
}

region_positions::region_positions(uint_region const &region) {
    this->v[0].x = this->v[2].x = region.origin.x;
    this->v[0].y = this->v[1].y = region.origin.y + region.size.height;
    this->v[1].x = this->v[3].x = region.origin.x + region.size.width;
    this->v[2].y = this->v[3].y = region.origin.y;
}

#pragma mark - vertex2d_rect

void vertex2d_rect::set_position(region const &region) {
    this->v[0].position.x = this->v[2].position.x = region.left();
    this->v[0].position.y = this->v[1].position.y = region.bottom();
    this->v[1].position.x = this->v[3].position.x = region.right();
    this->v[2].position.y = this->v[3].position.y = region.top();
}

void vertex2d_rect::set_tex_coord(uint_region const &region) {
    this->v[0].tex_coord.x = this->v[2].tex_coord.x = region.left();
    this->v[0].tex_coord.y = this->v[1].tex_coord.y = region.top();
    this->v[1].tex_coord.x = this->v[3].tex_coord.x = region.right();
    this->v[2].tex_coord.y = this->v[3].tex_coord.y = region.bottom();
}

void vertex2d_rect::set_color(simd::float4 const &color) {
    this->v[0].color = color;
    this->v[1].color = color;
    this->v[2].color = color;
    this->v[3].color = color;
}

void vertex2d_rect::set_color(ui::color const &color) {
    this->set_color(color.v);
}

bool vertex2d_rect::operator==(vertex2d_rect const &rhs) const {
    auto each = make_fast_each(vector_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        if (this->v[idx] != rhs.v[idx]) {
            return false;
        }
    }
    return true;
}

bool vertex2d_rect::operator!=(vertex2d_rect const &rhs) const {
    return !(*this == rhs);
}

#pragma mark - index2d_rect

void index2d_rect::set_all(uint32_t const first) {
    this->v[0] = first;
    this->v[1] = this->v[4] = first + 2;
    this->v[2] = this->v[3] = first + 1;
    this->v[5] = first + 3;
}

bool index2d_rect::operator==(index2d_rect const &rhs) const {
    auto each = make_fast_each(vector_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        if (this->v[idx] != rhs.v[idx]) {
            return false;
        }
    }
    return true;
}

bool index2d_rect::operator!=(index2d_rect const &rhs) const {
    return !(*this == rhs);
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

simd::float2 yas::to_float2(ui::uint_point const &point) {
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

std::string yas::to_string(region_insets const &insets) {
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

std::string yas::to_string(ui::range_insets const &insets) {
    return "{" + std::to_string(insets.min) + ", " + std::to_string(insets.max) + "}";
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
    return simd_equal(lhs, rhs);
}

bool yas::is_equal(simd::float3 const &lhs, simd::float3 const &rhs) {
    return simd_equal(lhs, rhs);
}

bool yas::is_equal(simd::float4 const &lhs, simd::float4 const &rhs) {
    return simd_equal(lhs, rhs);
}

bool yas::is_equal(simd::float4x4 const &lhs, simd::float4x4 const &rhs) {
    return simd_equal(lhs, rhs);
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

std::ostream &operator<<(std::ostream &os, yas::ui::region_insets const &insets) {
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

std::ostream &operator<<(std::ostream &os, yas::ui::range_insets const &insets) {
    os << to_string(insets);
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
