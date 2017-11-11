//
//  yas_ui_transformer.h
//

#pragma once

#include <functional>
#include <vector>

namespace yas {
namespace ui {
    using transform_f = std::function<float(float const)>;

    transform_f const &ease_in_sine_transformer();
    transform_f const &ease_out_sine_transformer();
    transform_f const &ease_in_out_sine_transformer();
    transform_f const &ping_pong_transformer();
    transform_f const &reverse_transformer();

    transform_f connect(std::vector<transform_f>);
}
}
