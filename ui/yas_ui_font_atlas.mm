//
//  yas_ui_font.mm
//

#include "yas_ui_font_atlas.h"
#include <CoreGraphics/CoreGraphics.h>
#include <CoreText/CoreText.h>
#include "yas_cf_ref.h"
#include "yas_cf_utils.h"
#include "yas_each_index.h"
#include "yas_objc_macros.h"
#include "yas_observing.h"
#include "yas_property.h"
#include "yas_ui_image.h"
#include "yas_ui_math.h"
#include "yas_ui_texture_element.h"

#if TARGET_OS_IPHONE
#include <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#include <AppKit/AppKit.h>
#endif

using namespace yas;

#pragma mark - font_atlas::impl

namespace yas::ui {
static ui::vertex2d_rect_t constexpr _empty_rect{0.0f};

struct word_info {
    ui::vertex2d_rect_t rect;
    ui::size advance;
};
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
    flow::sender<ui::texture> _texture_changed_sender;
    flow::sender<ui::texture> _texture_updated_sender;

    impl(std::string &&font_name, double const font_size, std::string &&words)
        : _ct_font_ref(make_cf_ref(CTFontCreateWithName(to_cf_object(font_name), font_size, nullptr))),
          _font_name(std::move(font_name)),
          _font_size(font_size),
          _words(std::move(words)) {
        auto ct_font_obj = _ct_font_ref.object();
        this->_ascent = CTFontGetAscent(ct_font_obj);
        this->_descent = CTFontGetDescent(ct_font_obj);
        this->_leading = CTFontGetLeading(ct_font_obj);
    }

    void prepare(ui::font_atlas &atlas) {
        auto weak_atlas = to_weak(atlas);

        this->_word_tex_coords_receiver =
            flow::receiver<std::pair<ui::uint_region, std::size_t>>([weak_atlas](auto const &pair) {
                if (auto atlas = weak_atlas.lock()) {
                    atlas.impl_ptr<impl>()->_word_infos.at(pair.second).rect.set_tex_coord(pair.first);
                }
            });

        this->_texture_updated_receiver = flow::receiver<ui::texture>([weak_atlas](ui::texture const &texture) {
            if (auto atlas = weak_atlas.lock()) {
                atlas.impl_ptr<impl>()->_texture_updated_sender.send_value(texture);
                atlas.impl_ptr<impl>()->_subject.notify(method::texture_updated, atlas);
            }
        });

        this->_texture_setter_flow = this->_texture_setter.begin()
                                         .guard([weak_atlas](ui::texture const &texture) {
                                             if (auto atlas = weak_atlas.lock()) {
                                                 return !is_same(atlas.texture(), texture);
                                             }
                                             return false;
                                         })
                                         .end(this->_texture_property.receiver());

        this->_texture_changed_receiver = flow::receiver<ui::texture>([weak_atlas](ui::texture const &texture) {
            if (auto atlas = weak_atlas.lock()) {
                auto atlas_impl = atlas.impl_ptr<impl>();

                atlas_impl->_update_word_infos();

                if (texture) {
                    atlas_impl->_texture_flow = texture.begin_flow(texture::method::metal_texture_changed)
                                                    .end(atlas_impl->_texture_updated_receiver);
                } else {
                    atlas_impl->_texture_flow = nullptr;
                }

                atlas_impl->_texture_changed_sender.send_value(texture);
                atlas_impl->_subject.notify(method::texture_changed, atlas);
            }
        });

        this->_texture_changed_flow = this->_texture_property.begin_value_flow().end(this->_texture_changed_receiver);

        this->_texture_changed_sender.set_sync_handler([weak_atlas]() {
            if (auto atlas = weak_atlas.lock()) {
                return opt_t<ui::texture>{atlas.texture()};
            } else {
                return opt_t<ui::texture>{nullopt};
            }
        });
    }

    ui::texture &texture() {
        return this->_texture_property.value();
    }

    void set_texture(ui::texture &&texture) {
        this->_texture_setter.send_value(texture);
    }

    ui::vertex2d_rect_t const &rect(std::string const &word) {
        auto idx = this->_words.find_first_of(word);
        if (idx == std::string::npos) {
            return _empty_rect;
        }
        return this->_word_infos.at(idx).rect;
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

        auto ct_font_obj = this->_ct_font_ref.object();
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

   private:
    property<ui::texture> _texture_property{{.value = nullptr}};
    std::vector<ui::word_info> _word_infos;
    flow::receiver<std::pair<ui::uint_region, std::size_t>> _word_tex_coords_receiver = nullptr;
    std::vector<flow::observer> _element_flows;
    flow::receiver<ui::texture> _texture_updated_receiver = nullptr;
    flow::observer _texture_flow = nullptr;
    flow::sender<ui::texture> _texture_setter;
    flow::observer _texture_setter_flow = nullptr;
    flow::observer _texture_changed_flow = nullptr;
    flow::receiver<ui::texture> _texture_changed_receiver = nullptr;

    void _update_word_infos() {
        this->_element_flows.clear();

        auto &texture = this->texture();

        if (!texture) {
            this->_word_infos.clear();
            return;
        }

        auto weak_atlas = to_weak(cast<ui::font_atlas>());
        auto ct_font_obj = this->_ct_font_ref.object();
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
        double const scale_factor = texture.scale_factor();

        for (auto const &idx : each_index<std::size_t>(word_count)) {
            ui::uint_size const image_size = {uint32_t(std::ceilf(advances[idx].width)),
                                              uint32_t(std::ceilf(string_height))};
            ui::region const image_region = {
                .origin = {0.0f, roundf(-descent, scale_factor)},
                .size = {static_cast<float>(image_size.width), static_cast<float>(image_size.height)}};

            this->_word_infos.at(idx).rect.set_position(image_region);

            auto texture_element = texture.add_draw_handler(
                image_size, [height = image_size.height, glyph = glyphs[idx], ct_font_obj](CGContextRef const ctx) {
                    CGContextSaveGState(ctx);

                    CGContextTranslateCTM(ctx, 0.0, height);
                    CGContextScaleCTM(ctx, 1.0, -1.0);
                    CGContextTranslateCTM(ctx, 0.0, CTFontGetDescent(ct_font_obj));
                    CGPathRef path = CTFontCreatePathForGlyph(ct_font_obj, glyph, nullptr);
                    CGContextSetFillColorWithColor(ctx, [yas_objc_color whiteColor].CGColor);
                    CGContextAddPath(ctx, path);
                    CGContextFillPath(ctx);
                    CGPathRelease(path);

                    CGContextRestoreGState(ctx);
                });

            this->_element_flows.emplace_back(
                texture_element.begin_tex_coords_flow()
                    .map([idx](ui::uint_region const &tex_coords) { return std::make_pair(tex_coords, idx); })
                    .sync(this->_word_tex_coords_receiver));

            auto const &advance = advances[idx];
            this->_word_infos.at(idx).advance = {static_cast<float>(advance.width), static_cast<float>(advance.height)};
        }
    }
};

ui::font_atlas::font_atlas(args args)
    : base(std::make_shared<impl>(std::move(args.font_name), args.font_size, std::move(args.words))) {
    impl_ptr<impl>()->prepare(*this);
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

flow::node<ui::texture, ui::texture, ui::texture> ui::font_atlas::begin_texture_changed_flow() const {
    return impl_ptr<impl>()->_texture_changed_sender.begin();
}

flow::node<ui::texture, ui::texture, ui::texture> ui::font_atlas::begin_texture_updated_flow() const {
    return impl_ptr<impl>()->_texture_updated_sender.begin();
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
