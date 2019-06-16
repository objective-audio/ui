//
//  yas_ui_texture.mm
//

#include "yas_ui_texture.h"
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_stl_utils.h>
#include <cpp_utils/yas_unless.h>
#include <map>
#include "yas_ui_image.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_metal_types.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture_element.h"

using namespace yas;

namespace yas::ui {
enum class draw_image_error {
    unknown,
    image_is_null,
    no_setup,
    out_of_range,
};

using draw_image_result = result<uint_region, draw_image_error>;
}

namespace yas {
std::string to_string(ui::draw_image_error const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::draw_image_error const &);

#pragma mark - ui::texture::impl

struct ui::texture::impl : base::impl, metal_object::impl {
    chaining::value::holder<ui::uint_size> _point_size;
    chaining::value::holder<double> _scale_factor;
    uint32_t const _depth = 1;
    bool const _has_alpha = false;
    ui::texture_usages_t const _usages;
    ui::pixel_format const _pixel_format;

    ui::metal_texture _metal_texture = nullptr;

    impl(ui::uint_size &&point_size, double const scale_factor, uint32_t const draw_padding,
         ui::texture_usages_t const usages, ui::pixel_format const format)
        : _draw_actual_padding(draw_padding * scale_factor),
          _draw_actual_pos({_draw_actual_padding, _draw_actual_padding}),
          _point_size(std::move(point_size)),
          _scale_factor(std::move(scale_factor)),
          _usages(usages),
          _pixel_format(format) {
    }

    void prepare(ui::texture &texture) {
        auto weak_texture = to_weak(texture);

        this->_notify_receiver = chaining::perform_receiver<method>([weak_texture](method const &method) {
            if (auto texture = weak_texture.lock()) {
                texture.impl_ptr<impl>()->_notify_sender.notify(std::make_pair(method, texture));
            }
        });

        auto point_size_chain = this->_point_size.chain().to_null();
        auto scale_factor_chain = this->_scale_factor.chain().to_null();

        this->_properties_observer = point_size_chain.merge(scale_factor_chain)
                                         .guard([weak_texture](auto const &) { return !!weak_texture; })
                                         .perform([weak_texture](auto const &) {
                                             auto texture_impl = weak_texture.lock().impl_ptr<impl>();
                                             texture_impl->_metal_texture = nullptr;
                                             texture_impl->_draw_actual_pos = {texture_impl->_draw_actual_padding,
                                                                               texture_impl->_draw_actual_padding};
                                         })
                                         .to_value(method::size_updated)
                                         .send_to(this->_notify_receiver)
                                         .end();
    }

    ui::setup_metal_result metal_setup(ui::metal_system const &metal_system) {
        if (!is_same(this->_metal_system, metal_system)) {
            this->_metal_system = metal_system;
            this->_metal_texture = nullptr;
        }

        if (!this->_metal_texture) {
            this->_metal_texture = ui::metal_texture{this->actual_size(), this->_usages, this->_pixel_format};

            if (auto ul = unless(this->_metal_texture.metal().metal_setup(metal_system))) {
                return ul.value;
            }

            this->_add_images_to_metal_texture();

            this->_notify_receiver.receivable().receive_value(method::metal_texture_changed);
        }

        return ui::setup_metal_result{nullptr};
    }

    ui::uint_size actual_size() {
        ui::uint_size const &point_size = this->_point_size.raw();
        double const &scale_factor = this->_scale_factor.raw();
        return {static_cast<uint32_t>(point_size.width * scale_factor),
                static_cast<uint32_t>(point_size.height * scale_factor)};
    }

    texture_element const &add_draw_handler(draw_pair_t pair) {
        texture_element element{std::move(pair)};

        if (this->_metal_texture) {
            this->_add_image_to_metal_texture(element);
        }

        this->_texture_elements.emplace_back(std::move(element));
        return this->_texture_elements.back();
    }

    void remove_draw_handler(texture_element const &erase_element) {
        erase_if(this->_texture_elements,
                 [&erase_element](texture_element const &element) { return element == erase_element; });
    }

    void sync_scale_from_renderer(ui::renderer const &renderer, ui::texture &texture) {
        this->_scale_observer = renderer.chain_scale_factor().send_to(texture.scale_factor_receiver()).sync();
    }

    chaining::chain_unsync_t<chain_pair_t> chain() {
        return this->_notify_sender.chain();
    }

   private:
    ui::metal_system _metal_system = nullptr;
    uint32_t _max_line_height = 0;
    uint32_t const _draw_actual_padding;
    uint_point _draw_actual_pos;
    std::vector<texture_element> _texture_elements;
    chaining::any_observer _scale_observer = nullptr;
    chaining::any_observer _properties_observer = nullptr;
    chaining::notifier<chain_pair_t> _notify_sender;
    chaining::perform_receiver<method> _notify_receiver = nullptr;

    draw_image_result _reserve_image_size(image const &image) {
        if (!image) {
            return draw_image_result{draw_image_error::image_is_null};
        }

        auto const actual_image_size = image.actual_size();

        this->_prepare_draw_pos(actual_image_size);

        if (!this->_can_draw(actual_image_size)) {
            return draw_image_result{draw_image_error::out_of_range};
        }

        ui::uint_point const origin = this->_draw_actual_pos;

        this->_move_draw_pos(actual_image_size);

        return draw_image_result{ui::uint_region{.origin = origin, .size = actual_image_size}};
    }

    draw_image_result _replace_image(image const &image, uint_point const origin) {
        if (!image) {
            return draw_image_result{draw_image_error::image_is_null};
        }

        if (!this->_metal_texture.texture() || !this->_metal_texture.samplerState()) {
            return draw_image_result{draw_image_error::no_setup};
        }

        auto region = uint_region{origin, image.actual_size()};

        if (id<MTLTexture> texture = this->_metal_texture.texture()) {
            [texture replaceRegion:to_mtl_region(region)
                       mipmapLevel:0
                         withBytes:image.data()
                       bytesPerRow:region.size.width * 4];
        }

        return draw_image_result{std::move(region)};
    }

    void _prepare_draw_pos(uint_size const size) {
        if (this->actual_size().width < (this->_draw_actual_pos.x + size.width + this->_draw_actual_padding)) {
            this->_move_draw_pos(size);
        }
    }

    void _move_draw_pos(uint_size const size) {
        this->_draw_actual_pos.x += size.width + this->_draw_actual_padding;

        if (this->actual_size().width < this->_draw_actual_pos.x) {
            this->_draw_actual_pos.y += this->_max_line_height + this->_draw_actual_padding;
            this->_max_line_height = 0;
            this->_draw_actual_pos.x = this->_draw_actual_padding;
        }

        if (this->_max_line_height < size.height) {
            this->_max_line_height = size.height;
        }
    }

    bool _can_draw(uint_size const size) {
        ui::uint_size const actual_size = this->actual_size();
        if ((actual_size.width < this->_draw_actual_pos.x + size.width + this->_draw_actual_padding) ||
            (actual_size.height < this->_draw_actual_pos.y + size.height + this->_draw_actual_padding)) {
            return false;
        }

        return true;
    }

    void _add_images_to_metal_texture() {
        for (auto &element : this->_texture_elements) {
            this->_add_image_to_metal_texture(element);
        }
    }

    void _add_image_to_metal_texture(texture_element &element) {
        if (!this->_metal_texture) {
            throw std::runtime_error("metal_texture not found.");
        }

        auto const &pair = element.draw_pair();
        auto const &point_size = pair.first;
        auto const &draw_handler = pair.second;

        ui::image image{{.point_size = point_size, .scale_factor = this->_scale_factor.raw()}};

        if (auto reserve_result = this->_reserve_image_size(image)) {
            if (draw_handler) {
                auto const &tex_coords = reserve_result.value();
                element.set_tex_coords(tex_coords);
                image.draw(draw_handler);
                this->_replace_image(image, tex_coords.origin);
            }
        }
    }
};

ui::texture::texture(args args)
    : base(std::make_shared<impl>(std::move(args.point_size), args.scale_factor, args.draw_padding, args.usages,
                                  args.pixel_format)) {
    impl_ptr<impl>()->prepare(*this);
}

ui::texture::texture(std::nullptr_t) : base(nullptr) {
}

bool ui::texture::operator==(texture const &rhs) const {
    return base::operator==(rhs);
}

bool ui::texture::operator!=(texture const &rhs) const {
    return base::operator!=(rhs);
}

ui::uint_size ui::texture::point_size() const {
    return impl_ptr<impl>()->_point_size.raw();
}

ui::uint_size ui::texture::actual_size() const {
    return impl_ptr<impl>()->actual_size();
}

double ui::texture::scale_factor() const {
    return impl_ptr<impl>()->_scale_factor.raw();
}

uint32_t ui::texture::depth() const {
    return impl_ptr<impl>()->_depth;
}

bool ui::texture::has_alpha() const {
    return impl_ptr<impl>()->_has_alpha;
}

void ui::texture::set_point_size(ui::uint_size size) {
    impl_ptr<impl>()->_point_size.set_value(std::move(size));
}

void ui::texture::set_scale_factor(double const scale_factor) {
    impl_ptr<impl>()->_scale_factor.set_value(scale_factor);
}

ui::texture_element const &ui::texture::add_draw_handler(ui::uint_size size, ui::draw_handler_f handler) {
    return impl_ptr<impl>()->add_draw_handler(std::make_pair(std::move(size), std::move(handler)));
}

void ui::texture::remove_draw_handler(texture_element const &element) {
    impl_ptr<impl>()->remove_draw_handler(element);
}

ui::metal_texture &ui::texture::metal_texture() {
    return impl_ptr<impl>()->_metal_texture;
}

ui::metal_texture const &ui::texture::metal_texture() const {
    return impl_ptr<impl>()->_metal_texture;
}

chaining::chain_unsync_t<ui::texture::chain_pair_t> ui::texture::chain() const {
    return impl_ptr<impl>()->chain();
}

chaining::chain_relayed_unsync_t<ui::texture, ui::texture::chain_pair_t> ui::texture::chain(
    method const &method) const {
    return impl_ptr<impl>()
        ->chain()
        .guard([method](chain_pair_t const &pair) { return pair.first == method; })
        .to([](chain_pair_t const &pair) { return pair.second; });
}

chaining::receiver<double> &ui::texture::scale_factor_receiver() {
    return impl_ptr<impl>()->_scale_factor;
}

ui::metal_object &ui::texture::metal() {
    if (!this->_metal_object) {
        this->_metal_object = ui::metal_object{impl_ptr<ui::metal_object::impl>()};
    }
    return this->_metal_object;
}

void ui::texture::sync_scale_from_renderer(ui::renderer const &renderer) {
    impl_ptr<impl>()->sync_scale_from_renderer(renderer, *this);
}

#pragma mark -

std::string yas::to_string(ui::draw_image_error const &error) {
    switch (error) {
        case ui::draw_image_error::image_is_null:
            return "image_is_null";
        case ui::draw_image_error::no_setup:
            return "no_setup";
        case ui::draw_image_error::out_of_range:
            return "out_of_range";
        default:
            return "unknown";
    }
}

std::string yas::to_string(ui::texture::method const &method) {
    switch (method) {
        case ui::texture::method::metal_texture_changed:
            return "metal_texture_changed";
        case ui::texture::method::size_updated:
            return "size_updated";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::draw_image_error const &error) {
    os << to_string(error);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::texture::method const &method) {
    os << to_string(method);
    return os;
}
