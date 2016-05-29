//
//  yas_ui_batch.h
//

#pragma once

#include "yas_base.h"

namespace yas {
namespace ui {
    class node;
    class renderable_batch;

    class batch : public base {
        class impl;

       public:
        batch();
        batch(std::nullptr_t);

        ui::renderable_batch renderable();
    };
}
}
