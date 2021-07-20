//
//  yas_ui_standard.mm
//

#include "yas_ui_standard.h"
#include <ui/yas_ui_action_manager.h>
#include <ui/yas_ui_detector.h>
#include <ui/yas_ui_event.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_node.h>
#include <ui/yas_ui_renderer.h>
#include <ui/yas_ui_view_look.h>

using namespace yas;
using namespace yas::ui;

standard::standard(std::shared_ptr<ui::view_look> const &view_look,
                   std::shared_ptr<ui::metal_system> const &metal_system)
    : _root_node(ui::node::make_shared()),
      _detector(ui::detector::make_shared()),
      _event_manager(ui::event_manager::make_shared()),
      _action_manager(ui::action_manager::make_shared()),
      _renderer(ui::renderer::make_shared(metal_system, view_look, _root_node, _detector, _action_manager)) {
}

std::shared_ptr<ui::node> const &standard::root_node() const {
    return this->_root_node;
}

std::shared_ptr<ui::detector> const &standard::detector() const {
    return this->_detector;
}

std::shared_ptr<ui::event_manager> const &standard::event_manager() const {
    return this->_event_manager;
}

std::shared_ptr<ui::action_manager> const &standard::action_manager() const {
    return this->_action_manager;
}

std::shared_ptr<ui::renderer> const &standard::renderer() const {
    return this->_renderer;
}

std::shared_ptr<standard> standard::make_shared(std::shared_ptr<ui::view_look> const &view_look,
                                                std::shared_ptr<ui::metal_system> const &metal_system) {
    return std::shared_ptr<standard>(new standard{view_look, metal_system});
}
