#pragma once

#include <cpp-utils/objc_ptr.h>
#include "yas_ui_metal_view.h"
#include <ui/metal/view/yas_ui_metal_view_controller_objc.h>

@interface YASUIMetalViewController ()

- (std::shared_ptr<yas::ui::view_look> const &)view_look;

- (void)configure_with_metal_system:(std::shared_ptr<yas::ui::metal_system_for_view> const &)metal_system
                           renderer:(std::shared_ptr<yas::ui::renderer_for_view> const &)renderer
                      event_manager:(std::shared_ptr<yas::ui::event_manager_for_view> const &)event_manager;

- (std::shared_ptr<yas::ui::renderer_for_view> const &)renderer;

@end
