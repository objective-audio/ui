//
//  yas_ui_strings.mm
//

#include <numeric>
#include "yas_each_index.h"
#include "yas_observing.h"
#include "yas_property.h"
#include "yas_ui_collection_layout.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_layout_types.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_strings.h"

using namespace yas;

struct ui::strings::impl : base::impl {
    ui::collection_layout _collection_layout;
    ui::rect_plane _rect_plane;
    subject_t _subject;

    property<std::string> _text_property;
    property<ui::font_atlas> _font_atlas_property;

    impl(args &&args)
        : _collection_layout({.frame = args.frame}),
          _rect_plane(make_rect_plane(args.max_word_count)),
          _text_property({.value = std::move(args.text)}),
          _font_atlas_property({.value = std::move(args.font_atlas)}),
          _line_height_property({.value = args.line_height}),
          _max_word_count(args.max_word_count) {
        if (_line_height_property.value() < 0.0f) {
            throw "line_height is negative.";
        }

        _collection_layout.set_alignment(args.alignment);
        _collection_layout.set_row_order(ui::layout_order::descending);
    }

    void prepare(ui::strings &strings) {
        auto weak_strings = to_weak(strings);

        _collection_observers.emplace_back(_collection_layout.subject().make_observer(
            ui::collection_layout::method::actual_cell_count_changed, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_layout();
                }
            }));

        _collection_observers.emplace_back(_collection_layout.subject().make_observer(
            ui::collection_layout::method::alignment_changed, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    if (strings.subject().has_observer()) {
                        strings.subject().notify(ui::strings::method::alignment_changed, strings);
                    }
                }
            }));

        _property_observers.emplace_back(
            _text_property.subject().make_observer(property_method::did_change, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_layout();

                    if (strings.subject().has_observer()) {
                        strings.subject().notify(ui::strings::method::text_changed, strings);
                    }
                }
            }));

        _property_observers.emplace_back(_font_atlas_property.subject().make_observer(
            property_method::did_change, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_font_atlas_observer();
                    strings.impl_ptr<impl>()->_update_layout();

                    if (strings.subject().has_observer()) {
                        strings.subject().notify(ui::strings::method::font_atlas_changed, strings);
                    }
                }
            }));

        _property_observers.emplace_back(_line_height_property.subject().make_observer(
            property_method::did_change, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_layout();

                    if (strings.subject().has_observer()) {
                        strings.subject().notify(ui::strings::method::line_height_changed, strings);
                    }
                }
            }));

        _update_font_atlas_observer();
        _update_layout();
    }

    void set_line_height(float const line_height) {
        _line_height_property.set_value(line_height);
    }

    float line_height() {
        auto const &line_height = _line_height_property.value();
        auto const &font_atlas = _font_atlas_property.value();

        if (line_height == 0 && font_atlas) {
            return font_atlas.ascent() + font_atlas.descent() + font_atlas.leading();
        } else {
            return line_height;
        }
    }

   private:
    std::size_t const _max_word_count = 0;
    property<float> _line_height_property;
    ui::font_atlas::observer_t _font_atlas_observer = nullptr;
    std::vector<ui::collection_layout::observer_t> _collection_observers;
    std::vector<base> _property_observers;

    void _update_font_atlas_observer() {
        if (auto &font_atlas = _font_atlas_property.value()) {
            if (!_font_atlas_observer) {
                _font_atlas_observer = font_atlas.subject().make_observer(
                    ui::font_atlas::method::texture_changed,
                    [weak_strings = to_weak(cast<ui::strings>())](auto const &context) {
                        if (auto strings = weak_strings.lock()) {
                            strings.rect_plane().node().mesh().set_texture(strings.font_atlas().texture());
                            strings.impl_ptr<impl>()->_update_layout();
                        }
                    });

                _rect_plane.node().mesh().set_texture(font_atlas.texture());
            }
        } else {
            _rect_plane.node().mesh().set_texture(nullptr);
            _font_atlas_observer = nullptr;
        }
    }

    void _update_layout() {
        auto const &font_atlas = _font_atlas_property.value();
        if (!font_atlas || !font_atlas.texture()) {
            _collection_layout.set_preferred_cell_count(0);
            _rect_plane.data().set_rect_count(0);
            return;
        }

        auto const &src_text = _text_property.value();
        auto const word_count = font_atlas ? std::min(src_text.size(), _max_word_count) : 0;
        std::string eliminated_text;
        eliminated_text.reserve(word_count);
        auto const cell_height = line_height();

        std::vector<ui::collection_layout::line> lines;
        std::vector<ui::size> cell_sizes;

        for (auto const &idx : make_each(word_count)) {
            auto const word = src_text.substr(idx, 1);
            if (word == "\n" || word == "\r") {
                lines.emplace_back(ui::collection_layout::line{.cell_sizes = std::move(cell_sizes),
                                                               .new_line_min_offset = cell_height});
            } else {
                auto const advance = font_atlas.advance(word);
                cell_sizes.emplace_back(ui::size{.width = advance.width, .height = cell_height});
                eliminated_text += word;
            }
        }

        if (cell_sizes.size() > 0) {
            lines.emplace_back(
                ui::collection_layout::line{.cell_sizes = std::move(cell_sizes), .new_line_min_offset = cell_height});
        }

        _collection_layout.set_lines(std::move(lines));
        _collection_layout.set_preferred_cell_count(eliminated_text.size());

        auto const actual_cell_count = _collection_layout.actual_cell_count();
        auto const prev_rect_count = _rect_plane.data().rect_count();

        _rect_plane.data().set_rect_count(actual_cell_count);

        auto handler = [](ui::strings &strings, std::size_t const idx, std::string const &word,
                          ui::region const &region) {
            auto &rect_plane_data = strings.impl_ptr<impl>()->_rect_plane.data();

            if (idx < rect_plane_data.rect_count()) {
                auto const &font_atlas = strings.font_atlas();
                auto str_rect = font_atlas.rect(word);
                float const ascent = font_atlas.ascent();
                simd::float2 offset{region.left(), region.top() - ascent};

                for (auto &vertex : str_rect.v) {
                    vertex.position += offset;
                }

                rect_plane_data.set_rect_vertex(str_rect.v, idx);
            }
        };

        auto strings = cast<ui::strings>();

        for (auto const &idx : make_each(actual_cell_count)) {
            auto const word = eliminated_text.substr(idx, 1);
            auto &cell_rect = _collection_layout.cell_layout_guide_rects().at(idx);

            if (idx >= prev_rect_count) {
                cell_rect.set_value_changed_handler(
                    [idx, word, weak_strings = to_weak(strings), handler](auto const &context) {
                        if (auto strings = weak_strings.lock()) {
                            handler(strings, idx, word, context.new_value);
                        }
                    });
            }

            handler(strings, idx, word, cell_rect.region());
        }
    }
};

ui::strings::strings() : strings(args{}) {
}

ui::strings::strings(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::strings::strings(std::nullptr_t) : base(nullptr) {
}

ui::strings::~strings() = default;

void ui::strings::set_text(std::string text) {
    impl_ptr<impl>()->_text_property.set_value(std::move(text));
}

void ui::strings::set_font_atlas(ui::font_atlas atlas) {
    impl_ptr<impl>()->_font_atlas_property.set_value(std::move(atlas));
}

void ui::strings::set_line_height(float const line_height) {
    impl_ptr<impl>()->set_line_height(std::move(line_height));
}

void ui::strings::set_alignment(ui::layout_alignment const alignment) {
    impl_ptr<impl>()->_collection_layout.set_alignment(alignment);
}

std::string const &ui::strings::text() const {
    return impl_ptr<impl>()->_text_property.value();
}

ui::font_atlas const &ui::strings::font_atlas() const {
    return impl_ptr<impl>()->_font_atlas_property.value();
}

float ui::strings::line_height() const {
    return impl_ptr<impl>()->line_height();
}

ui::layout_alignment ui::strings::alignment() const {
    return impl_ptr<impl>()->_collection_layout.alignment();
}

ui::layout_guide_rect &ui::strings::frame_layout_guide_rect() {
    return impl_ptr<impl>()->_collection_layout.frame_layout_guide_rect();
}

ui::rect_plane &ui::strings::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}

ui::strings::subject_t &ui::strings::subject() {
    return impl_ptr<impl>()->_subject;
}
