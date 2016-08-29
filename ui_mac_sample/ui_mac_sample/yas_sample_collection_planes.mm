//
//  yas_sample_collection_planes.cpp
//

#include "yas_each_index.h"
#include "yas_sample_collection_planes.h"

using namespace yas;

struct sample::collection_planes::impl : base::impl {
    static std::size_t const max_cell_count = 16;
    ui::rect_plane _rect_plane = ui::make_rect_plane(max_cell_count);
    ui::collection_layout _collection_layout{{.preferred_cell_count = max_cell_count,
                                              .frame = {.size = {200.0f, 200.0f}},
                                              .cell_sizes = {{40.0f, 40.0f}},
                                              .alignment = ui::layout_alignment::max,
                                              .row_order = ui::layout_order::descending,
                                              .row_spacing = 8.0f,
                                              .col_spacing = 8.0f,
                                              .borders = {10.0f, 10.0f, 10.0f, 10.0f}}};
    ui::collection_layout::observer_t _collection_layout_observer = nullptr;

    void prepare(sample::collection_planes &ext) {
        auto weak_ext = to_weak(ext);

        _rect_plane.node().dispatch_method(ui::node::method::renderer_changed);
        _renderer_observer = _rect_plane.node().subject().make_observer(
            ui::node::method::renderer_changed,
            [weak_ext, top_layout = ui::layout{nullptr}, right_layout = ui::layout{nullptr}](
                auto const &context) mutable {
                if (auto ext = weak_ext.lock()) {
                    auto impl = ext.impl_ptr<sample::collection_planes::impl>();
                    auto node = context.value;
                    if (auto renderer = node.renderer()) {
                        auto const &view_guide_rect = renderer.view_layout_guide_rect();
                        auto &collection_guide_rect = impl->_collection_layout.frame_layout_guide_rect();
                        top_layout = ui::make_fixed_layout(
                            {.source_guide = view_guide_rect.top(), .destination_guide = collection_guide_rect.top()});
                        right_layout = ui::make_fixed_layout({.source_guide = view_guide_rect.right(),
                                                              .destination_guide = collection_guide_rect.right()});
                    } else {
                        top_layout = nullptr;
                        right_layout = nullptr;
                    }
                }
            });

        _collection_layout_observer = _collection_layout.subject().make_observer(
            ui::collection_layout::method::actual_cell_count_changed, [weak_ext](auto const &context) {
                if (auto ext = weak_ext.lock()) {
                    ext.impl_ptr<impl>()->_update_plane_position();
                }
            });

        _update_plane_position();

        _rect_plane.node().set_color({1.0f, 0.6f, 0.0f});
    }

   private:
    ui::node::observer_t _renderer_observer = nullptr;

    void _update_plane_position() {
        auto const actual_cell_count = _collection_layout.actual_cell_count();
        auto &data = _rect_plane.data();

        data.set_rect_count(actual_cell_count);

        for (auto const &idx : make_each(actual_cell_count)) {
            auto &cell_guide_rect = _collection_layout.cell_layout_guide_rects().at(idx);
            cell_guide_rect.set_value_changed_handler(
                [weak_plane_ext = to_weak(_rect_plane), idx](auto const &context) {
                    if (auto plane_ext = weak_plane_ext.lock()) {
                        plane_ext.data().set_rect_position(context.new_value, idx);
                    }
                });

            data.set_rect_position(cell_guide_rect.region(), idx);
        }
    }
};

sample::collection_planes::collection_planes() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

sample::collection_planes::collection_planes(std::nullptr_t) : base(nullptr) {
}

ui::rect_plane &sample::collection_planes::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}

ui::layout_guide_rect &sample::collection_planes::frame_layout_guide_rect() {
    return impl_ptr<impl>()->_collection_layout.frame_layout_guide_rect();
}
