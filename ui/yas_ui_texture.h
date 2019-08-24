//
//  yas_ui_texture.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_result.h>
#include "yas_ui_metal_protocol.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_ptr.h"
#include "yas_ui_texture_protocol.h"
#include "yas_ui_types.h"

namespace yas::ui {
class image;
class metal_texture;
class texture_element;

struct texture {
    class impl;

    struct args {
        ui::uint_size point_size;
        double scale_factor = 1.0;
        uint32_t draw_padding = 2;
        ui::texture_usages_t usages = {texture_usage::shader_read};
        ui::pixel_format pixel_format = ui::pixel_format::rgba8_unorm;
    };

    enum class method {
        metal_texture_changed,
        size_updated,
    };

    uintptr_t identifier() const;

    uint_size point_size() const;
    uint_size actual_size() const;
    double scale_factor() const;
    uint32_t depth() const;
    bool has_alpha() const;

    void set_point_size(ui::uint_size);
    void set_scale_factor(double const);

    [[nodiscard]] texture_element_ptr const &add_draw_handler(ui::uint_size, ui::draw_handler_f);
    void remove_draw_handler(texture_element_ptr const &);

    std::shared_ptr<ui::metal_texture> const &metal_texture() const;

    using chain_pair_t = std::pair<method, texture_ptr>;
    [[nodiscard]] chaining::chain_unsync_t<chain_pair_t> chain() const;
    [[nodiscard]] chaining::chain_relayed_unsync_t<texture_ptr, chain_pair_t> chain(method const &) const;
    [[nodiscard]] std::shared_ptr<chaining::receiver<double>> scale_factor_receiver();

    ui::metal_object &metal();

    void sync_scale_from_renderer(ui::renderer_ptr const &);

    [[nodiscard]] static texture_ptr make_shared(args);

   private:
    std::shared_ptr<impl> _impl;

    ui::metal_object _metal_object = nullptr;

    explicit texture(args &&);

    void _prepare(texture_ptr const &);
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::texture::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::texture::method const &);
