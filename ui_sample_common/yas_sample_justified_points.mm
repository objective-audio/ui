//
//  yas_sample_justified_points.mm
//

#include "yas_sample_justified_points.h"
#include <cpp_utils/yas_fast_each.h>

using namespace yas;

namespace yas::sample {
static std::size_t constexpr x_point_count = 16;
static std::size_t constexpr y_point_count = 8;
static std::size_t constexpr all_point_count = x_point_count + y_point_count;

static std::vector<ui::layout_guide_ptr> make_layout_guides(std::size_t const count) {
    std::vector<ui::layout_guide_ptr> guides;
    guides.reserve(count);
    auto each = make_fast_each(count);
    while (yas_each_next(each)) {
        guides.emplace_back(ui::layout_guide::make_shared());
    }
    return guides;
}
}

sample::justified_points::justified_points()
    : _rect_plane(ui::rect_plane::make_shared(sample::all_point_count)),
      _x_layout_guides(sample::make_layout_guides(sample::x_point_count)),
      _y_layout_guides(sample::make_layout_guides(sample::y_point_count)) {
    this->_setup_colors();
    this->_setup_layout_guides();
}

sample::justified_points::~justified_points() = default;

ui::rect_plane_ptr const &sample::justified_points::rect_plane() {
    return this->_rect_plane;
}

void sample::justified_points::_prepare(justified_points_ptr const &points) {
    auto &node = this->_rect_plane->node();

    this->_renderer_observer =
        node->chain_renderer()
            .perform([weak_points = to_weak(points), x_layout = chaining::any_observer_ptr{nullptr},
                      y_layout = chaining::any_observer_ptr{nullptr}](ui::renderer_ptr const &renderer) mutable {
                if (auto points = weak_points.lock()) {
                    if (renderer) {
                        std::vector<ui::layout_guide_ptr> x_receivers;
                        for (auto &guide : points->_x_layout_guides) {
                            x_receivers.push_back(guide);
                        }

                        x_layout = renderer->view_layout_guide_rect()
                                       ->left()
                                       ->chain()
                                       .combine(renderer->view_layout_guide_rect()->right()->chain())
                                       .to(ui::justify<sample::x_point_count - 1>())
                                       .send_to(x_receivers)
                                       .sync();

                        std::array<float, sample::y_point_count - 1> y_ratios;

                        auto each = make_fast_each(sample::y_point_count - 1);
                        while (yas_each_next(each)) {
                            auto const &idx = yas_each_index(each);
                            if (idx < y_point_count / 2) {
                                y_ratios.at(idx) = std::pow(2.0f, idx);
                            } else {
                                y_ratios.at(idx) = std::pow(2.0f, y_point_count - 2 - idx);
                            }
                        }

                        std::vector<ui::layout_guide_ptr> y_receivers;
                        for (auto &guide : points->_y_layout_guides) {
                            y_receivers.push_back(guide);
                        }

                        y_layout = renderer->view_layout_guide_rect()
                                       ->bottom()
                                       ->chain()
                                       .combine(renderer->view_layout_guide_rect()->top()->chain())
                                       .to(ui::justify<sample::y_point_count - 1>(y_ratios))
                                       .perform([](std::array<float, sample::y_point_count> const &value) {})
                                       .send_to(y_receivers)
                                       .sync();
                    } else {
                        x_layout = nullptr;
                        y_layout = nullptr;
                    }
                }
            })
            .sync();
}

void sample::justified_points::_setup_colors() {
    this->_rect_plane->node()->mesh()->raw()->set_use_mesh_color(true);

    auto const &rect_plane_data = this->_rect_plane->data();

    auto each = make_fast_each(sample::all_point_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        if (idx < sample::x_point_count) {
            rect_plane_data->set_rect_color(simd::float4{1.0f, 0.8f, 0.5f, 1.0f}, idx);
        } else {
            rect_plane_data->set_rect_color(simd::float4{0.8f, 0.5f, 1.0f, 1.0f}, idx);
        }
    }
}

void sample::justified_points::_setup_layout_guides() {
    auto weak_plane = to_weak(this->_rect_plane);

    auto x_each = make_fast_each(sample::x_point_count);
    while (yas_each_next(x_each)) {
        auto const &idx = yas_each_index(x_each);
        this->_guide_observers.emplace_back(this->_x_layout_guides.at(idx)
                                                ->chain()
                                                .guard([weak_plane](float const &) { return !weak_plane.expired(); })
                                                .perform([weak_plane, idx](float const &value) {
                                                    weak_plane.lock()->data()->set_rect_position(
                                                        {.origin = {value - 2.0f, -2.0f}, .size = {4.0f, 4.0f}}, idx);
                                                })
                                                .end());
    }

    auto y_each = make_fast_each(sample::y_point_count);
    while (yas_each_next(y_each)) {
        auto const &idx = yas_each_index(y_each);
        this->_guide_observers.emplace_back(this->_y_layout_guides.at(idx)
                                                ->chain()
                                                .guard([weak_plane](float const &) { return !weak_plane.expired(); })
                                                .perform([weak_plane, idx](float const &value) {
                                                    weak_plane.lock()->data()->set_rect_position(
                                                        {.origin = {-2.0f, value - 2.0f}, .size = {4.0f, 4.0f}},
                                                        idx + x_point_count);
                                                })
                                                .end());
    }
}

sample::justified_points_ptr sample::justified_points::make_shared() {
    auto shared = std::shared_ptr<justified_points>(new justified_points{});
    shared->_prepare(shared);
    return shared;
}
