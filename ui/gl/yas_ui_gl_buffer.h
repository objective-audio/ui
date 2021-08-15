//
//  yas_ui_gl_buffer.h
//

#pragma once

#include <ui/yas_ui_types.h>

namespace yas::ui {
struct gl_buffer {
    virtual ~gl_buffer() = default;

    virtual void write_from_vertices(std::vector<ui::vertex2d_t> const &, std::size_t const dynamic_buffer_index) = 0;
    virtual void write_from_indices(std::vector<ui::index2d_t> const &, std::size_t const dynamic_buffer_index) = 0;
};
}  // namespace yas::ui
