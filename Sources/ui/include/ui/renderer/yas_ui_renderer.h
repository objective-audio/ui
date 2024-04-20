//
//  yas_ui_renderer.h
//

#pragma once

#include <ui/common/yas_ui_common_dependency.h>
#include <ui/metal/view/yas_ui_metal_view_controller_dependency.h>
#include <ui/renderer/yas_ui_renderer_dependency.h>

#include <observing/yas_observing_umbrella.hpp>

namespace yas::ui {
struct renderer final : renderer_for_view, renderer_observable {
    [[nodiscard]] observing::endable observe_will_render(std::function<void(std::nullptr_t const &)> &&) override;
    [[nodiscard]] observing::endable observe_did_render(std::function<void(std::nullptr_t const &)> &&) override;

    [[nodiscard]] static std::shared_ptr<renderer> make_shared(
        std::shared_ptr<ui::system_for_renderer> const &, std::shared_ptr<ui::view_look_for_renderer> const &,
        std::shared_ptr<ui::node> const &, std::shared_ptr<ui::detector_for_renderer> const &,
        std::shared_ptr<ui::action_manager_for_renderer> const &);

   private:
    enum class update_result {
        no_change,
        changed,
    };

    enum class pre_render_result {
        none,
        updated,
    };

    std::shared_ptr<ui::system_for_renderer> _system;
    std::shared_ptr<ui::view_look_for_renderer> _view_look;

    renderer_updates_t _updates;

    std::shared_ptr<node> const _root_node;
    std::shared_ptr<ui::detector_for_renderer> const _detector;
    std::shared_ptr<ui::action_manager_for_renderer> const _action_manager;

    observing::notifier_ptr<std::nullptr_t> _will_render_notifier;
    observing::notifier_ptr<std::nullptr_t> _did_render_notifier;

    renderer(std::shared_ptr<ui::system_for_renderer> const &, std::shared_ptr<ui::view_look_for_renderer> const &,
             std::shared_ptr<ui::node> const &root_node, std::shared_ptr<ui::detector_for_renderer> const &,
             std::shared_ptr<ui::action_manager_for_renderer> const &);

    renderer(renderer const &) = delete;
    renderer(renderer &&) = delete;
    renderer &operator=(renderer const &) = delete;
    renderer &operator=(renderer &&) = delete;

    void view_render() override;

    pre_render_result _pre_render();
    void _post_render();
};
}  // namespace yas::ui

namespace yas::ui {
bool operator==(std::weak_ptr<yas::ui::renderer> const &, std::weak_ptr<yas::ui::renderer> const &);
bool operator!=(std::weak_ptr<yas::ui::renderer> const &, std::weak_ptr<yas::ui::renderer> const &);
}  // namespace yas::ui
