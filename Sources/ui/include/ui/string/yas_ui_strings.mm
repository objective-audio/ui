//
//  yas_ui_strings.mm
//

#include "yas_ui_strings.h"

#include <cpp-utils/fast_each.h>
#include <ui/collection_layout/yas_ui_collection_layout.h>
#include <ui/layout/yas_ui_layout_guide.h>
#include <ui/layout/yas_ui_layout_types.h>
#include <ui/mesh/yas_ui_mesh.h>
#include <ui/metal/yas_ui_metal_texture.h>
#include <ui/node/yas_ui_node.h>
#include <ui/rect_plane/yas_ui_rect_plane.h>
#include <numeric>

using namespace yas;
using namespace yas::ui;

strings::strings(strings_args &&args, std::shared_ptr<ui::font_atlas> const &atlas)
    : _collection_layout(collection_layout::make_shared(
          {.frame = args.frame, .alignment = args.alignment, .row_order = layout_order::descending})),
      _rect_plane(rect_plane::make_shared(args.max_word_count)),
      _text(observing::value::holder<std::string>::make_shared(std::move(args.text))),
      _attributes(observing::value::holder<std::vector<strings_attribute>>::make_shared(std::move(args.attributes))),
      _font_atlas(atlas),
      _line_height(observing::value::holder<std::optional<float>>::make_shared(args.line_height)),
      _max_word_count(args.max_word_count) {
    this->rect_plane()->node()->meshes().at(0)->set_texture(atlas->texture());

    this->_prepare_observings();
    this->_update_collection_layout();
    this->_update_data_rects();
}

void strings::set_text(std::string text) {
    this->_text->set_value(std::move(text));
}

void strings::set_attributes(std::vector<strings_attribute> &&attributes) {
    this->_attributes->set_value(std::move(attributes));
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

std::vector<strings_attribute> const &strings::attributes() const {
    return this->_attributes->value();
}

std::shared_ptr<font_atlas> const &strings::font_atlas() const {
    return this->_font_atlas;
}

std::optional<float> const &strings::line_height() const {
    return this->_line_height->value();
}

layout_alignment const &strings::alignment() const {
    return this->_collection_layout->alignment();
}

region strings::actual_frame() const {
    return this->_collection_layout->actual_frame();
}

std::vector<region> const &strings::actual_cell_regions() const {
    return this->_collection_layout->actual_cell_regions();
}

std::shared_ptr<layout_region_guide> const &strings::preferred_layout_guide() const {
    return this->_collection_layout->preferred_layout_guide();
}

std::shared_ptr<layout_region_source> strings::actual_layout_source() const {
    return this->_collection_layout->actual_frame_layout_source();
}

std::shared_ptr<rect_plane> const &strings::rect_plane() {
    return this->_rect_plane;
}

observing::syncable strings::observe_text(std::function<void(std::string const &)> &&handler) {
    return this->_text->observe(std::move(handler));
}

observing::syncable strings::observe_attributes(std::function<void(std::vector<strings_attribute> const &)> &&handler) {
    return this->_attributes->observe(std::move(handler));
}

observing::syncable strings::observe_line_height(std::function<void(std::optional<float> const &)> &&handler) {
    return this->_line_height->observe(std::move(handler));
}

observing::syncable strings::observe_alignment(std::function<void(layout_alignment const &)> &&handler) {
    return this->_collection_layout->observe_alignment(std::move(handler));
}

observing::syncable strings::observe_actual_cell_regions(std::function<void(std::vector<region> const &)> &&handler) {
    return this->_collection_layout->observe_actual_cell_regions(std::move(handler));
}

void strings::_prepare_observings() {
    this->_font_atlas->observe_rects_updated([this](auto const &) { this->_update_collection_layout(); })
        .end()
        ->add_to(this->_pool);

    this->_text->observe([this](auto const &) { this->_update_collection_layout(); }).end()->add_to(this->_pool);
    this->_attributes->observe([this](auto const &) { this->_update_data_rect_colors(); }).end()->add_to(this->_pool);

    this->_line_height->observe([this](auto const &) { this->_update_collection_layout(); }).end()->add_to(this->_pool);

    this->_collection_layout->observe_actual_cell_regions([this](auto const &) { this->_update_data_rects(); })
        .end()
        ->add_to(this->_pool);
}

void strings::_update_collection_layout() {
    auto const &font_atlas = this->_font_atlas;
    if (!font_atlas || !font_atlas->texture() || !font_atlas->texture()->metal_texture()) {
        this->_collection_text = "";
        this->_collection_layout->set_preferred_cell_count(0);
        this->_rect_plane->data()->set_rect_count(0);
        return;
    }

    auto const &src_text = this->_text->value();
    auto const word_count = font_atlas ? std::min(src_text.size(), this->_max_word_count) : 0;
    std::string collection_text;
    collection_text.reserve(word_count);
    auto const cell_height = this->_cell_height();

    std::vector<collection_layout::line> lines;
    std::vector<size> cell_sizes;

    auto each = make_fast_each(word_count);
    while (yas_each_next(each)) {
        auto const word = src_text.substr(yas_each_index(each), 1);
        if (word == "\n" || word == "\r") {
            lines.emplace_back(
                collection_layout::line{.cell_sizes = std::move(cell_sizes), .new_line_min_offset = cell_height});
            cell_sizes.clear();
        } else {
            auto const advance = font_atlas->advance(word);
            cell_sizes.emplace_back(size{.width = advance.width, .height = cell_height});
            collection_text += word;
        }
    }

    if (cell_sizes.size() > 0) {
        lines.emplace_back(
            collection_layout::line{.cell_sizes = std::move(cell_sizes), .new_line_min_offset = cell_height});
    }

    this->_collection_text = collection_text;
    this->_collection_layout->set_lines(std::move(lines));
    this->_collection_layout->set_preferred_cell_count(collection_text.size());
    this->_update_data_rects();
}

void strings::_update_data_rects() {
    auto const cell_count = std::min(this->_collection_layout->actual_cell_count(), this->_collection_text.size());

    if (cell_count == 0) {
        this->_rect_plane->data()->set_rect_count(0);
        return;
    }

    this->_rect_plane->data()->set_rect_count(cell_count);

    auto const &rect_plane_data = this->_rect_plane->data();
    auto const &font_atlas = this->font_atlas();
    float const ascent = font_atlas->ascent();

    auto each = make_fast_each(cell_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto const word = this->_collection_text.substr(idx, 1);
        auto const &region = this->_collection_layout->actual_cell_regions().at(idx);

        auto str_rect = font_atlas->rect(word);
        simd::float2 offset{region.left(), region.top() - ascent};

        for (auto &vertex : str_rect.v) {
            vertex.position += offset;
        }

        rect_plane_data->set_rect_vertex(str_rect.v, idx);
        rect_plane_data->set_rect_color(this->_rect_color_at(idx), idx);
    }
}

void strings::_update_data_rect_colors() {
    auto const &rect_plane_data = this->_rect_plane->data();

    auto each = make_fast_each(rect_plane_data->rect_count());
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        auto const &color = this->_rect_color_at(idx);

        rect_plane_data->set_rect_color(color, idx);
    }
}

ui::color strings::_rect_color_at(std::size_t const idx) const {
    auto const &attributes = this->_attributes->value();

    for (auto it = attributes.rbegin(), end = attributes.rend(); it != end; ++it) {
        auto const &range = it->range;
        if (range.has_value() && !range.value().contains(idx)) {
            continue;
        }

        return it->color;
    }

    return to_color(ui::white_color(), 1.0f);
}

float strings::_cell_height() {
    auto const &line_height = this->_line_height->value();
    if (line_height) {
        return *line_height;
    } else {
        auto const &font_atlas = this->_font_atlas;
        return font_atlas->ascent() + font_atlas->descent() + font_atlas->leading();
    }
}

std::shared_ptr<strings> strings::make_shared(strings_args &&args, std::shared_ptr<ui::font_atlas> const &atlas) {
    return std::shared_ptr<strings>(new strings{std::move(args), atlas});
}
