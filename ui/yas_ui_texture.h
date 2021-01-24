//
//  yas_ui_texture.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_result.h>
#include <ui/yas_ui_metal_protocol.h>
#include <ui/yas_ui_metal_system.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_texture_protocol.h>
#include <ui/yas_ui_types.h>

namespace yas::ui {
class image;
class metal_texture;
class texture_element;
enum class draw_image_error;
using draw_image_result = result<uint_region, draw_image_error>;

struct texture : metal_object {
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
    [[nodiscard]] observing::canceller_ptr observe(observing::caller<chain_pair_t>::handler_f &&);

    void sync_scale_from_renderer(ui::renderer_ptr const &);

    [[nodiscard]] static texture_ptr make_shared(args);

   private:
    std::weak_ptr<ui::texture> _weak_texture;

    ui::uint_size _point_size;
    double _scale_factor;
    uint32_t const _depth = 1;
    bool const _has_alpha = false;
    ui::texture_usages_t const _usages;
    ui::pixel_format const _pixel_format;

    ui::metal_texture_ptr _metal_texture = nullptr;

    ui::metal_system_ptr _metal_system = nullptr;
    uint32_t _max_line_height = 0;
    uint32_t const _draw_actual_padding;
    uint_point _draw_actual_pos;
    std::vector<texture_element_ptr> _texture_elements;
    chaining::any_observer_ptr _scale_observer = nullptr;
    chaining::any_observer_ptr _properties_observer = nullptr;
    observing::notifier_ptr<chain_pair_t> const _notifier = observing::notifier<chain_pair_t>::make_shared();

    explicit texture(args &&);

    texture(texture const &) = delete;
    texture(texture &&) = delete;
    texture &operator=(texture const &) = delete;
    texture &operator=(texture &&) = delete;

    void _prepare(texture_ptr const &);

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    draw_image_result _reserve_image_size(image_ptr const &image);
    draw_image_result _replace_image(image_ptr const &image, uint_point const origin);
    void _prepare_draw_pos(uint_size const size);
    void _move_draw_pos(uint_size const size);
    bool _can_draw(uint_size const size);
    void _add_images_to_metal_texture();
    void _add_image_to_metal_texture(texture_element_ptr const &element);
    void _size_updated();
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::texture::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::texture::method const &);
