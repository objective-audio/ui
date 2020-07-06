//
//  yas_ui_background_protocol.mm
//

#include "yas_ui_background_protocol.h"

using namespace yas;

ui::renderable_background_ptr ui::renderable_background::cast(renderable_background_ptr const &background) {
    return background;
}
