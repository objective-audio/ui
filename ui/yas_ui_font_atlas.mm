//
//  yas_ui_font.mm
//

#include "yas_ui_font_atlas.h"
#include <CoreGraphics/CoreGraphics.h>
#include <CoreText/CoreText.h>
#include <cpp_utils/yas_cf_ref.h>
#include <cpp_utils/yas_cf_utils.h>
#include <cpp_utils/yas_each_index.h>
#include <objc_utils/yas_objc_macros.h>
#include "yas_ui_image.h"
#include "yas_ui_math.h"
#include "yas_ui_texture_element.h"

using namespace yas;

#pragma mark - font_atlas::impl

namespace yas::ui {
static ui::vertex2d_rect_t constexpr _empty_rect{0.0f};

struct word_info {
    ui::vertex2d_rect_t rect;
    ui::size advance;
};
}

struct ui::font_atlas::impl {
    cf_ref<CTFontRef> _ct_font_ref = nullptr;

    impl(std::string const &font_name, double const font_size)
        : _ct_font_ref(cf_ref_with_move_object(CTFontCreateWithName(to_cf_object(font_name), font_size, nullptr))) {
    }
};

ui::font_atlas::font_atlas(args &&args)
    : _impl(std::make_unique<impl>(args.font_name, args.font_size)),
      _font_name(std::move(args.font_name)),
      _font_size(args.font_size),
      _ascent(CTFontGetAscent(this->_impl->_ct_font_ref.object())),
      _descent(CTFontGetDescent(this->_impl->_ct_font_ref.object())),
      _leading(CTFontGetLeading(this->_impl->_ct_font_ref.object())),
      _words(std::move(args.words)),
      _texture(observing::value::holder<ui::texture_ptr>::make_shared(args.texture)) {
    this->_texture_changed_fetcher = observing::fetcher<ui::texture_ptr>::make_shared(
        [this]() { return std::optional<ui::texture_ptr>{this->texture()}; });

    this->_texture
        ->observe(
            [this](ui::texture_ptr const &texture) {
                this->_update_word_infos();

                if (texture) {
                    this->_texture_canceller = texture->observe([this](auto const &method) {
                        if (method == texture::method::metal_texture_changed) {
                            this->_texture_updated_notifier->notify(this->_texture->value());
                        }
                    });
                } else {
                    this->_texture_canceller = std::nullopt;
                }

                this->_texture_changed_fetcher->push();
            },
            true)
        ->set_to(this->_texture_changed_canceller);
}

ui::font_atlas::~font_atlas() = default;

std::string const &ui::font_atlas::font_name() const {
    return this->_font_name;
}

double const &ui::font_atlas::font_size() const {
    return this->_font_size;
}

double const &ui::font_atlas::ascent() const {
    return this->_ascent;
}

double const &ui::font_atlas::descent() const {
    return this->_descent;
}

double const &ui::font_atlas::leading() const {
    return this->_leading;
}

std::string const &ui::font_atlas::words() const {
    return this->_words;
}

ui::texture_ptr const &ui::font_atlas::texture() const {
    return this->_texture->value();
}

ui::vertex2d_rect_t const &ui::font_atlas::rect(std::string const &word) const {
    auto idx = this->_words.find_first_of(word);
    if (idx == std::string::npos) {
        return _empty_rect;
    }
    return this->_word_infos.at(idx).rect;
}

ui::size ui::font_atlas::advance(std::string const &word) const {
    if (word.size() != 1) {
        throw std::invalid_argument("word size is not equal to one.");
    }

    if (word == "\n" || word == "\r") {
        return {0.0f, 0.0f};
    }

    CGGlyph glyphs[1];
    UniChar characters[1];
    CGSize advances[1];

    auto ct_font_obj = this->_impl->_ct_font_ref.object();
    auto cf_word = to_cf_object(word);

    CFIndex const length = CFStringGetLength(cf_word);
    if (length == 0) {
        return {0.0f, 0.0f};
    }

    CFStringGetCharacters(cf_word, CFRangeMake(0, 1), characters);
    CTFontGetGlyphsForCharacters(ct_font_obj, characters, glyphs, 1);
    CTFontGetAdvancesForGlyphs(ct_font_obj, kCTFontOrientationDefault, glyphs, advances, 1);

    return {.width = static_cast<float>(advances[0].width), .height = static_cast<float>(advances[0].height)};
}

void ui::font_atlas::set_texture(ui::texture_ptr const &texture) {
    if (this->texture() != texture) {
        this->_texture->set_value(texture);
    }
}

observing::canceller_ptr ui::font_atlas::observe_texture(observing::caller<texture_ptr>::handler_f &&handler,
                                                         bool const sync) {
    return this->_texture_changed_fetcher->observe(std::move(handler), sync);
}

observing::canceller_ptr ui::font_atlas::observe_texture_updated(
    observing::caller<ui::texture_ptr>::handler_f &&handler) {
    return this->_texture_updated_notifier->observe(std::move(handler));
}

void ui::font_atlas::_update_word_infos() {
    this->_element_cancellers.clear();

    auto &texture = this->texture();

    if (!texture) {
        this->_word_infos.clear();
        return;
    }

    auto ct_font_obj = this->_impl->_ct_font_ref.object();
    auto const word_count = this->_words.size();

    this->_word_infos.resize(word_count);

    CGGlyph glyphs[word_count];
    UniChar characters[word_count];
    CGSize advances[word_count];

    CFStringGetCharacters(to_cf_object(this->_words), CFRangeMake(0, word_count), characters);
    CTFontGetGlyphsForCharacters(ct_font_obj, characters, glyphs, word_count);
    CTFontGetAdvancesForGlyphs(ct_font_obj, kCTFontOrientationDefault, glyphs, advances, word_count);

    CGFloat const ascent = CTFontGetAscent(ct_font_obj);
    CGFloat const descent = CTFontGetDescent(ct_font_obj);
    CGFloat const string_height = descent + ascent;
    double const scale_factor = texture->scale_factor();

    for (auto const &idx : each_index<std::size_t>(word_count)) {
        ui::uint_size const image_size = {uint32_t(std::ceilf(advances[idx].width)),
                                          uint32_t(std::ceilf(string_height))};
        ui::region const image_region = {
            .origin = {0.0f, roundf(-descent, scale_factor)},
            .size = {static_cast<float>(image_size.width), static_cast<float>(image_size.height)}};

        this->_word_infos.at(idx).rect.set_position(image_region);

        auto texture_element = texture->add_draw_handler(
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

        this->_element_cancellers.emplace_back(texture_element->observe_tex_coords(
            [this, idx](ui::uint_region const &tex_coords) {
                this->_word_infos.at(idx).rect.set_tex_coord(tex_coords);
            },
            true));

        auto const &advance = advances[idx];
        this->_word_infos.at(idx).advance = {static_cast<float>(advance.width), static_cast<float>(advance.height)};
    }
}

ui::font_atlas_ptr ui::font_atlas::make_shared(args args) {
    return std::shared_ptr<font_atlas>(new font_atlas{std::move(args)});
}

#pragma mark -

std::string yas::to_string(ui::font_atlas::method const &method) {
    switch (method) {
        case ui::font_atlas::method::texture_changed:
            return "texture_changed";
        case ui::font_atlas::method::texture_updated:
            return "texture_updated";
    }
}
