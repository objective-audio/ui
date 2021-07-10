//
//  yas_ui_detector.h
//

#pragma once

#include <ui/yas_ui_collider.h>
#include <ui/yas_ui_render_info_dependency.h>
#include <ui/yas_ui_renderer_dependency.h>
#include <ui/yas_ui_types.h>

#include <deque>

namespace yas::ui {
struct detector final : renderer_detector_interface, render_info_detector_interface {
    virtual ~detector();

    [[nodiscard]] std::optional<std::shared_ptr<collider>> detect(ui::point const &) const;
    [[nodiscard]] bool detect(ui::point const &, std::shared_ptr<collider> const &) const;

    [[nodiscard]] static std::shared_ptr<detector> make_shared();

   private:
    std::deque<std::shared_ptr<collider>> _colliders;
    bool _updating = true;

    detector();

    detector(detector const &) = delete;
    detector(detector &&) = delete;
    detector &operator=(detector const &) = delete;
    detector &operator=(detector &&) = delete;

    bool is_updating() override;
    void begin_update() override;
    void push_front_collider(std::shared_ptr<collider> const &) override;
    void end_update() override;
};
}  // namespace yas::ui
