//
//  yas_ui_transformer.cpp
//

#include <math.h>
#include "yas_each_index.h"
#include "yas_ui_transformer.h"

using namespace yas;

#pragma mark - action_utils

namespace yas {
namespace ui {
    static std::size_t constexpr _curve_frames = 256;

    static std::vector<float> _make_curve_vector(std::function<float(float const)> const &func) {
        static std::size_t constexpr _vector_size = _curve_frames + 2;
        std::vector<float> curve_vector;
        curve_vector.reserve(_vector_size);
        for (auto const &i : each_index<std::size_t>(_vector_size)) {
            float const pos = float(i) / _curve_frames;
            float val = (pos < 1.0f) ? func(pos) : func(1.0f);
            curve_vector.push_back(val);
        }
        return curve_vector;
    }

    static float _convert_value(std::vector<float> const &vector, float pos) {
        float const frame = pos * _curve_frames;
        std::size_t const cur_index = frame;
        float const cur_val = vector.at(cur_index);
        float const next_val = vector.at(cur_index + 1);
        float const frac = frame - cur_index;
        return cur_val + (next_val - cur_val) * frac;
    }
}
}

ui::action_transform_f const &ui::ease_in_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        static auto curve = _make_curve_vector([](float const pos) { return sinf((pos - 1.0f) * M_PI_2) + 1.0f; });
        return _convert_value(curve, pos);
    };

    return _transformer;
}

ui::action_transform_f const &ui::ease_out_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        static auto curve = _make_curve_vector([](float const pos) { return sinf(pos * M_PI_2); });
        return _convert_value(curve, pos);
    };

    return _transformer;
}

ui::action_transform_f const &ui::ease_in_out_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        static auto curve =
            _make_curve_vector([](float const pos) { return (sinf((pos * 2.0f - 1.0f) * M_PI_2) + 1.0f) * 0.5f; });
        return _convert_value(curve, pos);
    };

    return _transformer;
}

ui::action_transform_f const &ui::ping_pong_transformer() {
    static action_transform_f const _transformer = [](float const pos) {
        static auto curve = _make_curve_vector([](float const pos) {
            float _pos = pos * 2.0f;
            if (_pos > 1.0f) {
                _pos = 2.0f - _pos;
            }
            return _pos;
        });
        return _convert_value(curve, pos);
    };

    return _transformer;
}

ui::action_transform_f const &ui::reverse_transformer() {
    static action_transform_f const _transformer = [](float const pos) { return 1.0f - pos; };

    return _transformer;
}

ui::action_transform_f ui::connect(std::vector<action_transform_f> transformers) {
    auto transformer = [transformers = std::move(transformers)](float const value) {
        float _value = value;
        for (auto transformer : transformers) {
            _value = transformer(_value);
        }
        return _value;
    };

    return transformer;
}
