//
//  yas_ui_texture_protocol.h
//

#include "yas_protocol.h"

#pragma once

namespace yas::ui {
struct renderable_texture : protocol {
    struct impl : protocol::impl {};
    
    explicit renderable_texture(std::shared_ptr<impl>);
    renderable_texture(std::nullptr_t);
};
}
