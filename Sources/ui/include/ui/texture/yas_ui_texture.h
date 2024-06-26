//
//  yas_ui_texture.h
//

#pragma once

#include <cpp-utils/result.h>
#include <ui/common/yas_ui_common_dependency.h>
#include <ui/common/yas_ui_types.h>
#include <ui/metal/yas_ui_metal_setup_types.h>
#include <ui/metal/yas_ui_metal_system.h>
#include <ui/texture/yas_ui_texture_types.h>

#include <observing/umbrella.hpp>

namespace yas::ui {
enum class draw_image_error;
using draw_image_result = result<uint_region, draw_image_error>;

struct texture {
    [[nodiscard]] uintptr_t identifier() const;

    [[nodiscard]] uint_size point_size() const;
    [[nodiscard]] uint_size actual_size() const;
    [[nodiscard]] double scale_factor() const;
    [[nodiscard]] uint32_t depth() const;
    [[nodiscard]] bool has_alpha() const;

    void set_point_size(ui::uint_size);
    void set_scale_factor(double const);

    [[nodiscard]] std::shared_ptr<texture_element> const &add_draw_handler(ui::uint_size, ui::draw_handler_f);
    void remove_draw_handler(std::shared_ptr<texture_element> const &);

    [[nodiscard]] std::shared_ptr<ui::metal_texture> const &metal_texture() const;

    [[nodiscard]] observing::endable observe_metal_texture_changed(std::function<void(std::nullptr_t const &)> &&);
    [[nodiscard]] observing::endable observe_size_updated(std::function<void(std::nullptr_t const &)> &&);

    ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &);

    [[nodiscard]] static std::shared_ptr<texture> make_shared(texture_args &&,
                                                              std::shared_ptr<scale_factor_observable> const &);

   private:
    ui::uint_size _point_size;
    double _scale_factor;
    uint32_t const _depth = 1;
    bool const _has_alpha = false;
    ui::texture_usages_t const _usages;
    ui::pixel_format const _pixel_format;

    std::shared_ptr<ui::metal_texture> _metal_texture = nullptr;

    std::shared_ptr<metal_system> _metal_system = nullptr;
    uint32_t _max_line_height = 0;
    uint32_t const _draw_actual_padding;
    uint_point _draw_actual_pos;
    std::vector<std::shared_ptr<texture_element>> _texture_elements;
    observing::canceller_pool _pool;
    observing::notifier_ptr<std::nullptr_t> const _texture_notifier =
        observing::notifier<std::nullptr_t>::make_shared();
    observing::notifier_ptr<std::nullptr_t> const _size_notifier = observing::notifier<std::nullptr_t>::make_shared();

    texture(texture_args &&, std::shared_ptr<scale_factor_observable> const &);

    texture(texture const &) = delete;
    texture(texture &&) = delete;
    texture &operator=(texture const &) = delete;
    texture &operator=(texture &&) = delete;

    draw_image_result _reserve_image_size(std::shared_ptr<image> const &image);
    draw_image_result _replace_image(std::shared_ptr<image> const &image, uint_point const origin);
    void _prepare_draw_pos(uint_size const size);
    void _move_draw_pos(uint_size const size);
    bool _can_draw(uint_size const size);
    void _add_images_to_metal_texture();
    void _add_image_to_metal_texture(std::shared_ptr<texture_element> const &element);
    void _size_updated();
};
}  // namespace yas::ui
