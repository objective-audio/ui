//
//  yas_ui_batch_protocol.h
//

#pragma once

#include "yas_protocol.h"

namespace yas {
namespace ui {
    struct renderable_batch : protocol {
        struct impl : protocol::impl {
            virtual void clear() = 0;
        };

        explicit renderable_batch(std::shared_ptr<impl>);

        void clear();
    };
}
}
