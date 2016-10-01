//
//  yas_ui_font.mm
//

#include <CoreGraphics/CoreGraphics.h>
#include <CoreText/CoreText.h>
#include "yas_cf_ref.h"
#include "yas_cf_utils.h"
#include "yas_each_index.h"
#include "yas_objc_macros.h"
#include "yas_observing.h"
#include "yas_ui_font_atlas.h"
#include "yas_ui_image.h"
#include "yas_ui_math.h"

#if TARGET_OS_IPHONE
#include <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#include <AppKit/AppKit.h>
#endif

using namespace yas;

#pragma mark - font_atlas::impl

namespace yas {
namespace ui {
    static ui::vertex2d_rect_t constexpr _empty_rect{0.0f};

    struct word_info {
        ui::vertex2d_rect_t rect;
        ui::size advance;
    };
}
}

struct ui::font_atlas::impl : base::impl {
    cf_ref<CTFontRef> _ct_font_ref = nullptr;
    std::string _font_name;
    double _font_size;
    double _ascent;
    double _descent;
    double _leading;
    std::string _words;
    ui::font_atlas::subject_t _subject;

    impl(std::string &&font_name, double const font_size, std::string &&words)
        : _ct_font_ref(make_cf_ref(CTFontCreateWithName(to_cf_object(font_name), font_size, nullptr))),
          _font_name(std::move(font_name)),
          _font_size(font_size),
          _words(std::move(words)) {
        auto ct_font_obj = _ct_font_ref.object();
        _ascent = CTFontGetAscent(ct_font_obj);
        _descent = CTFontGetDescent(ct_font_obj);
        _leading = CTFontGetLeading(ct_font_obj);
    }

    ui::texture &texture() {
        return _texture;
    }

    void set_texture(ui::texture &&texture) {
        if (!is_same(_texture, texture)) {
            _texture = std::move(texture);

            _update_texture();

            _subject.notify(ui::font_atlas::method::texture_changed, cast<ui::font_atlas>());
        }
    }

    ui::vertex2d_rect_t const &rect(std::string const &word) {
        auto idx = _words.find_first_of(word);
        if (idx == std::string::npos) {
            return _empty_rect;
        }
        return _word_infos.at(idx).rect;
    }

    ui::size advance(std::string const &word) {
        if (word.size() != 1) {
            throw "word size is not equal to one.";
        }

        if (word == "\n" || word == "\r") {
            return {0.0f, 0.0f};
        }

        CGGlyph glyphs[1];
        UniChar characters[1];
        CGSize advances[1];

        auto ct_font_obj = _ct_font_ref.object();

        CFStringGetCharacters(to_cf_object(word), CFRangeMake(0, 1), characters);
        CTFontGetGlyphsForCharacters(ct_font_obj, characters, glyphs, 1);
        CTFontGetAdvancesForGlyphs(ct_font_obj, kCTFontOrientationDefault, glyphs, advances, 1);

        return {.width = static_cast<float>(advances[0].width), .height = static_cast<float>(advances[0].height)};
    }

   private:
    std::vector<ui::word_info> _word_infos;
    ui::texture _texture = nullptr;

    void _update_texture() {
        if (!_texture) {
            _word_infos.clear();
            return;
        }

        auto ct_font_obj = _ct_font_ref.object();
        auto const word_count = _words.size();

        _word_infos.resize(word_count);

        CGGlyph glyphs[word_count];
        UniChar characters[word_count];
        CGSize advances[word_count];

        CFStringGetCharacters(to_cf_object(_words), CFRangeMake(0, word_count), characters);
        CTFontGetGlyphsForCharacters(ct_font_obj, characters, glyphs, word_count);
        CTFontGetAdvancesForGlyphs(ct_font_obj, kCTFontOrientationDefault, glyphs, advances, word_count);

        auto const ascent = CTFontGetAscent(ct_font_obj);
        auto const descent = CTFontGetDescent(ct_font_obj);
        auto const string_height = descent + ascent;
        auto const scale_factor = _texture.scale_factor();

        for (auto const &idx : each_index<std::size_t>(word_count)) {
            ui::uint_size const image_size = {uint32_t(std::ceilf(advances[idx].width)),
                                              uint32_t(std::ceilf(string_height))};
            ui::region const image_region = {
                .origin = {0.0f, roundf(-descent, scale_factor)},
                .size = {static_cast<float>(image_size.width), static_cast<float>(image_size.height)}};

            _word_infos.at(idx).rect.set_position(image_region);

            ui::image image{{.point_size = image_size, .scale_factor = scale_factor}};

            image.draw([&image_region, &descent, &glyphs, &idx, &ct_font_obj](CGContextRef const ctx) {
                CGContextSaveGState(ctx);

                CGContextTranslateCTM(ctx, 0.0, image_region.size.height);
                CGContextScaleCTM(ctx, 1.0, -1.0);
                CGContextTranslateCTM(ctx, 0.0, descent);
                CGPathRef path = CTFontCreatePathForGlyph(ct_font_obj, glyphs[idx], nullptr);
                CGContextSetFillColorWithColor(ctx, [yas_objc_color whiteColor].CGColor);
                CGContextAddPath(ctx, path);
                CGContextFillPath(ctx);
                CGPathRelease(path);

                CGContextRestoreGState(ctx);
            });

            if (auto result = _texture.add_image(image)) {
                _word_infos.at(idx).rect.set_tex_coord(result.value());
            }

            auto const &advance = advances[idx];
            _word_infos.at(idx).advance = {static_cast<float>(advance.width), static_cast<float>(advance.height)};
        }
    }
};

ui::font_atlas::font_atlas(args args)
    : base(std::make_shared<impl>(std::move(args.font_name), args.font_size, std::move(args.words))) {
    set_texture(std::move(args.texture));
}

ui::font_atlas::font_atlas(std::nullptr_t) : base(nullptr) {
}

ui::font_atlas::~font_atlas() = default;

std::string const &ui::font_atlas::font_name() const {
    return impl_ptr<impl>()->_font_name;
}

double const &ui::font_atlas::font_size() const {
    return impl_ptr<impl>()->_font_size;
}

double const &ui::font_atlas::ascent() const {
    return impl_ptr<impl>()->_ascent;
}

double const &ui::font_atlas::descent() const {
    return impl_ptr<impl>()->_descent;
}

double const &ui::font_atlas::leading() const {
    return impl_ptr<impl>()->_leading;
}

std::string const &ui::font_atlas::words() const {
    return impl_ptr<impl>()->_words;
}

ui::texture const &ui::font_atlas::texture() const {
    return impl_ptr<impl>()->texture();
}

ui::vertex2d_rect_t const &ui::font_atlas::rect(std::string const &word) const {
    return impl_ptr<impl>()->rect(word);
}

ui::size ui::font_atlas::advance(std::string const &word) const {
    return impl_ptr<impl>()->advance(word);
}

void ui::font_atlas::set_texture(ui::texture texture) {
    impl_ptr<impl>()->set_texture(std::move(texture));
}

ui::font_atlas::subject_t &ui::font_atlas::subject() {
    return impl_ptr<impl>()->_subject;
}

#pragma mark -

std::string yas::to_string(ui::font_atlas::method const &method) {
    switch (method) {
        case ui::font_atlas::method::texture_changed:
            return "texture_changed";
    }
}
