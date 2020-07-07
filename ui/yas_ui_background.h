//
//  yas_ui_background.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>

#include "yas_ui_background_protocol.h"

namespace yas::ui {
class color;

struct background final : renderable_background {
    ~background();

    [[nodiscard]] chaining::value::holder_ptr<ui::color> const &color() const;
    [[nodiscard]] chaining::value::holder_ptr<float> const &alpha() const;

    [[nodiscard]] static std::shared_ptr<background> make_shared();

   private:
    chaining::value::holder_ptr<ui::color> _color;
    chaining::value::holder_ptr<float> _alpha;

    background_updates_t _updates;

    chaining::observer_pool _pool;

    background();

    background(background const &) = delete;
    background(background &&) = delete;
    background &operator=(background const &) = delete;
    background &operator=(background &&) = delete;

    ui::background_updates_t const &updates() const override;
    void clear_updates() override;
};
}  // namespace yas::ui
