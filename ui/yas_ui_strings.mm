//
//  yas_ui_strings.mm
//

#include <numeric>
#include "yas_fast_each.h"
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

    property<std::nullptr_t, std::string> _text_property;
    property<std::nullptr_t, ui::font_atlas> _font_atlas_property;
    property<std::nullptr_t, std::experimental::optional<float>> _line_height_property;

    impl(args &&args)
        : _collection_layout(
              {.frame = args.frame, .alignment = args.alignment, .row_order = ui::layout_order::descending}),
          _rect_plane(make_rect_plane(args.max_word_count)),
          _text_property({.value = std::move(args.text)}),
          _font_atlas_property({.value = std::move(args.font_atlas)}),
          _line_height_property({.value = args.line_height,
                                 .validator =
                                     [](auto const &value) {
                                         if (value) {
                                             return *value >= 0.0f;
                                         } else {
                                             return true;
                                         }
                                     }}),
          _max_word_count(args.max_word_count) {
    }

    void prepare(ui::strings &strings) {
        auto weak_strings = to_weak(strings);

        this->_collection_observers.emplace_back(this->_collection_layout.subject().make_observer(
            ui::collection_layout::method::actual_cell_count_changed, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_layout();
                }
            }));

        this->_collection_observers.emplace_back(this->_collection_layout.subject().make_observer(
            ui::collection_layout::method::alignment_changed, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.subject().notify(ui::strings::method::alignment_changed, strings);
                }
            }));

        this->_property_observers.emplace_back(this->_text_property.subject().make_observer(
            property_method::did_change, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_layout();

                    strings.subject().notify(ui::strings::method::text_changed, strings);
                }
            }));

        this->_property_observers.emplace_back(this->_font_atlas_property.subject().make_observer(
            property_method::did_change, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_font_atlas_observer();
                    strings.impl_ptr<impl>()->_update_layout();

                    strings.subject().notify(ui::strings::method::font_atlas_changed, strings);
                }
            }));

        this->_property_observers.emplace_back(this->_line_height_property.subject().make_observer(
            property_method::did_change, [weak_strings](auto const &context) {
                if (auto strings = weak_strings.lock()) {
                    strings.impl_ptr<impl>()->_update_layout();

                    strings.subject().notify(ui::strings::method::line_height_changed, strings);
                }
            }));

        this->_update_font_atlas_observer();
        this->_update_layout();
    }

   private:
    std::size_t const _max_word_count = 0;
    ui::font_atlas::observer_t _font_atlas_observer = nullptr;
    std::vector<ui::collection_layout::observer_t> _collection_observers;
    std::vector<base> _property_observers;

    void _update_font_atlas_observer() {
        if (auto &font_atlas = _font_atlas_property.value()) {
            if (!this->_font_atlas_observer) {
                this->_font_atlas_observer = font_atlas.subject().make_observer(
                    ui::font_atlas::method::texture_changed,
                    [weak_strings = to_weak(cast<ui::strings>())](auto const &context) {
                        if (auto strings = weak_strings.lock()) {
                            strings.rect_plane().node().mesh().set_texture(strings.font_atlas().texture());
                            strings.impl_ptr<impl>()->_update_layout();
                        }
                    });

                this->_rect_plane.node().mesh().set_texture(font_atlas.texture());
            }
        } else {
            this->_rect_plane.node().mesh().set_texture(nullptr);
            this->_font_atlas_observer = nullptr;
        }
    }

    void _update_layout() {
        auto const &font_atlas = this->_font_atlas_property.value();
        if (!font_atlas || !font_atlas.texture()) {
            this->_collection_layout.set_preferred_cell_count(0);
            this->_rect_plane.data().set_rect_count(0);
            return;
        }

        auto const &src_text = this->_text_property.value();
        auto const word_count = font_atlas ? std::min(src_text.size(), this->_max_word_count) : 0;
        std::string eliminated_text;
        eliminated_text.reserve(word_count);
        auto const cell_height = this->_cell_height();

        std::vector<ui::collection_layout::line> lines;
        std::vector<ui::size> cell_sizes;

        auto each = make_fast_each(word_count);
        while (yas_each_next(each)) {
            auto const word = src_text.substr(yas_each_index(each), 1);
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

        this->_collection_layout.set_lines(std::move(lines));
        this->_collection_layout.set_preferred_cell_count(eliminated_text.size());

        auto const actual_cell_count = this->_collection_layout.actual_cell_count();

        this->_rect_plane.data().set_rect_count(actual_cell_count);

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

        each = make_fast_each(actual_cell_count);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            auto const word = eliminated_text.substr(idx, 1);
            auto &cell_rect = this->_collection_layout.cell_layout_guide_rects().at(idx);

            cell_rect.set_value_changed_handler(
                [idx, word, weak_strings = to_weak(strings), handler](auto const &context) {
                    if (auto strings = weak_strings.lock()) {
                        handler(strings, idx, word, context.new_value);
                    }
                });

            handler(strings, idx, word, cell_rect.region());
        }
    }

    float _cell_height() {
        auto const &line_height = this->_line_height_property.value();
        if (line_height) {
            return *line_height;
        } else {
            if (auto const &font_atlas = this->_font_atlas_property.value()) {
                return font_atlas.ascent() + font_atlas.descent() + font_atlas.leading();
            } else {
                return 0.0f;
            }
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

void ui::strings::set_line_height(std::experimental::optional<float> line_height) {
    impl_ptr<impl>()->_line_height_property.set_value(std::move(line_height));
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

std::experimental::optional<float> const &ui::strings::line_height() const {
    return impl_ptr<impl>()->_line_height_property.value();
}

ui::layout_alignment const &ui::strings::alignment() const {
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
