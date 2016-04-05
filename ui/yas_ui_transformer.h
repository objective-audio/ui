//
//  yas_ui_transformer.h
//

#pragma once

#include <functional>
#include <vector>

namespace yas {
namespace ui {
    using action_transform_f = std::function<float(float const)>;

    action_transform_f const &ease_in_transformer();
    action_transform_f const &ease_out_transformer();
    action_transform_f const &ease_in_out_transformer();
    action_transform_f const &ping_pong_transformer();
    action_transform_f const &reverse_transformer();

    action_transform_f connect(std::vector<action_transform_f>);
}
}