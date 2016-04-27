//
//  yas_ui_collider_protocol.h
//

#pragma once

#include <simd/simd.h>
#include "yas_protocol.h"

namespace yas {
namespace ui {
    struct renderable_collider : protocol {
        struct impl : protocol::impl {
            virtual simd::float4x4 const &matrix() const = 0;
            virtual void set_matrix(simd::float4x4 &&) = 0;
        };

        explicit renderable_collider(std::shared_ptr<impl>);

        simd::float4x4 const &matrix();
        void set_matrix(simd::float4x4);
    };
}
}
