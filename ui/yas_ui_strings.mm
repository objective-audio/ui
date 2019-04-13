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

struct ui::strings::impl : base::impl {
    ui::collection_layout _collection_layout;
    ui::rect_plane _rect_plane;
    chaining::receiver<std::string> _text_receiver = nullptr;

    chaining::value::holder<std::string> _text;
    chaining::value::holder<ui::font_atlas> _font_atlas;
    chaining::value::holder<std::optional<float>> _line_height;

    impl(args &&args)
        : _collection_layout(
              {.frame = args.frame, .alignment = args.alignment, .row_order = ui::layout_order::descending}),
          _rect_plane(args.max_word_count),
          _text(std::move(args.text)),
          _font_atlas(std::move(args.font_atlas)),
          _line_height(args.line_height),
          _max_word_count(args.max_word_count) {
    }

    void prepare(ui::strings &strings) {
        auto weak_strings = to_weak(strings);

        this->_prepare_receivers(weak_strings);
        this->_prepare_chains(weak_strings);

        this->_update_layout();
    }

   private:
    std::size_t const _max_word_count = 0;
    chaining::receiver<ui::texture> _texture_receiver = nullptr;
    chaining::receiver<ui::font_atlas> _update_texture_receiver = nullptr;
    chaining::receiver<std::nullptr_t> _update_layout_receiver = nullptr;
    chaining::any_observer _texture_observer = nullptr;
    std::vector<chaining::any_observer> _property_observers;

    void _prepare_receivers(weak<ui::strings> &weak_strings) {
        this->_texture_receiver = chaining::receiver<ui::texture>([weak_strings](ui::texture const &texture) {
            if (auto strings = weak_strings.lock()) {
                strings.rect_plane().node().mesh().raw().set_texture(texture);
            }
        });

        this->_update_texture_receiver = chaining::receiver<ui::font_atlas>([weak_strings](ui::font_atlas const &) {
            if (auto strings = weak_strings.lock()) {
                strings.impl_ptr<impl>()->_update_texture_chaining();
            }
        });

        this->_update_layout_receiver = chaining::receiver<std::nullptr_t>([weak_strings](auto const &) {
            if (auto strings = weak_strings.lock()) {
                strings.impl_ptr<impl>()->_update_layout();
            }
        });

        this->_text_receiver = chaining::receiver<std::string>([weak_strings](std::string const &text) {
            if (auto strings = weak_strings.lock()) {
                strings.set_text(text);
            }
        });
    }

    void _prepare_chains(weak<ui::strings> &weak_strings) {
        this->_property_observers.emplace_back(this->_font_atlas.chain()
                                                   .send_to(this->_update_texture_receiver)
                                                   .send_null(this->_update_layout_receiver)
                                                   .sync());

        this->_property_observers.emplace_back(this->_text.chain().send_null(this->_update_layout_receiver).end());

        this->_property_observers.emplace_back(
            this->_line_height.chain().send_null(this->_update_layout_receiver).end());

        this->_property_observers.emplace_back(
            this->_collection_layout.chain_actual_cell_count().to_null().send_to(this->_update_layout_receiver).end());

        this->_property_observers.emplace_back(this->_collection_layout.chain_alignment().end());
    }

    void _update_texture_chaining() {
        if (auto &font_atlas = _font_atlas.raw()) {
            if (!this->_texture_observer) {
                auto weak_strings = to_weak(cast<ui::strings>());
                auto strings_impl = weak_strings.lock().impl_ptr<impl>();
                this->_texture_observer = font_atlas.chain_texture()
                                              .guard([weak_strings](auto const &) { return !!weak_strings; })
                                              .send_to(strings_impl->_texture_receiver)
                                              .merge(font_atlas.chain_texture_updated())
                                              .to_null()
                                              .send_to(strings_impl->_update_layout_receiver)
                                              .sync();
            }
        } else {
            this->_rect_plane.node().mesh().raw().set_texture(nullptr);
            this->_texture_observer = nullptr;
        }
    }

    void _update_layout() {
        this->_cell_rect_observers.clear();

        auto const &font_atlas = this->_font_atlas.raw();
        if (!font_atlas || !font_atlas.texture() || !font_atlas.texture().metal_texture()) {
            this->_collection_layout.set_preferred_cell_count(0);
            this->_rect_plane.data().set_rect_count(0);
            return;
        }

        auto const &src_text = this->_text.raw();
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

            auto weak_strings = to_weak(strings);

            this->_cell_rect_observers.emplace_back(
                cell_rect.chain()
                    .guard([weak_strings](ui::region const &) { return !!weak_strings; })
                    .perform([idx, word, weak_strings, handler](ui::region const &value) {
                        auto strings = weak_strings.lock();
                        handler(strings, idx, word, value);
                    })
                    .end());

            handler(strings, idx, word, cell_rect.region());
        }
    }

    float _cell_height() {
        auto const &line_height = this->_line_height.raw();
        if (line_height) {
            return *line_height;
        } else {
            if (auto const &font_atlas = this->_font_atlas.raw()) {
                return font_atlas.ascent() + font_atlas.descent() + font_atlas.leading();
            } else {
                return 0.0f;
            }
        }
    }

   private:
    std::vector<chaining::any_observer> _cell_rect_observers;
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
    impl_ptr<impl>()->_text.set_value(std::move(text));
}

void ui::strings::set_font_atlas(ui::font_atlas atlas) {
    impl_ptr<impl>()->_font_atlas.set_value(std::move(atlas));
}

void ui::strings::set_line_height(std::optional<float> line_height) {
    impl_ptr<impl>()->_line_height.set_value(std::move(line_height));
}

void ui::strings::set_alignment(ui::layout_alignment const alignment) {
    impl_ptr<impl>()->_collection_layout.set_alignment(alignment);
}

std::string const &ui::strings::text() const {
    return impl_ptr<impl>()->_text.raw();
}

ui::font_atlas const &ui::strings::font_atlas() const {
    return impl_ptr<impl>()->_font_atlas.raw();
}

std::optional<float> const &ui::strings::line_height() const {
    return impl_ptr<impl>()->_line_height.raw();
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

chaining::chain_sync_t<std::string> ui::strings::chain_text() const {
    return impl_ptr<impl>()->_text.chain();
}

chaining::chain_sync_t<ui::font_atlas> ui::strings::chain_font_atlas() const {
    return impl_ptr<impl>()->_font_atlas.chain();
}

chaining::chain_sync_t<std::optional<float>> ui::strings::chain_line_height() const {
    return impl_ptr<impl>()->_line_height.chain();
}

chaining::chain_sync_t<ui::layout_alignment> ui::strings::chain_alignment() const {
    return impl_ptr<impl>()->_collection_layout.chain_alignment();
}

chaining::receiver<std::string> &ui::strings::text_receiver() {
    return impl_ptr<impl>()->_text_receiver;
}
