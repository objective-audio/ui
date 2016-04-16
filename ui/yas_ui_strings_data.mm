//
//  yas_ui_strings_data.mm
//

#include <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>
#include "yas_cf_utils.h"
#include "yas_objc_macros.h"
#import "yas_ui_image.h"
#include "yas_ui_strings_data.h"
#include "yas_ui_texture.h"

#if TARGET_OS_IPHONE
#include <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#include <AppKit/AppKit.h>
#endif

using namespace yas;

#pragma mark - strings_info

ui::strings_info::strings_info(std::size_t const word_count) : _squares(word_count), _width(0.0) {
}

ui::vertex2d_square_t const &ui::strings_info::square(std::size_t const word_index) const {
    return _squares.at(word_index);
}

std::vector<ui::vertex2d_square_t> const &ui::strings_info::squares() const {
    return _squares;
}

std::size_t ui::strings_info::word_count() const {
    return _squares.size();
}

double ui::strings_info::width() const {
    return _width;
}

#pragma mark - mutable_strings_info

namespace yas {
namespace ui {
    struct mutable_strings_info : strings_info {
        mutable_strings_info(std::size_t const word_size) : strings_info(word_size) {
        }

        ui::vertex2d_square_t &square(std::size_t const word_index) {
            return _squares.at(word_index);
        }

        void set_width(double const width) {
            _width = width;
        }
    };
}
}

#pragma mark - strings_data::impl

struct ui::strings_data::impl : base::impl {
    ui::texture texture;
    std::string font_name;
    double font_size;
    std::string words;

    impl(std::string &&font_name, double const font_size, std::string &&words, ui::texture &&texture)
        : font_name(std::move(font_name)), font_size(font_size), words(std::move(words)), texture(std::move(texture)) {
        CTFontRef ct_font = CTFontCreateWithName(to_cf_object(font_name), font_size, nullptr);
        setup(ct_font);
        CFRelease(ct_font);
    }

    void setup(CTFontRef const &ct_font) {
        auto const word_size = words.size();

        _squares.resize(word_size);
        _advances.resize(word_size);

        CGGlyph glyphs[word_size];
        UniChar characters[word_size];

        CFStringGetCharacters(to_cf_object(words), CFRangeMake(0, word_size), characters);
        CTFontGetGlyphsForCharacters(ct_font, characters, glyphs, word_size);
        CTFontGetAdvancesForGlyphs(ct_font, kCTFontOrientationDefault, glyphs, _advances.data(), word_size);

        auto const ascent = CTFontGetAscent(ct_font);
        auto const descent = CTFontGetDescent(ct_font);
        auto const string_height = descent + ascent;

        for (auto const &idx : each_index<std::size_t>(word_size)) {
            uint_region const image_region{{0, UInt32(roundf(-descent))},
                                           {UInt32(ceilf(_advances[idx].width)), UInt32(ceilf(string_height))}};

            _set_vertex_position(image_region, idx);

            ui::image image{image_region.size};

            image.draw([&image_region, &descent, &glyphs, &idx, &ct_font](CGContextRef const ctx) {
                CGContextSaveGState(ctx);

                CGContextTranslateCTM(ctx, 0.0, image_region.size.height);
                CGContextScaleCTM(ctx, 1.0, -1.0);
                CGContextTranslateCTM(ctx, 0.0, descent);
                CGPathRef path = CTFontCreatePathForGlyph(ct_font, glyphs[idx], nullptr);
                CGContextSetFillColorWithColor(ctx, [yas_objc_color whiteColor].CGColor);
                CGContextAddPath(ctx, path);
                CGContextFillPath(ctx);
                CGPathRelease(path);

                CGContextRestoreGState(ctx);
            });

            if (auto result = texture.add_image(image)) {
                _set_vertex_tex_coords(result.value(), idx);
            }
        }
    }

    strings_info make_strings_info(std::string const &text, pivot const pivot) {
        auto const word_size = text.size();

        ui::mutable_strings_info strings_info{word_size};

        double width = 0;

        for (auto const &word_idx : each_index<std::size_t>(word_size)) {
            auto const word = text.substr(word_idx, 1);
            auto const &str_square = _square(word);
            auto &info_square = strings_info.square(word_idx);

            for (auto const &sq_idx : each_index<std::size_t>(4)) {
                info_square.v[sq_idx] = str_square.v[sq_idx];
                info_square.v[sq_idx].position[0] += roundf(width);
            }

            width += _advance(word).width;
        }

        strings_info.set_width(ceil(width));

        if (pivot != pivot::left) {
            double offset = 0;

            if (pivot == pivot::center) {
                offset = -width * 0.5;
            } else if (pivot == pivot::right) {
                offset = -width;
            }

            for (auto &square : strings_info.squares()) {
                for (auto &vertex : square.v) {
                    vertex.position[0] += offset;
                }
            }
        }

        return std::move(strings_info);
    }

    ui::vertex2d_square_t &_square(std::string const &word) {
        auto idx = words.find_first_of(word);
        if (idx == std::string::npos) {
            idx = 0;
        }
        return _squares.at(idx);
    }

    void _set_vertex_position(uint_region const &region, std::size_t const word_idx) {
        auto &square = _squares.at(word_idx);
        Float32 const minX = region.origin.x;
        Float32 const minY = region.origin.y;
        Float32 const maxX = minX + region.size.width;
        Float32 const maxY = minY + region.size.height;
        square.v[0].position[0] = square.v[2].position[0] = minX;
        square.v[0].position[1] = square.v[1].position[1] = minY;
        square.v[1].position[0] = square.v[3].position[0] = maxX;
        square.v[2].position[1] = square.v[3].position[1] = maxY;
    }

    void _set_vertex_tex_coords(uint_region const &region, std::size_t const word_idx) {
        auto &square = _squares.at(word_idx);
        Float32 const minX = region.origin.x;
        Float32 const minY = region.origin.y;
        Float32 const maxX = minX + region.size.width;
        Float32 const maxY = minY + region.size.height;
        square.v[0].tex_coord[0] = square.v[2].tex_coord[0] = minX;
        square.v[0].tex_coord[1] = square.v[1].tex_coord[1] = maxY;
        square.v[1].tex_coord[0] = square.v[3].tex_coord[0] = maxX;
        square.v[2].tex_coord[1] = square.v[3].tex_coord[1] = minY;
    }

    CGSize const &_advance(std::string const &word) {
        auto idx = words.find(word);
        if (idx == std::string::npos) {
            idx = 0;
        }
        return _advances.at(idx);
    }

   private:
    std::vector<ui::vertex2d_square_t> _squares;
    std::vector<CGSize> _advances;
};

ui::strings_data::strings_data(std::string font_name, double const font_size, std::string words, ui::texture texture)
    : super_class(std::make_shared<impl>(std::move(font_name), font_size, std::move(words), std::move(texture))) {
}

std::string const &ui::strings_data::font_name() const {
    return impl_ptr<impl>()->font_name;
}

double const &ui::strings_data::font_size() const {
    return impl_ptr<impl>()->font_size;
}

std::string const &ui::strings_data::words() const {
    return impl_ptr<impl>()->words;
}

ui::texture const &ui::strings_data::texture() const {
    return impl_ptr<impl>()->texture;
}

ui::strings_info ui::strings_data::make_strings_info(std::string const &text, pivot const pivot) const {
    return std::move(impl_ptr<impl>()->make_strings_info(text, pivot));
}
