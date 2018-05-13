//
//  yas_ui_transformer.h
//

#pragma once

#include <functional>
#include <vector>

namespace yas::ui {
using transform_f = std::function<float(float const)>;

transform_f const &ease_in_sine_transformer();
transform_f const &ease_out_sine_transformer();
transform_f const &ease_in_out_sine_transformer();

transform_f const &ease_in_quad_transformer();
transform_f const &ease_out_quad_transformer();
transform_f const &ease_in_out_quad_transformer();

transform_f const &ease_in_cubic_transformer();
transform_f const &ease_out_cubic_transformer();
transform_f const &ease_in_out_cubic_transformer();

transform_f const &ease_in_quart_transformer();
transform_f const &ease_out_quart_transformer();
transform_f const &ease_in_out_quart_transformer();

transform_f const &ease_in_quint_transformer();
transform_f const &ease_out_quint_transformer();
transform_f const &ease_in_out_quint_transformer();

transform_f const &ease_in_expo_transformer();
transform_f const &ease_out_expo_transformer();
transform_f const &ease_in_out_expo_transformer();

transform_f const &ease_in_circ_transformer();
transform_f const &ease_out_circ_transformer();
transform_f const &ease_in_out_circ_transformer();

transform_f const &ping_pong_transformer();
transform_f const &reverse_transformer();

transform_f connect(std::vector<transform_f>);
}  // namespace yas::ui
