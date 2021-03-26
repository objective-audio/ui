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
using namespace yas::ui;

strings::strings(args args)
    : _collection_layout(collection_layout::make_shared(
          {.frame = args.frame, .alignment = args.alignment, .row_order = layout_order::descending})),
      _rect_plane(rect_plane::make_shared(args.max_word_count)),
      _text(observing::value::holder<std::string>::make_shared(std::move(args.text))),
      _font_atlas(observing::value::holder<font_atlas_ptr>::make_shared(std::move(args.font_atlas))),
      _line_height(observing::value::holder<std::optional<float>>::make_shared(args.line_height)),
      _max_word_count(args.max_word_count) {
    this->_prepare_chains();
    this->_update_layout();
}

strings::~strings() = default;

void strings::set_text(std::string text) {
    this->_text->set_value(std::move(text));
}

void strings::set_font_atlas(font_atlas_ptr atlas) {
    this->_font_atlas->set_value(std::move(atlas));
}

void strings::set_line_height(std::optional<float> line_height) {
    this->_line_height->set_value(std::move(line_height));
}

void strings::set_alignment(layout_alignment const alignment) {
    this->_collection_layout->set_alignment(alignment);
}

std::string const &strings::text() const {
    return this->_text->value();
}

font_atlas_ptr const &strings::font_atlas() const {
    return this->_font_atlas->value();
}

std::optional<float> const &strings::line_height() const {
    return this->_line_height->value();
}

layout_alignment const &strings::alignment() const {
    return this->_collection_layout->alignment();
}

layout_guide_rect_ptr const &strings::frame_layout_guide_rect() {
    return this->_collection_layout->frame_guide_rect;
}

rect_plane_ptr const &strings::rect_plane() {
    return this->_rect_plane;
}

observing::canceller_ptr strings::observe_text(observing::caller<std::string>::handler_f &&handler, bool const sync) {
    return this->_text->observe(std::move(handler), sync);
}

observing::canceller_ptr strings::observe_font_atlas(observing::caller<font_atlas_ptr>::handler_f &&handler,
                                                     bool const sync) {
    return this->_font_atlas->observe(std::move(handler), sync);
}

observing::canceller_ptr strings::observe_line_height(observing::caller<std::optional<float>>::handler_f &&handler,
                                                      bool const sync) {
    return this->_line_height->observe(std::move(handler), sync);
}

observing::canceller_ptr strings::observe_alignment(observing::caller<layout_alignment>::handler_f &&handler,
                                                    bool const sync) {
    return this->_collection_layout->observe_alignment(std::move(handler), sync);
}

void strings::_prepare_chains() {
    this->_font_atlas
        ->observe(
            [this](font_atlas_ptr const &font_atras) {
                this->_update_texture_observing();
                this->_update_layout();
            },
            true)
        ->add_to(this->_property_pool);

    this->_text->observe([this](auto const &) { this->_update_layout(); }, false)->add_to(this->_property_pool);

    this->_line_height->observe([this](auto const &) { this->_update_layout(); }, false)->add_to(this->_property_pool);

    this->_collection_layout->observe_actual_cell_count([this](auto const &) { this->_update_layout(); }, false)
        ->add_to(this->_property_pool);

    this->_collection_layout->observe_alignment([this](auto const &) { this->_update_layout(); }, false)
        ->add_to(this->_property_pool);
}

void strings::_update_texture_observing() {
    if (auto &font_atlas = this->_font_atlas->value()) {
        if (!this->_texture_pool.has_cancellable()) {
            font_atlas
                ->observe_texture(
                    [this](auto const &texture) {
                        this->rect_plane()->node()->mesh()->set_texture(texture);
                        this->_update_layout();
                    },
                    true)
                ->add_to(this->_texture_pool);

            font_atlas->observe_texture_updated([this](auto const &) { this->_update_layout(); })
                ->add_to(this->_texture_pool);
        }
    } else {
        this->_rect_plane->node()->mesh()->set_texture(nullptr);
        this->_texture_pool.cancel();
    }
}

void strings::_update_layout() {
    this->_cell_rect_pool.cancel();

    auto const &font_atlas = this->_font_atlas->value();
    if (!font_atlas || !font_atlas->texture() || !font_atlas->texture()->metal_texture()) {
        this->_collection_layout->set_preferred_cell_count(0);
        this->_rect_plane->data()->set_rect_count(0);
        return;
    }

    auto const &src_text = this->_text->value();
    auto const word_count = font_atlas ? std::min(src_text.size(), this->_max_word_count) : 0;
    std::string eliminated_text;
    eliminated_text.reserve(word_count);
    auto const cell_height = this->_cell_height();

    std::vector<collection_layout::line> lines;
    std::vector<size> cell_sizes;

    auto each = make_fast_each(word_count);
    while (yas_each_next(each)) {
        auto const word = src_text.substr(yas_each_index(each), 1);
        if (word == "\n" || word == "\r") {
            lines.emplace_back(
                collection_layout::line{.cell_sizes = std::move(cell_sizes), .new_line_min_offset = cell_height});
        } else {
            auto const advance = font_atlas->advance(word);
            cell_sizes.emplace_back(size{.width = advance.width, .height = cell_height});
            eliminated_text += word;
        }
    }

    if (cell_sizes.size() > 0) {
        lines.emplace_back(
            collection_layout::line{.cell_sizes = std::move(cell_sizes), .new_line_min_offset = cell_height});
    }

    this->_collection_layout->set_lines(std::move(lines));
    this->_collection_layout->set_preferred_cell_count(eliminated_text.size());

    auto const actual_cell_count = this->_collection_layout->actual_cell_count();

    this->_rect_plane->data()->set_rect_count(actual_cell_count);

    auto handler = [this](std::size_t const idx, std::string const &word, region const &region) {
        auto const &rect_plane_data = this->_rect_plane->data();

        if (idx < rect_plane_data->rect_count()) {
            auto const &font_atlas = this->font_atlas();
            auto str_rect = font_atlas->rect(word);
            float const ascent = font_atlas->ascent();
            simd::float2 offset{region.left(), region.top() - ascent};

            for (auto &vertex : str_rect.v) {
                vertex.position += offset;
            }

            rect_plane_data->set_rect_vertex(str_rect.v, idx);
        }
    };

    each = make_fast_each(actual_cell_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto const word = eliminated_text.substr(idx, 1);
        auto const &cell_rect = this->_collection_layout->cell_guide_rects().at(idx);

        cell_rect->observe([idx, word, handler](region const &value) { handler(idx, word, value); }, false)
            ->add_to(this->_cell_rect_pool);

        handler(idx, word, cell_rect->region());
    }
}

float strings::_cell_height() {
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

strings_ptr strings::make_shared() {
    return make_shared({});
}

strings_ptr strings::make_shared(args args) {
    return std::shared_ptr<strings>(new strings{std::move(args)});
}