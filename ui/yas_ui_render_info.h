//
//  yas_ui_render_info.h
//

#pragma once

#include <Metal/Metal.h>
#include <simd/simd.h>
#include <deque>
#include "yas_base.h"
#include "yas_ui_collision_detector.h"

namespace yas {
namespace ui {
    class encode_info;

    struct render_info {
        std::deque<encode_info> all_encode_infos;

        void push_encode_info(encode_info);
        void pop_encode_info();

        ui::encode_info const &current_encode_info();

        simd::float4x4 render_matrix;
        ui::collision_detector collision_detector;

       private:
        std::deque<encode_info> _current_encode_infos;
    };
}
}
