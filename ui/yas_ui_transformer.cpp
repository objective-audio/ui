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

ui::transform_f const &ui::ease_in_sine_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) { return sinf((pos - 1.0f) * M_PI_2) + 1.0f; });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_out_sine_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) { return sinf(pos * M_PI_2); });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_out_sine_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve =
            ui::_make_curve_vector([](float const pos) { return (sinf((pos * 2.0f - 1.0f) * M_PI_2) + 1.0f) * 0.5f; });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_quad_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) { return pos * pos; });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_out_quad_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) { return -1.0f * pos * (pos - 2.0f); });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_out_quad_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float val = 2.0f * pos;
            if (val < 1.0f) {
                return 0.5f * val * val;
            } else {
                float val = 2.0f * pos;
                if (val < 1.0f) {
                    return 0.5f * val * val;
                } else {
                    val -= 1.0f;
                    return -0.5f * (val * (val - 2.0f) - 1.0f);
                }
            }

        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_cubic_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) { return pos * pos * pos; });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_out_cubic_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float const val = pos - 1.0f;
            return val * val * val + 1.0f;
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_out_cubic_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float val = 2.0f * pos;
            if (val < 1.0f) {
                return 0.5f * val * val * val;
            } else {
                val -= 2.0f;
                return 0.5f * (val * val * val + 2.0f);
            }
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_quart_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) { return pos * pos * pos * pos; });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_out_quart_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float const val = pos - 1.0f;
            return -1.0f * (val * val * val * val - 1.0f);
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_out_quart_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float val = 2.0f * pos;
            if (val < 1.0f) {
                return 0.5f * val * val * val * val;
            } else {
                val -= 2.0f;
                return -0.5f * (val * val * val * val - 2.0f);
            }
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_quint_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) { return pos * pos * pos * pos * pos; });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_out_quint_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float const val = pos - 1.0f;
            return val * val * val * val * val + 1.0f;
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_out_quint_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float val = 2.0f * pos;
            if (val < 1.0f) {
                return 0.5f * val * val * val * val * val;
            } else {
                val -= 2.0f;
                return 0.5f * (val * val * val * val * val + 2.0f);
            }
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_expo_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            auto const value_handler = [](float const pos) { return pow(2.0f, 10.0f * (pos - 1.0f)); };
            static float const zero_value = value_handler(0.0f);
            static float const diff = value_handler(1.0f) - zero_value;
            return (value_handler(pos) - zero_value) / diff;

        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_out_expo_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            auto const value_handler = [](float const pos) { return 1.0f - pow(2.0f, -10.0f * pos); };
            static float const one_value = value_handler(1.0f);
            return value_handler(pos) / one_value;
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_out_expo_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float val = pos * 2.0f;
            if (val < 1.0f) {
                return 0.5f * ui::ease_in_expo_transformer()(val);
            } else {
                return 0.5f * ui::ease_out_expo_transformer()(val - 1.0f) + 0.5f;
            }
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_circ_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) { return 1.0f - sqrt(1.0f - pos * pos); });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_out_circ_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float const val = pos - 1.0f;
            return sqrt(1.0f - val * val);
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ease_in_out_circ_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float val = 2.0f * pos;
            if (val < 1.0f) {
                return -0.5f * (sqrt(1.0f - val * val) - 1.0f);
            } else {
                val -= 2.0f;
                return 0.5f * (sqrt(1.0f - val * val) + 1.0f);
            }
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::ping_pong_transformer() {
    static transform_f const _transformer = [](float const pos) {
        static auto curve = ui::_make_curve_vector([](float const pos) {
            float _pos = pos * 2.0f;
            if (_pos > 1.0f) {
                _pos = 2.0f - _pos;
            }
            return _pos;
        });
        return ui::_convert_value(curve, pos);
    };

    return _transformer;
}

ui::transform_f const &ui::reverse_transformer() {
    static transform_f const _transformer = [](float const pos) { return 1.0f - pos; };

    return _transformer;
}

ui::transform_f ui::connect(std::vector<transform_f> transformers) {
    auto transformer = [transformers = std::move(transformers)](float const value) {
        float _value = value;
        for (auto transformer : transformers) {
            _value = transformer(_value);
        }
        return _value;
    };

    return transformer;
}
