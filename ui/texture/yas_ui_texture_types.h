//
//  yas_ui_texture_types.h
//

#pragma once

namespace yas::ui {
struct texture_args final {
    ui::uint_size point_size;
    uint32_t draw_padding = 2;
    ui::texture_usages_t usages = {texture_usage::shader_read};
    ui::pixel_format pixel_format = ui::pixel_format::rgba8_unorm;
};
}  // namespace yas::ui
