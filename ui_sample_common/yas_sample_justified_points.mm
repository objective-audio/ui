//
//  yas_sample_justified_points.mm
//

#include "yas_each_index.h"
#include "yas_sample_justified_points.h"

using namespace yas;

namespace yas {
namespace sample {
    static std::size_t constexpr x_point_count = 16;
    static std::size_t constexpr y_point_count = 8;
    static std::size_t constexpr all_point_count = x_point_count + y_point_count;
}
}

struct sample::justified_points::impl : base::impl {
    ui::rect_plane _rect_plane = ui::make_rect_plane(sample::all_point_count);
    std::vector<ui::layout_guide> _x_layout_guides{sample::x_point_count};
    std::vector<ui::layout_guide> _y_layout_guides{sample::y_point_count};

    impl() {
        _setup_colors();
        _setup_layout_guides();

        _rect_plane.node().dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::justified_points &ext) {
        auto &node = _rect_plane.node();

        _renderer_observer = node.subject().make_observer(
            ui::node::method::renderer_changed,
            [weak_ext = to_weak(ext), x_layout = ui::layout{nullptr}, y_layout = ui::layout{nullptr}](
                auto const &context) mutable {
                if (auto ext = weak_ext.lock()) {
                    auto &node = context.value;
                    if (auto renderer = node.renderer()) {
                        x_layout =
                            ui::make_justified_layout({.first_source_guide = renderer.view_layout_guide_rect().left(),
                                                       .second_source_guide = renderer.view_layout_guide_rect().right(),
                                                       .destination_guides = ext.impl_ptr<impl>()->_x_layout_guides});

                        std::vector<float> ratios;
                        ratios.reserve(sample::y_point_count - 1);
                        for (auto const &idx : make_each(sample::y_point_count - 1)) {
                            if (idx < y_point_count / 2) {
                                ratios.emplace_back(std::pow(2.0f, idx));
                            } else {
                                ratios.emplace_back(std::pow(2.0f, y_point_count - 2 - idx));
                            }
                        }

                        y_layout =
                            ui::make_justified_layout({.first_source_guide = renderer.view_layout_guide_rect().bottom(),
                                                       .second_source_guide = renderer.view_layout_guide_rect().top(),
                                                       .destination_guides = ext.impl_ptr<impl>()->_y_layout_guides,
                                                       .ratios = std::move(ratios)});
                    } else {
                        x_layout = nullptr;
                        y_layout = nullptr;
                    }
                }
            });
    }

   private:
    ui::node::observer_t _renderer_observer = nullptr;

    void _setup_colors() {
        _rect_plane.node().mesh().set_use_mesh_color(true);

        auto &rect_plane_data = _rect_plane.data();

        for (auto const &idx : make_each(sample::all_point_count)) {
            if (idx < sample::x_point_count) {
                rect_plane_data.set_rect_color({1.0f, 0.8f, 0.5f, 1.0f}, idx);
            } else {
                rect_plane_data.set_rect_color({0.8f, 0.5f, 1.0f, 1.0f}, idx);
            }
        }
    }

    void _setup_layout_guides() {
        for (auto const &idx : make_each(sample::x_point_count)) {
            _x_layout_guides.at(idx)
                .set_value_changed_handler([weak_ext = to_weak(_rect_plane), idx](auto const &context) {
                    if (auto ext = weak_ext.lock()) {
                        ext.data().set_rect_position(
                            {.origin = {context.new_value - 2.0f, -2.0f}, .size = {4.0f, 4.0f}}, idx);
                    }
                });
        }

        for (auto const &idx : make_each(sample::y_point_count)) {
            _y_layout_guides.at(idx)
                .set_value_changed_handler([weak_ext = to_weak(_rect_plane), idx](auto const &context) {
                    if (auto ext = weak_ext.lock()) {
                        ext.data().set_rect_position(
                            {.origin = {-2.0f, context.new_value - 2.0f}, .size = {4.0f, 4.0f}}, idx + x_point_count);
                    }
                });
        }
    }
};

sample::justified_points::justified_points() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::justified_points::justified_points(std::nullptr_t) : base(nullptr) {
}

sample::justified_points::~justified_points() = default;

ui::rect_plane &sample::justified_points::rect_plane_ext() {
    return impl_ptr<impl>()->_rect_plane;
}