//
//  yas_ui_strings.mm
//

#include "yas_ui_strings.h"
#include <cpp_utils/yas_fast_each.h>
#include <numeric>
#include "yas_ui_collection_layout.h"
#include "yas_ui_layout_guide.h"
#include "yas_ui_layout_types.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"

using namespace yas;

ui::strings::strings(args args)
    : _collection_layout(ui::collection_layout::make_shared(
          {.frame = args.frame, .alignment = args.alignment, .row_order = ui::layout_order::descending})),
      _rect_plane(ui::rect_plane::make_shared(args.max_word_count)),
      _text(chaining::value::holder<std::string>::make_shared(std::move(args.text))),
      _font_atlas(chaining::value::holder<ui::font_atlas_ptr>::make_shared(std::move(args.font_atlas))),
      _line_height(chaining::value::holder<std::optional<float>>::make_shared(args.line_height)),
      _max_word_count(args.max_word_count) {
}

ui::strings::~strings() = default;

void ui::strings::set_text(std::string text) {
    this->_text->set_value(std::move(text));
}

void ui::strings::set_font_atlas(ui::font_atlas_ptr atlas) {
    this->_font_atlas->set_value(std::move(atlas));
}

void ui::strings::set_line_height(std::optional<float> line_height) {
    this->_line_height->set_value(std::move(line_height));
}

void ui::strings::set_alignment(ui::layout_alignment const alignment) {
    this->_collection_layout->alignment->set_value(alignment);
}

std::string const &ui::strings::text() const {
    return this->_text->value();
}

ui::font_atlas_ptr const &ui::strings::font_atlas() const {
    return this->_font_atlas->value();
}

std::optional<float> const &ui::strings::line_height() const {
    return this->_line_height->value();
}

ui::layout_alignment const &ui::strings::alignment() const {
    return this->_collection_layout->alignment->value();
}

ui::layout_guide_rect_ptr &ui::strings::frame_layout_guide_rect() {
    return this->_collection_layout->frame_guide_rect;
}

ui::rect_plane_ptr const &ui::strings::rect_plane() {
    return this->_rect_plane;
}

chaining::chain_sync_t<std::string> ui::strings::chain_text() const {
    return this->_text->chain();
}

chaining::chain_sync_t<ui::font_atlas_ptr> ui::strings::chain_font_atlas() const {
    return this->_font_atlas->chain();
}

chaining::chain_sync_t<std::optional<float>> ui::strings::chain_line_height() const {
    return this->_line_height->chain();
}

chaining::chain_sync_t<ui::layout_alignment> ui::strings::chain_alignment() const {
    return this->_collection_layout->alignment->chain();
}

chaining::receiver_ptr<std::string> ui::strings::text_receiver() {
    return this->_text_receiver;
}

void ui::strings::_prepare(strings_ptr const &strings) {
    this->_weak_strings = to_weak(strings);

    this->_prepare_receivers(this->_weak_strings);
    this->_prepare_chains(this->_weak_strings);

    this->_update_layout();
}

void ui::strings::_prepare_receivers(ui::strings_wptr const &weak_strings) {
    this->_texture_receiver =
        chaining::perform_receiver<ui::texture_ptr>::make_shared([weak_strings](ui::texture_ptr const &texture) {
            if (auto strings = weak_strings.lock()) {
                strings->rect_plane()->node()->mesh()->value()->set_texture(texture);
            }
        });

    this->_update_texture_receiver =
        chaining::perform_receiver<ui::font_atlas_ptr>::make_shared([weak_strings](ui::font_atlas_ptr const &) {
            if (auto strings = weak_strings.lock()) {
                strings->_update_texture_chaining();
            }
        });

    this->_update_layout_receiver =
        chaining::perform_receiver<std::nullptr_t>::make_shared([weak_strings](auto const &) {
            if (auto strings = weak_strings.lock()) {
                strings->_update_layout();
            }
        });

    this->_text_receiver =
        chaining::perform_receiver<std::string>::make_shared([weak_strings](std::string const &text) {
            if (auto strings = weak_strings.lock()) {
                strings->set_text(text);
            }
        });
}

void ui::strings::_prepare_chains(ui::strings_wptr const &weak_strings) {
    this->_property_observers.emplace_back(this->_font_atlas->chain()
                                               .send_to(this->_update_texture_receiver)
                                               .send_null_to(this->_update_layout_receiver)
                                               .sync());

    this->_property_observers.emplace_back(this->_text->chain().send_null_to(this->_update_layout_receiver).end());

    this->_property_observers.emplace_back(
        this->_line_height->chain().send_null_to(this->_update_layout_receiver).end());

    this->_property_observers.emplace_back(
        this->_collection_layout->actual_cell_count()->chain().to_null().send_to(this->_update_layout_receiver).end());

    this->_property_observers.emplace_back(this->_collection_layout->alignment->chain().end());
}

void ui::strings::_update_texture_chaining() {
    if (auto &font_atlas = this->_font_atlas->value()) {
        if (!this->_texture_observer) {
            auto &weak_strings = this->_weak_strings;
            this->_texture_observer = font_atlas->chain_texture()
                                          .guard([weak_strings](auto const &) { return !weak_strings.expired(); })
                                          .send_to(this->_texture_receiver)
                                          .merge(font_atlas->chain_texture_updated())
                                          .to_null()
                                          .send_to(this->_update_layout_receiver)
                                          .sync();
        }
    } else {
        this->_rect_plane->node()->mesh()->value()->set_texture(nullptr);
        this->_texture_observer = nullptr;
    }
}

void ui::strings::_update_layout() {
    this->_cell_rect_observers.clear();

    auto const &font_atlas = this->_font_atlas->value();
    if (!font_atlas || !font_atlas->texture() || !font_atlas->texture()->metal_texture()) {
        this->_collection_layout->preferred_cell_count->set_value(0);
        this->_rect_plane->data()->set_rect_count(0);
        return;
    }

    auto const &src_text = this->_text->value();
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
            lines.emplace_back(
                ui::collection_layout::line{.cell_sizes = std::move(cell_sizes), .new_line_min_offset = cell_height});
        } else {
            auto const advance = font_atlas->advance(word);
            cell_sizes.emplace_back(ui::size{.width = advance.width, .height = cell_height});
            eliminated_text += word;
        }
    }

    if (cell_sizes.size() > 0) {
        lines.emplace_back(
            ui::collection_layout::line{.cell_sizes = std::move(cell_sizes), .new_line_min_offset = cell_height});
    }

    this->_collection_layout->lines->set_value(std::move(lines));
    this->_collection_layout->preferred_cell_count->set_value(eliminated_text.size());

    auto const actual_cell_count = this->_collection_layout->actual_cell_count()->value();

    this->_rect_plane->data()->set_rect_count(actual_cell_count);

    auto handler = [](ui::strings_ptr const &strings, std::size_t const idx, std::string const &word,
                      ui::region const &region) {
        auto const &rect_plane_data = strings->_rect_plane->data();

        if (idx < rect_plane_data->rect_count()) {
            auto const &font_atlas = strings->font_atlas();
            auto str_rect = font_atlas->rect(word);
            float const ascent = font_atlas->ascent();
            simd::float2 offset{region.left(), region.top() - ascent};

            for (auto &vertex : str_rect.v) {
                vertex.position += offset;
            }

            rect_plane_data->set_rect_vertex(str_rect.v, idx);
        }
    };

    auto strings = this->_weak_strings.lock();

    each = make_fast_each(actual_cell_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto const word = eliminated_text.substr(idx, 1);
        auto &cell_rect = this->_collection_layout->cell_guide_rects.at(idx);

        auto weak_strings = to_weak(strings);

        this->_cell_rect_observers.emplace_back(
            cell_rect->chain()
                .guard([weak_strings](ui::region const &) { return !weak_strings.expired(); })
                .perform([idx, word, weak_strings, handler](ui::region const &value) {
                    auto strings = weak_strings.lock();
                    handler(strings, idx, word, value);
                })
                .end());

        handler(strings, idx, word, cell_rect->region());
    }
}

float ui::strings::_cell_height() {
    auto const &line_height = this->_line_height->value();
    if (line_height) {
        return *line_height;
    } else {
        if (auto const &font_atlas = this->_font_atlas->value()) {
            return font_atlas->ascent() + font_atlas->descent() + font_atlas->leading();
        } else {
            return 0.0f;
        }
    }
}

ui::strings_ptr ui::strings::make_shared() {
    return make_shared({});
}

ui::strings_ptr ui::strings::make_shared(args args) {
    auto shared = std::shared_ptr<strings>(new strings{std::move(args)});
    shared->_prepare(shared);
    return shared;
}
