//
//  yas_ui_renderer.h
//

#pragma once

#include <observing/yas_observing_umbrella.h>
#include <ui/yas_ui_metal_view_controller_dependency.h>
#include <ui/yas_ui_renderer_dependency.h>

namespace yas::ui {
struct renderer final : view_renderer_interface {
    virtual ~renderer();

    [[nodiscard]] observing::endable observe_will_render(observing::caller<std::nullptr_t>::handler_f &&);

    [[nodiscard]] static std::shared_ptr<renderer> make_shared(std::shared_ptr<ui::renderer_metal_system> const &,
                                                               std::shared_ptr<ui::renderer_view_look> const &,
                                                               std::shared_ptr<ui::node> const &,
                                                               std::shared_ptr<ui::renderer_detector_interface> const &,
                                                               std::shared_ptr<ui::renderer_action_manager> const &);

   private:
    enum class update_result {
        no_change,
        changed,
    };

    enum class pre_render_result {
        none,
        updated,
    };

    std::shared_ptr<ui::renderer_metal_system> _metal_system;
    std::shared_ptr<ui::renderer_view_look> _view_look;

    renderer_updates_t _updates;

    std::shared_ptr<node> const _root_node;
    std::shared_ptr<ui::renderer_detector_interface> const _detector;
    std::shared_ptr<ui::renderer_action_manager> const _action_manager;

    observing::notifier_ptr<std::nullptr_t> const _will_render_notifier;

    renderer(std::shared_ptr<ui::renderer_metal_system> const &, std::shared_ptr<ui::renderer_view_look> const &,
             std::shared_ptr<ui::node> const &root_node, std::shared_ptr<ui::renderer_detector_interface> const &,
             std::shared_ptr<ui::renderer_action_manager> const &);

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
