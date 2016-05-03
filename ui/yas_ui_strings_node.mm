//
//  yas_ui_strings_node.mm
//

#include "yas_each_index.h"
#include "yas_ui_font_atlas.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_node.h"
#include "yas_ui_square_node.h"
#include "yas_ui_strings_node.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::strings_node::impl : base::impl {
    using super_class = base::impl;

    impl(ui::font_atlas &&str_data, std::size_t const max_word_count)
        : _square_node(make_square_node(max_word_count)), _font_atlas(std::move(str_data)) {
        _square_node.node().mesh().set_texture(_font_atlas.texture());
        _update_mesh_data();
    }

    std::string &text() {
        return _text;
    }

    ui::pivot pivot() {
        return _pivot;
    }

    float width() {
        return _width;
    }

    void set_text(std::string &&text) {
        _text = std::move(text);
        _update_mesh_data();
    }

    void set_pivot(ui::pivot const pivot) {
        _pivot = pivot;
        _update_mesh_data();
    }

    void _update_mesh_data() {
        auto &mesh_data = _square_node.square_mesh_data();

        auto const count = std::min(_text.size(), mesh_data.max_square_count());
        auto const layout = _font_atlas.make_strings_layout(_text, _pivot);

        for (auto const &idx : make_each(count)) {
            mesh_data.write(idx, [&layout, &idx](auto &sq_vertex, auto &) { sq_vertex = layout.square(idx); });
        }

        _width = layout.width();
        mesh_data.set_square_count(count);
    }

    ui::square_node _square_node;

   private:
    ui::font_atlas _font_atlas;
    std::string _text;
    ui::pivot _pivot;
    float _width;
};

ui::strings_node::strings_node(font_atlas str_data, std::size_t const max_word_count)
    : base(std::make_shared<impl>(std::move(str_data), max_word_count)) {
}

ui::strings_node::strings_node(std::nullptr_t) : base(nullptr) {
}

std::string const &ui::strings_node::text() const {
    return impl_ptr<impl>()->text();
}

ui::pivot ui::strings_node::pivot() const {
    return impl_ptr<impl>()->pivot();
}

float ui::strings_node::width() const {
    return impl_ptr<impl>()->width();
}

void ui::strings_node::set_text(std::string text) {
    impl_ptr<impl>()->set_text(std::move(text));
}

void ui::strings_node::set_pivot(ui::pivot const pivot) {
    impl_ptr<impl>()->set_pivot(pivot);
}

ui::square_node &ui::strings_node::square_node() {
    return impl_ptr<impl>()->_square_node;
}
