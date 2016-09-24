//
//  yas_ui_dynamic_strings.mm
//

#include <numeric>
#include "yas_each_index.h"
#include "yas_ui_collection_layout.h"
#include "yas_ui_dynamic_strings.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_layout_types.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"

using namespace yas;

struct ui::dynamic_strings::impl : base::impl {
    ui::collection_layout _collection_layout;
    ui::rect_plane _rect_plane;

    impl(args &&args)
        : _collection_layout({.frame = args.frame}),
          _rect_plane(make_rect_plane(args.max_word_count)),
          _args(std::move(args)) {
        if (_args.line_height < 0.0f) {
            throw "line_height is negative.";
        }

        _collection_layout.set_alignment(_args.alignment);
        _collection_layout.set_row_order(ui::layout_order::descending);
    }

    void prepare(ui::dynamic_strings &strings) {
        auto weak_strings = to_weak(strings);

        _collection_observer = _collection_layout.subject().make_observer(
            ui::collection_layout::method::actual_cell_count_changed, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_layout();
                }
            });

        _update_font_atlas_observer();
        _update_layout();
    }

    void set_text(std::string &&text) {
        if (_args.text != text) {
            _args.text = std::move(text);

            _update_layout();
        }
    }

    void set_font_atlas(ui::font_atlas &&atlas) {
        if (_args.font_atlas != atlas) {
            _args.font_atlas = std::move(atlas);

            _update_font_atlas_observer();
            _update_layout();
        }
    }

    void set_line_height(float const line_height) {
        if (_args.line_height != line_height) {
            _args.line_height = line_height;

            _update_layout();
        }
    }

    std::string &text() {
        return _args.text;
    }

    ui::font_atlas &font_atlas() {
        return _args.font_atlas;
    }

    float line_height() {
        if (_args.line_height == 0 && _args.font_atlas) {
            return _args.font_atlas.ascent() + _args.font_atlas.descent() + _args.font_atlas.leading();
        } else {
            return _args.line_height;
        }
    }

   private:
    args _args;
    ui::font_atlas::observer_t _font_atlas_observer = nullptr;
    ui::collection_layout::observer_t _collection_observer = nullptr;

    void _update_font_atlas_observer() {
        if (_args.font_atlas) {
            if (!_font_atlas_observer) {
                _font_atlas_observer = _args.font_atlas.subject().make_observer(
                    ui::font_atlas::method::texture_changed,
                    [weak_strings = to_weak(cast<ui::dynamic_strings>())](auto const &context) {
                        if (auto strings = weak_strings.lock()) {
                            strings.rect_plane().node().mesh().set_texture(strings.font_atlas().texture());
                            strings.impl_ptr<impl>()->_update_layout();
                        }
                    });

                _rect_plane.node().mesh().set_texture(_args.font_atlas.texture());
            }
        } else {
            _rect_plane.node().mesh().set_texture(nullptr);
            _font_atlas_observer = nullptr;
        }
    }

    void _update_layout() {
        auto const &font_atlas = _args.font_atlas;
        auto const &src_text = _args.text;
        auto const word_count = font_atlas ? std::min(src_text.size(), _args.max_word_count) : 0;
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

        auto handler = [](ui::dynamic_strings &strings, std::size_t const idx, std::string const &word,
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

        auto strings = cast<ui::dynamic_strings>();

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

ui::dynamic_strings::dynamic_strings() : dynamic_strings(args{}) {
}

ui::dynamic_strings::dynamic_strings(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::dynamic_strings::dynamic_strings(std::nullptr_t) : base(nullptr) {
}

ui::dynamic_strings::~dynamic_strings() = default;

void ui::dynamic_strings::set_text(std::string text) {
    impl_ptr<impl>()->set_text(std::move(text));
}

void ui::dynamic_strings::set_font_atlas(ui::font_atlas atlas) {
    impl_ptr<impl>()->set_font_atlas(std::move(atlas));
}

void ui::dynamic_strings::set_line_height(float const line_height) {
    impl_ptr<impl>()->set_line_height(std::move(line_height));
}

void ui::dynamic_strings::set_alignment(ui::layout_alignment const alignment) {
    impl_ptr<impl>()->_collection_layout.set_alignment(alignment);
}

std::string const &ui::dynamic_strings::text() const {
    return impl_ptr<impl>()->text();
}

ui::font_atlas const &ui::dynamic_strings::font_atlas() const {
    return impl_ptr<impl>()->font_atlas();
}

float ui::dynamic_strings::line_height() const {
    return impl_ptr<impl>()->line_height();
}

ui::layout_alignment ui::dynamic_strings::alignment() const {
    return impl_ptr<impl>()->_collection_layout.alignment();
}

ui::layout_guide_rect &ui::dynamic_strings::frame_layout_guide_rect() {
    return impl_ptr<impl>()->_collection_layout.frame_layout_guide_rect();
}

ui::rect_plane &ui::dynamic_strings::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}
