//
//  yas_ui_strings.mm
//

#include "yas_each_index.h"
#include "yas_observing.h"
#include "yas_ui_font_atlas.h"
#include "yas_ui_mesh.h"
#include "yas_ui_mesh_data.h"
#include "yas_ui_node.h"
#include "yas_ui_rect_plane.h"
#include "yas_ui_strings.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::strings::impl : base::impl {
    impl(std::size_t const max_word_count) : _rect_plane(make_rect_plane(max_word_count)) {
    }

    ui::font_atlas &font_atlas() {
        return _font_atlas;
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

    void set_font_atlas(ui::font_atlas &&atlas) {
        _font_atlas = std::move(atlas);

        if (_font_atlas) {
            _rect_plane.node().mesh().set_texture(_font_atlas.texture());
            _font_atlas_observer =
                _font_atlas.subject().make_observer(ui::font_atlas::method::texture_changed,
                                                    [weak_strings = to_weak(cast<ui::strings>())](auto const &context) {
                                                        if (auto strings = weak_strings.lock()) {
                                                            strings.impl_ptr<impl>()->update_mesh_data();
                                                        }
                                                    });
        } else {
            _rect_plane.node().mesh().set_texture(nullptr);
            _font_atlas_observer = nullptr;
        }

        update_mesh_data();
    }

    void set_text(std::string &&text) {
        _text = std::move(text);
        update_mesh_data();
    }

    void set_pivot(ui::pivot const pivot) {
        _pivot = pivot;
        update_mesh_data();
    }

    void update_mesh_data() {
        auto &mesh_data = _rect_plane.data();

        if (_font_atlas && _font_atlas.texture()) {
            auto const count = std::min(_text.size(), mesh_data.max_rect_count());
            auto const layout = _font_atlas.make_strings_layout(_text, _pivot);

            for (auto const &idx : make_each(count)) {
                mesh_data.write_vertex(idx, [&layout, &idx](auto &vertex_rect) { vertex_rect = layout.rect(idx); });
            }

            _width = layout.width();
            mesh_data.set_rect_count(count);
            _rect_plane.node().mesh().set_texture(_font_atlas.texture());
        } else {
            _width = 0;
            mesh_data.set_rect_count(0);
            _rect_plane.node().mesh().set_texture(nullptr);
        }
    }

    ui::rect_plane _rect_plane;

   private:
    ui::font_atlas _font_atlas = nullptr;
    std::string _text;
    ui::pivot _pivot = ui::pivot::left;
    float _width = 0.0f;

    ui::font_atlas::observer_t _font_atlas_observer = nullptr;
};

ui::strings::strings(args args) : base(std::make_shared<impl>(args.max_word_count)) {
    set_font_atlas(std::move(args.font_atlas));
}

ui::strings::strings(std::nullptr_t) : base(nullptr) {
}

ui::strings::~strings() = default;

ui::font_atlas const &ui::strings::font_atlas() const {
    return impl_ptr<impl>()->font_atlas();
}

std::string const &ui::strings::text() const {
    return impl_ptr<impl>()->text();
}

ui::pivot ui::strings::pivot() const {
    return impl_ptr<impl>()->pivot();
}

float ui::strings::width() const {
    return impl_ptr<impl>()->width();
}

void ui::strings::set_font_atlas(ui::font_atlas atlas) {
    impl_ptr<impl>()->set_font_atlas(std::move(atlas));
}

void ui::strings::set_text(std::string text) {
    impl_ptr<impl>()->set_text(std::move(text));
}

void ui::strings::set_pivot(ui::pivot const pivot) {
    impl_ptr<impl>()->set_pivot(pivot);
}

ui::rect_plane &ui::strings::rect_plane() {
    return impl_ptr<impl>()->_rect_plane;
}
