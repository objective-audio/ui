
//
//  yas_ui_collider.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <ui/yas_ui_collider_protocol.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_types.h>

#include <string>

namespace yas::ui {
struct anywhere_shape final {
    bool hit_test(ui::point const &) const;
};

struct circle_shape final {
    ui::point center = {.v = 0.0f};
    float radius = 0.5f;

    bool hit_test(ui::point const &) const;
};

struct rect_shape final {
    ui::region rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}};

    bool hit_test(ui::point const &pos) const;
};

struct shape final {
    class impl_base;

    template <typename T>
    class impl;

    struct anywhere {
        using type = anywhere_shape;
    };

    struct circle {
        using type = circle_shape;
    };

    struct rect {
        using type = rect_shape;
    };

    virtual ~shape();

    std::type_info const &type_info() const;

    bool hit_test(ui::point const &) const;

    template <typename T>
    typename T::type const &get() const;

    [[nodiscard]] static shape_ptr make_shared(anywhere::type);
    [[nodiscard]] static shape_ptr make_shared(circle::type);
    [[nodiscard]] static shape_ptr make_shared(rect::type);

   private:
    std::shared_ptr<impl_base> _impl;

    explicit shape(anywhere::type &&);
    explicit shape(circle::type &&);
    explicit shape(rect::type &&);

    shape(shape const &) = delete;
    shape(shape &&) = delete;
    shape &operator=(shape const &) = delete;
    shape &operator=(shape &&) = delete;
};

struct collider final : renderable_collider {
    virtual ~collider();

    void set_shape(ui::shape_ptr);
    ui::shape_ptr const &shape() const;

    void set_enabled(bool const);
    bool is_enabled() const;

    bool hit_test(ui::point const &) const;

    [[nodiscard]] observing::canceller_ptr observe_shape(observing::caller<ui::shape_ptr>::handler_f &&,
                                                         bool const sync);
    [[nodiscard]] observing::canceller_ptr observe_enabled(observing::caller<bool>::handler_f &&, bool const sync);

    [[nodiscard]] static collider_ptr make_shared();
    [[nodiscard]] static collider_ptr make_shared(ui::shape_ptr);

   private:
    simd::float4x4 _matrix = matrix_identity_float4x4;

    observing::value::holder_ptr<ui::shape_ptr> const _shape;
    observing::value::holder_ptr<bool> const _enabled = observing::value::holder<bool>::make_shared(true);

    explicit collider(ui::shape_ptr &&);

    simd::float4x4 const &matrix() const override;
    void set_matrix(simd::float4x4 const &) override;
};
}  // namespace yas::ui
