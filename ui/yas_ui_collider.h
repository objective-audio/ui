
//
//  yas_ui_collider.h
//

#pragma once

#include <string>
#include <cpp_utils/yas_base.h>
#include <chaining/yas_chaining_umbrella.h>
#include "yas_ui_collider_protocol.h"
#include "yas_ui_types.h"

namespace yas::ui {
struct anywhere_shape {
    bool hit_test(ui::point const &) const;
};

struct circle_shape {
    ui::point center = {.v = 0.0f};
    float radius = 0.5f;

    bool hit_test(ui::point const &) const;
};

struct rect_shape {
    ui::region rect = {.origin = {-0.5f, -0.5f}, .size = {1.0f, 1.0f}};

    bool hit_test(ui::point const &pos) const;
};

class shape : public base {
   public:
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

    explicit shape(anywhere::type);
    explicit shape(circle::type);
    explicit shape(rect::type);
    shape(std::nullptr_t);

    virtual ~shape() final;

    std::type_info const &type_info() const;

    bool hit_test(ui::point const &) const;

    template <typename T>
    typename T::type const &get() const;
};

class collider : public base {
   public:
    class impl;

    collider();
    explicit collider(ui::shape);
    collider(std::nullptr_t);

    virtual ~collider() final;

    void set_shape(ui::shape);
    ui::shape const &shape() const;

    void set_enabled(bool const);
    bool is_enabled() const;

    bool hit_test(ui::point const &) const;

    [[nodiscard]] chaining::chain_sync_t<ui::shape> chain_shape() const;
    [[nodiscard]] chaining::chain_sync_t<bool> chain_enabled() const;

    [[nodiscard]] chaining::receiver<ui::shape> &shape_receiver();
    [[nodiscard]] chaining::receiver<bool> &enabled_receiver();

    ui::renderable_collider &renderable();

   private:
    ui::renderable_collider _renderable = nullptr;
};
}  // namespace yas::ui
