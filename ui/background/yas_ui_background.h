//
//  yas_ui_background.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_renderer_dependency.h>

namespace yas::ui {
class color;

struct background final : renderable_background {
    virtual ~background();

    void set_color(ui::color const &);
    void set_color(ui::color &&);
    [[nodiscard]] ui::color const &color() const;
    [[nodiscard]] observing::canceller_ptr observe_color(observing::caller<ui::color>::handler_f &&, bool const sync);

    void set_alpha(float const &);
    [[nodiscard]] float const &alpha() const;
    [[nodiscard]] observing::canceller_ptr observe_alpha(observing::caller<float>::handler_f &&, bool const sync);

    [[nodiscard]] static std::shared_ptr<background> make_shared();

   private:
    observing::value::holder_ptr<ui::color> _color;
    observing::value::holder_ptr<float> _alpha;

    background_updates_t _updates;

    observing::canceller_pool _pool;

    background();

    background(background const &) = delete;
    background(background &&) = delete;
    background &operator=(background const &) = delete;
    background &operator=(background &&) = delete;

    ui::background_updates_t const &updates() const override;
    void clear_updates() override;
};
}  // namespace yas::ui
