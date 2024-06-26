//
//  yas_ui_font.mm
//

#include "yas_ui_font_atlas.h"

#include <CoreGraphics/CoreGraphics.h>
#include <CoreText/CoreText.h>
#include <cpp-utils/cf_ref.h>
#include <cpp-utils/cf_utils.h>
#include <cpp-utils/each_index.h>
#include <ui/image/yas_ui_image.h>
#include <ui/texture/yas_ui_texture_element.h>
#include <ui/utils/yas_ui_math.h>

using namespace yas;
using namespace yas::ui;

#pragma mark - font_atlas::impl

namespace yas::ui {
static vertex2d_rect constexpr _empty_rect{0.0f};

struct word_info {
    vertex2d_rect rect;
    size advance;
    std::weak_ptr<ui::texture_element> texture_element;
};
}  // namespace yas::ui

struct font_atlas::impl {
    cf_ref<CTFontRef> ct_font_ref = nullptr;

    impl(std::string const &font_name, double const font_size)
        : ct_font_ref(cf_ref_with_move_object(CTFontCreateWithName(to_cf_object(font_name), font_size, nullptr))) {
    }
};

std::shared_ptr<font_atlas> font_atlas::make_shared(font_atlas_args &&args,
                                                    std::shared_ptr<ui::texture> const &texture) {
    return std::shared_ptr<font_atlas>(new font_atlas{std::move(args), texture});
}

font_atlas::font_atlas(font_atlas_args &&args, std::shared_ptr<ui::texture> const &texture)
    : _impl(std::make_unique<impl>(args.font_name, args.font_size)),
      _font_name(std::move(args.font_name)),
      _font_size(args.font_size),
      _ascent(CTFontGetAscent(this->_impl->ct_font_ref.object())),
      _descent(CTFontGetDescent(this->_impl->ct_font_ref.object())),
      _leading(CTFontGetLeading(this->_impl->ct_font_ref.object())),
      _texture(texture) {
    this->_setup(args.words);
    this->_rects_canceller = texture
                                 ->observe_metal_texture_changed([this](auto const &) {
                                     this->_update_tex_coords();
                                     this->_rects_updated_notifier->notify();
                                 })
                                 .end();
}

std::string const &font_atlas::font_name() const {
    return this->_font_name;
}

double const &font_atlas::font_size() const {
    return this->_font_size;
}

double const &font_atlas::ascent() const {
    return this->_ascent;
}

double const &font_atlas::descent() const {
    return this->_descent;
}

double const &font_atlas::leading() const {
    return this->_leading;
}

std::string font_atlas::words() const {
    return yas::joined(this->_word_infos, "", [](auto const &pair) { return pair.first; });
}

std::shared_ptr<texture> const &font_atlas::texture() const {
    return this->_texture;
}

vertex2d_rect const &font_atlas::rect(std::string const &word) const {
    if (this->_word_infos.contains(word)) {
        return this->_word_infos.at(word).rect;
    } else {
        return _empty_rect;
    }
}

size font_atlas::advance(std::string const &word) const {
    if (word.size() != 1) {
        throw std::invalid_argument("word size is not equal to one.");
    }

    if (word == "\n" || word == "\r") {
        return size::zero();
    }

    if (this->_word_infos.contains(word)) {
        return this->_word_infos.at(word).advance;
    } else {
        return size::zero();
    }
}

observing::endable font_atlas::observe_rects_updated(std::function<void(std::nullptr_t const &)> &&handler) {
    return this->_rects_updated_notifier->observe(std::move(handler));
}

observing::endable font_atlas::observe_rects_updated(std::size_t const order,
                                                     std::function<void(std::nullptr_t const &)> &&handler) {
    return this->_rects_updated_notifier->observe(order, std::move(handler));
}

void font_atlas::_setup(std::string const &words) {
    auto &texture = this->texture();

    if (!texture) {
        return;
    }

    auto ct_font_obj = this->_impl->ct_font_ref.object();
    auto const word_count = words.size();

    CGGlyph glyphs[word_count];
    UniChar characters[word_count];
    CGSize advances[word_count];

    CFStringGetCharacters(to_cf_object(words), CFRangeMake(0, word_count), characters);
    CTFontGetGlyphsForCharacters(ct_font_obj, characters, glyphs, word_count);
    CTFontGetAdvancesForGlyphs(ct_font_obj, kCTFontOrientationDefault, glyphs, advances, word_count);

    CGFloat const string_height = this->_descent + this->_ascent;
    double const scale_factor = texture->scale_factor();

    for (auto const &idx : each_index<std::size_t>(word_count)) {
        uint_size const image_size = {uint32_t(std::ceilf(advances[idx].width)), uint32_t(std::ceilf(string_height))};
        region const image_region = {
            .origin = {0.0f, roundf(-this->_descent, scale_factor)},
            .size = {static_cast<float>(image_size.width), static_cast<float>(image_size.height)}};

        auto const texture_element = texture->add_draw_handler(
            image_size, [height = image_size.height, glyph = glyphs[idx], ct_font_obj](CGContextRef const ctx) {
                CGContextSaveGState(ctx);

                CGContextTranslateCTM(ctx, 0.0, height);
                CGContextScaleCTM(ctx, 1.0, -1.0);
                CGContextTranslateCTM(ctx, 0.0, CTFontGetDescent(ct_font_obj));

                CGPathRef path = CTFontCreatePathForGlyph(ct_font_obj, glyph, nullptr);

                auto color_space = CGColorSpaceCreateDeviceRGB();
                CGFloat const components[4] = {1.0, 1.0, 1.0, 1.0};
                auto color = CGColorCreate(color_space, components);
                CGColorSpaceRelease(color_space);
                CGContextSetFillColorWithColor(ctx, color);
                CGColorRelease(color);

                CGContextAddPath(ctx, path);
                CGContextFillPath(ctx);
                CGPathRelease(path);

                CGContextRestoreGState(ctx);
            });

        auto const &advance = advances[idx];

        vertex2d_rect rect;
        rect.set_position(image_region);

        this->_word_infos.emplace(words.substr(idx, 1), ui::word_info{.rect = std::move(rect),
                                                                      .advance = {static_cast<float>(advance.width),
                                                                                  static_cast<float>(advance.height)},
                                                                      .texture_element = texture_element});
    }

    this->_update_tex_coords();
}

void font_atlas::_update_tex_coords() {
    for (auto &pair : this->_word_infos) {
        if (auto const texture_element = pair.second.texture_element.lock()) {
            pair.second.rect.set_tex_coord(texture_element->tex_coords());
        }
    }
}
