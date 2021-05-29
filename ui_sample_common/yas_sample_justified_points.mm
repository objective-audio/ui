//
//  yas_sample_justified_points.mm
//

#include "yas_sample_justified_points.h"
#include <cpp_utils/yas_fast_each.h>

using namespace yas;
using namespace yas::ui;

namespace yas::sample {
static std::size_t constexpr x_point_count = 16;
static std::size_t constexpr y_point_count = 8;
static std::size_t constexpr all_point_count = x_point_count + y_point_count;

static std::vector<std::shared_ptr<layout_guide>> make_layout_guides(std::size_t const count) {
    std::vector<std::shared_ptr<layout_guide>> guides;
    guides.reserve(count);
    auto each = make_fast_each(count);
    while (yas_each_next(each)) {
        guides.emplace_back(layout_guide::make_shared());
    }
    return guides;
}
}

sample::justified_points::justified_points()
    : _rect_plane(rect_plane::make_shared(sample::all_point_count)),
      _x_layout_guides(sample::make_layout_guides(sample::x_point_count)),
      _y_layout_guides(sample::make_layout_guides(sample::y_point_count)) {
    this->_setup_colors();
    this->_setup_layout_guides();

    this->_rect_plane->node()
        ->observe_renderer(
            [this, pool = observing::canceller_pool::make_shared()](std::shared_ptr<renderer> const &renderer) {
                pool->cancel();

                if (renderer) {
                    std::vector<std::weak_ptr<layout_guide>> x_receivers;
                    for (auto &guide : this->_x_layout_guides) {
                        x_receivers.push_back(to_weak(guide));
                    }

                    auto weak_rect = to_weak(renderer->view_layout_guide_rect());

                    auto x_justifying = [weak_rect, x_receivers](float const &) {
                        if (auto const rect = weak_rect.lock()) {
                            auto const justified =
                                justify<sample::x_point_count - 1>(rect->left()->value(), rect->right()->value());
                            int idx = 0;
                            for (auto const &weak_guide : x_receivers) {
                                if (auto const guide = weak_guide.lock()) {
                                    guide->set_value(justified.at(idx));
                                }
                                ++idx;
                            }
                        }
                    };

                    renderer->view_layout_guide_rect()->left()->observe(x_justifying).end()->add_to(*pool);
                    renderer->view_layout_guide_rect()->right()->observe(x_justifying).sync()->add_to(*pool);

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

                    std::vector<std::weak_ptr<layout_guide>> y_receivers;
                    for (auto &guide : this->_y_layout_guides) {
                        y_receivers.push_back(to_weak(guide));
                    }

                    auto y_justifying = [weak_rect, y_receivers](float const &) {
                        if (auto const rect = weak_rect.lock()) {
                            auto justified =
                                justify<sample::y_point_count - 1>(rect->bottom()->value(), rect->top()->value());
                            int idx = 0;
                            for (auto const &weak_guide : y_receivers) {
                                if (auto const guide = weak_guide.lock()) {
                                    guide->set_value(justified.at(idx));
                                }
                                ++idx;
                            }
                        }
                    };

                    renderer->view_layout_guide_rect()->bottom()->observe(y_justifying).end()->add_to(*pool);
                    renderer->view_layout_guide_rect()->top()->observe(y_justifying).sync()->add_to(*pool);
                }
            })
        .sync()
        ->set_to(this->_renderer_canceller);
}

sample::justified_points::~justified_points() = default;

std::shared_ptr<rect_plane> const &sample::justified_points::rect_plane() {
    return this->_rect_plane;
}

void sample::justified_points::_setup_colors() {
    this->_rect_plane->node()->mesh()->set_use_mesh_color(true);

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
        this->_x_layout_guides.at(idx)
            ->observe([weak_plane, idx](float const &value) {
                if (auto const plane = weak_plane.lock()) {
                    plane->data()->set_rect_position({.origin = {value - 2.0f, -2.0f}, .size = {4.0f, 4.0f}}, idx);
                }
            })
            .end()
            ->add_to(this->_guide_pool);
    }

    auto y_each = make_fast_each(sample::y_point_count);
    while (yas_each_next(y_each)) {
        auto const &idx = yas_each_index(y_each);
        this->_y_layout_guides.at(idx)
            ->observe([weak_plane, idx](float const &value) {
                if (auto const plane = weak_plane.lock()) {
                    plane->data()->set_rect_position({.origin = {-2.0f, value - 2.0f}, .size = {4.0f, 4.0f}},
                                                     idx + x_point_count);
                }
            })
            .sync()
            ->add_to(this->_guide_pool);
    }
}

sample::justified_points_ptr sample::justified_points::make_shared() {
    return std::shared_ptr<justified_points>(new justified_points{});
}
