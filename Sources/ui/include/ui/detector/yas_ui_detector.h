//
//  yas_ui_detector.h
//

#pragma once

#include <ui/collider/yas_ui_collider.h>
#include <ui/common/yas_ui_common_dependency.h>
#include <ui/common/yas_ui_types.h>
#include <ui/render_info/yas_ui_render_info_dependency.h>
#include <ui/renderer/yas_ui_renderer_dependency.h>

#include <deque>

namespace yas::ui {
struct detector final : detector_for_renderer, collider_detectable {
    [[nodiscard]] std::optional<std::shared_ptr<collider>> detect(ui::point const &) const;
    [[nodiscard]] bool detect(ui::point const &, std::shared_ptr<collider> const &) const override;

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
