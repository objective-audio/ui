//
//  yas_ui_render_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <deque>
#include "yas_base.h"

namespace yas {
namespace ui {
    class encode_info;

    class render_info : public base {
        using super_class = base;

       public:
        render_info();
        render_info(std::nullptr_t);

        void push_encode_info(encode_info);
        void pop_endoce_info();

        ui::encode_info const &current_encode_info();
        std::deque<ui::encode_info> const &all_encode_infos();

        simd::float4x4 render_matrix;
        simd::float4x4 touch_matrix;

       private:
        class impl;
    };
}
}
