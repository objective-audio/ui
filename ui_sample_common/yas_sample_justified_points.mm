//
//  yas_sample_justified_points.mm
//

#include "yas_sample_justified_points.h"
#include "yas_fast_each.h"

using namespace yas;

namespace yas::sample {
static std::size_t constexpr x_point_count = 16;
static std::size_t constexpr y_point_count = 8;
static std::size_t constexpr all_point_count = x_point_count + y_point_count;
}

struct sample::justified_points::impl : base::impl {
    ui::rect_plane _rect_plane{sample::all_point_count};
    std::vector<ui::layout_guide> _x_layout_guides{sample::x_point_count};
    std::vector<ui::layout_guide> _y_layout_guides{sample::y_point_count};

    impl() {
        this->_setup_colors();
        this->_setup_layout_guides();
    }

    void prepare(sample::justified_points &points) {
        auto &node = this->_rect_plane.node();

        this->_renderer_observer = node.dispatch_and_make_observer(
            ui::node::method::renderer_changed, [weak_points = to_weak(points), x_layout = flow::observer{nullptr},
                                                 y_layout = flow::observer{nullptr}](auto const &context) mutable {
                if (auto points = weak_points.lock()) {
                    auto &node = context.value;
                    if (auto renderer = node.renderer()) {
                        x_layout = ui::make_flow({.first_source_guide = renderer.view_layout_guide_rect().left(),
                                                  .second_source_guide = renderer.view_layout_guide_rect().right(),
                                                  .destination_guides = points.impl_ptr<impl>()->_x_layout_guides});

                        std::array<float, sample::y_point_count - 1> ratios;

                        auto each = make_fast_each(sample::y_point_count - 1);
                        while (yas_each_next(each)) {
                            auto const &idx = yas_each_index(each);
                            if (idx < y_point_count / 2) {
                                ratios.at(idx) = std::pow(2.0f, idx);
                            } else {
                                ratios.at(idx) = std::pow(2.0f, y_point_count - 2 - idx);
                            }
                        }

                        std::vector<flow::receiver<float>> receivers;
                        for (auto &guide : points.impl_ptr<impl>()->_y_layout_guides) {
                            receivers.push_back(guide.receiver());
                        }

                        y_layout = renderer.view_layout_guide_rect()
                                       .bottom()
                                       .begin_flow()
                                       .combine(renderer.view_layout_guide_rect().top().begin_flow())
                                       .map(ui::justify<sample::y_point_count - 1>(ratios))
                                       .perform([](std::array<float, sample::y_point_count> const &value) {})
                                       .receive(receivers)
                                       .sync();
                    } else {
                        x_layout = nullptr;
                        y_layout = nullptr;
                    }
                }
            });
    }

   private:
    ui::node::observer_t _renderer_observer = nullptr;
    std::vector<flow::observer> _guide_observers;

    void _setup_colors() {
        this->_rect_plane.node().mesh().set_use_mesh_color(true);

        auto &rect_plane_data = this->_rect_plane.data();

        auto each = make_fast_each(sample::all_point_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            if (idx < sample::x_point_count) {
                rect_plane_data.set_rect_color(simd::float4{1.0f, 0.8f, 0.5f, 1.0f}, idx);
            } else {
                rect_plane_data.set_rect_color(simd::float4{0.8f, 0.5f, 1.0f, 1.0f}, idx);
            }
        }
    }

    void _setup_layout_guides() {
        auto weak_plane = to_weak(this->_rect_plane);

        auto x_each = make_fast_each(sample::x_point_count);
        while (yas_each_next(x_each)) {
            auto const &idx = yas_each_index(x_each);
            this->_guide_observers.emplace_back(this->_x_layout_guides.at(idx)
                                                    .begin_flow()
                                                    .filter([weak_plane](float const &) { return !!weak_plane; })
                                                    .perform([weak_plane, idx](float const &value) {
                                                        weak_plane.lock().data().set_rect_position(
                                                            {.origin = {value - 2.0f, -2.0f}, .size = {4.0f, 4.0f}},
                                                            idx);
                                                    })
                                                    .end());
        }

        auto y_each = make_fast_each(sample::y_point_count);
        while (yas_each_next(y_each)) {
            auto const &idx = yas_each_index(y_each);
            this->_guide_observers.emplace_back(this->_y_layout_guides.at(idx)
                                                    .begin_flow()
                                                    .filter([weak_plane](float const &) { return !!weak_plane; })
                                                    .perform([weak_plane, idx](float const &value) {
                                                        weak_plane.lock().data().set_rect_position(
                                                            {.origin = {-2.0f, value - 2.0f}, .size = {4.0f, 4.0f}},
                                                            idx + x_point_count);
                                                    })
                                                    .end());
        }
    }
};

sample::justified_points::justified_points() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::justified_points::justified_points(std::nullptr_t) : base(nullptr) {
}

sample::justified_points::~justified_points() = default;

ui::rect_plane &sample::justified_points::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}
