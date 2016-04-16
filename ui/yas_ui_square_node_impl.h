//
//  yas_ui_square_node_impl.h
//

#pragma once

struct yas::ui::square_node::impl : ui::node::impl {
    using super_class = ui::node::impl;

    impl(std::size_t const square_count);

    ui::square_mesh_data _mesh_data;
};
