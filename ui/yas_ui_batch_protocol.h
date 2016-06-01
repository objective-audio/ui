//
//  yas_ui_batch_protocol.h
//

#pragma once

#include <vector>
#include "yas_protocol.h"

namespace yas {
namespace ui {
    class mesh;

    struct renderable_batch : protocol {
        struct impl : protocol::impl {
            virtual std::vector<ui::mesh> &meshes() = 0;
            virtual void commit() = 0;
            virtual void clear() = 0;
        };

        explicit renderable_batch(std::shared_ptr<impl>);

        std::vector<ui::mesh> &meshes();
        void commit();
        void clear();
    };
}
}
