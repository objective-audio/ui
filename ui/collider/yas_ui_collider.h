
//
//  yas_ui_collider.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_renderer_dependency.h>
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

    [[nodiscard]] std::type_info const &type_info() const;

    [[nodiscard]] bool hit_test(ui::point const &) const;

    [[nodiscard]] static std::shared_ptr<shape> make_shared(anywhere::type);
    [[nodiscard]] static std::shared_ptr<shape> make_shared(circle::type);
    [[nodiscard]] static std::shared_ptr<shape> make_shared(rect::type);

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

    void set_shape(std::shared_ptr<shape>);
    [[nodiscard]] std::shared_ptr<shape> const &shape() const;

    void set_enabled(bool const);
    [[nodiscard]] bool is_enabled() const;

    [[nodiscard]] bool hit_test(ui::point const &) const;

    [[nodiscard]] observing::syncable observe_shape(observing::caller<std::shared_ptr<ui::shape>>::handler_f &&);
    [[nodiscard]] observing::syncable observe_enabled(observing::caller<bool>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<collider> make_shared();
    [[nodiscard]] static std::shared_ptr<collider> make_shared(std::shared_ptr<ui::shape>);

   private:
    simd::float4x4 _matrix = matrix_identity_float4x4;

    observing::value::holder_ptr<std::shared_ptr<ui::shape>> const _shape;
    observing::value::holder_ptr<bool> const _enabled = observing::value::holder<bool>::make_shared(true);

    explicit collider(std::shared_ptr<ui::shape> &&);

    simd::float4x4 const &matrix() const override;
    void set_matrix(simd::float4x4 const &) override;
};
}  // namespace yas::ui
