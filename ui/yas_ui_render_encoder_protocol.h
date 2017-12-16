//
//  yas_ui_render_encoder_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas {
namespace ui {
    class mesh;
    class renderer;

    struct render_encodable : protocol {
        struct impl : protocol::impl {
            virtual void append_mesh(ui::mesh &&mesh) = 0;
        };

        explicit render_encodable(std::shared_ptr<impl>);
        render_encodable(std::nullptr_t);

        void append_mesh(ui::mesh);
    };
}
}
