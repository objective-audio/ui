//
//  yas_ui_font.mm
//

#include <CoreGraphics/CoreGraphics.h>
#include <CoreText/CoreText.h>
#include "yas_cf_utils.h"
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

#pragma mark - strings_layout

ui::strings_layout::strings_layout(std::size_t const word_count) : _squares(word_count), _width(0.0) {
}

ui::vertex2d_square_t const &ui::strings_layout::square(std::size_t const word_index) const {
    return _squares.at(word_index);
}

std::vector<ui::vertex2d_square_t> const &ui::strings_layout::squares() const {
    return _squares;
}

std::size_t ui::strings_layout::word_count() const {
    return _squares.size();
}

double ui::strings_layout::width() const {
    return _width;
}

#pragma mark - mutable_strings_layout

namespace yas {
namespace ui {
    struct mutable_strings_layout : strings_layout {
        mutable_strings_layout(std::size_t const word_size) : strings_layout(word_size) {
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

#pragma mark - font_atlas::impl

namespace yas {
namespace ui {
    static ui::vertex2d_square_t constexpr _empty_square{0.0f};
    static CGSize constexpr _empty_advance{0.0f};
}
}

struct ui::font_atlas::impl : base::impl {
    std::string _font_name;
    double _font_size;
    std::string _words;
    ui::font_atlas::subject_t _subject;

    impl(std::string &&font_name, double const font_size, std::string &&words)
        : _font_name(std::move(font_name)), _font_size(font_size), _words(std::move(words)) {
    }

    ui::texture &texture() {
        return _texture;
    }

    void set_texture(ui::texture &&texture) {
        if (!is_same(_texture, texture)) {
            _texture = std::move(texture);

            _update_texture();

            if (_subject.has_observer()) {
                _subject.notify(ui::font_atlas_method::texture_changed, cast<ui::font_atlas>());
            }
        }
    }

    strings_layout make_strings_layout(std::string const &text, pivot const pivot) {
        if (!_texture) {
            return ui::mutable_strings_layout{0};
        }

        auto const word_size = text.size();

        ui::mutable_strings_layout strings_layout{word_size};

        double width = 0;
        auto const scale_factor = _texture.scale_factor();

        if (pivot == pivot::right) {
            for (auto const &idx : each_index<std::size_t>(word_size)) {
                auto const &word_idx = word_size - idx - 1;
                auto const word = text.substr(word_idx, 1);
                auto const &str_square = _square(word);

                width += _advance(word).width;

                auto &layout_square = strings_layout.square(word_idx);

                if (&str_square == &_empty_square) {
                    layout_square = {0.0f};
                } else {
                    for (auto const &sq_idx : each_index<std::size_t>(4)) {
                        layout_square.v[sq_idx] = str_square.v[sq_idx];
                        layout_square.v[sq_idx].position.x =
                            roundf(layout_square.v[sq_idx].position.x - width, scale_factor);
                    }
                }
            }
        } else {
            for (auto const &word_idx : each_index<std::size_t>(word_size)) {
                auto const word = text.substr(word_idx, 1);
                auto const &str_square = _square(word);

                auto &layout_square = strings_layout.square(word_idx);

                if (&str_square == &_empty_square) {
                    layout_square = {0.0f};
                } else {
                    for (auto const &sq_idx : each_index<std::size_t>(4)) {
                        layout_square.v[sq_idx] = str_square.v[sq_idx];
                        layout_square.v[sq_idx].position.x =
                            roundf(layout_square.v[sq_idx].position.x + width, scale_factor);
                    }
                }

                width += _advance(word).width;
            }
        }

        strings_layout.set_width(ceil(width, scale_factor));

        if (pivot == pivot::center) {
            double offset = roundf(-width * 0.5, scale_factor);

            for (auto &square : strings_layout.squares()) {
                for (auto &vertex : square.v) {
                    vertex.position.x += offset;
                }
            }
        }

        return std::move(strings_layout);
    }

   private:
    std::vector<ui::vertex2d_square_t> _squares;
    std::vector<CGSize> _advances;
    ui::texture _texture = nullptr;

    void _update_texture() {
        if (!_texture) {
            _squares.clear();
            _advances.clear();
            return;
        }

        CTFontRef ct_font = CTFontCreateWithName(to_cf_object(_font_name), _font_size, nullptr);

        auto const word_size = _words.size();

        _squares.resize(word_size);
        _advances.resize(word_size);

        CGGlyph glyphs[word_size];
        UniChar characters[word_size];

        CFStringGetCharacters(to_cf_object(_words), CFRangeMake(0, word_size), characters);
        CTFontGetGlyphsForCharacters(ct_font, characters, glyphs, word_size);
        CTFontGetAdvancesForGlyphs(ct_font, kCTFontOrientationDefault, glyphs, _advances.data(), word_size);

        auto const ascent = CTFontGetAscent(ct_font);
        auto const descent = CTFontGetDescent(ct_font);
        auto const string_height = descent + ascent;
        auto const scale_factor = _texture.scale_factor();

        for (auto const &idx : each_index<std::size_t>(word_size)) {
            ui::uint_size const image_size = {uint32_t(std::ceilf(_advances[idx].width)),
                                              uint32_t(std::ceilf(string_height))};
            ui::float_region const image_region = {0.0f, roundf(-descent, scale_factor),
                                                   static_cast<float>(image_size.width),
                                                   static_cast<float>(image_size.height)};

            _set_vertex_position(image_region, idx);

            ui::image image{{.point_size = image_size, .scale_factor = scale_factor}};

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

            if (auto result = _texture.add_image(image)) {
                _set_vertex_tex_coords(result.value(), idx);
            }
        }

        CFRelease(ct_font);
    }

    ui::vertex2d_square_t const &_square(std::string const &word) {
        auto idx = _words.find_first_of(word);
        if (idx == std::string::npos) {
            return _empty_square;
        }
        return _squares.at(idx);
    }

    void _set_vertex_position(float_region const &region, std::size_t const word_idx) {
        auto &square = _squares.at(word_idx);
        float const minX = region.origin.x;
        float const minY = region.origin.y;
        float const maxX = minX + region.size.width;
        float const maxY = minY + region.size.height;
        square.v[0].position.x = square.v[2].position.x = minX;
        square.v[0].position.y = square.v[1].position.y = minY;
        square.v[1].position.x = square.v[3].position.x = maxX;
        square.v[2].position.y = square.v[3].position.y = maxY;
    }

    void _set_vertex_tex_coords(uint_region const &region, std::size_t const word_idx) {
        auto &square = _squares.at(word_idx);
        float const minX = region.origin.x;
        float const minY = region.origin.y;
        float const maxX = minX + region.size.width;
        float const maxY = minY + region.size.height;
        square.v[0].tex_coord.x = square.v[2].tex_coord.x = minX;
        square.v[0].tex_coord.y = square.v[1].tex_coord.y = maxY;
        square.v[1].tex_coord.x = square.v[3].tex_coord.x = maxX;
        square.v[2].tex_coord.y = square.v[3].tex_coord.y = minY;
    }

    CGSize const &_advance(std::string const &word) {
        auto idx = _words.find(word);
        if (idx == std::string::npos) {
            return _empty_advance;
        }
        return _advances.at(idx);
    }
};

ui::font_atlas::font_atlas(args args)
    : base(std::make_shared<impl>(std::move(args.font_name), args.font_size, std::move(args.words))) {
    set_texture(std::move(args.texture));
}

ui::font_atlas::font_atlas(std::nullptr_t) : base(nullptr) {
}

std::string const &ui::font_atlas::font_name() const {
    return impl_ptr<impl>()->_font_name;
}

double const &ui::font_atlas::font_size() const {
    return impl_ptr<impl>()->_font_size;
}

std::string const &ui::font_atlas::words() const {
    return impl_ptr<impl>()->_words;
}

ui::texture const &ui::font_atlas::texture() const {
    return impl_ptr<impl>()->texture();
}

void ui::font_atlas::set_texture(ui::texture texture) {
    impl_ptr<impl>()->set_texture(std::move(texture));
}

ui::font_atlas::subject_t &ui::font_atlas::subject() {
    return impl_ptr<impl>()->_subject;
}

ui::strings_layout ui::font_atlas::make_strings_layout(std::string const &text, pivot const pivot) const {
    return std::move(impl_ptr<impl>()->make_strings_layout(text, pivot));
}

#pragma mark -

std::string yas::to_string(ui::font_atlas_method const &method) {
    switch (method) {
        case ui::font_atlas_method::texture_changed:
            return "texture_changed";
    }
}
