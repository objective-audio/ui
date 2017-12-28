//
//  yas_sample_draw_call_text.mm
//

#include "yas_sample_draw_call_text.hpp"
#include "yas_timer.h"

using namespace yas;

struct sample::draw_call_text::impl : base::impl {
    ui::strings _strings;

    impl(ui::font_atlas &&font_atlas)
        : _strings({.text = "---",
                    .alignment = ui::layout_alignment::max,
                    .font_atlas = std::move(font_atlas),
                    .max_word_count = 32}) {
        auto &node = _strings.rect_plane().node();
        node.dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::draw_call_text &text) {
        auto &node = _strings.rect_plane().node();

        this->_renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_text = to_weak(text), left_layout = ui::layout{nullptr}, right_layout = ui::layout{nullptr},
            bottom_layout = ui::layout{nullptr}, strings_observer = ui::strings::observer_t{nullptr}
        ](auto const &context) mutable {
            if (auto text = weak_text.lock()) {
                auto node = context.value;
                if (auto renderer = node.renderer()) {
                    auto &strings = text.strings();
                    auto &strings_guide_rect = strings.frame_layout_guide_rect();
                    auto const &safe_area_guide_rect = renderer.safe_area_layout_guide_rect();
                    left_layout = ui::make_layout({.distance = 4.0f,
                                                   .source_guide = safe_area_guide_rect.left(),
                                                   .destination_guide = strings_guide_rect.right()});

                    right_layout = ui::make_layout({.distance = -4.0f,
                                                    .source_guide = safe_area_guide_rect.right(),
                                                    .destination_guide = strings_guide_rect.right()});

                    bottom_layout = ui::make_layout({.distance = 4.0f,
                                                     .source_guide = safe_area_guide_rect.bottom(),
                                                     .destination_guide = strings_guide_rect.bottom()});

                    auto strings_handler = [top_layout = ui::layout{nullptr}](ui::strings & strings) mutable {
                        float distance = 0.0f;

                        if (strings.font_atlas()) {
                            auto const &font_atlas = strings.font_atlas();
                            distance += font_atlas.ascent() + font_atlas.descent();
                        }

                        top_layout = ui::make_layout({.distance = distance,
                                                      .source_guide = strings.frame_layout_guide_rect().bottom(),
                                                      .destination_guide = strings.frame_layout_guide_rect().top()});
                    };

                    strings_handler(strings);

                    strings_observer = strings.subject().make_observer(ui::strings::method::font_atlas_changed, [
                        strings_handler = std::move(strings_handler), weak_strings = to_weak(strings)
                    ](auto const &context) mutable {
                        if (auto strings = weak_strings.lock()) {
                            strings_handler(strings);
                        }
                    });
                } else {
                    left_layout = nullptr;
                    right_layout = nullptr;
                    bottom_layout = nullptr;
                    strings_observer = nullptr;
                }
            }
        });

        auto timer_handler = [weak_text = to_weak(text)]() {
            if (auto text = weak_text.lock()) {
                text.impl_ptr<impl>()->update_text();
            }
        };

        this->_timer = timer{1.0, true, std::move(timer_handler)};
    }

    void update_text() {
        std::string text = "---";

        if (auto renderer = this->_strings.rect_plane().node().renderer()) {
            if (auto metal_system = renderer.metal_system()) {
                std::size_t const count = metal_system.last_encoded_mesh_count();
                text = "drawcall:" + std::to_string(count);
            }
        }

        this->_strings.set_text(text);
    }

   private:
    timer _timer = nullptr;
    ui::node::observer_t _renderer_observer = nullptr;
};

sample::draw_call_text::draw_call_text(ui::font_atlas font_atlas)
    : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::draw_call_text::draw_call_text(std::nullptr_t) : base(nullptr) {
}

ui::strings &sample::draw_call_text::strings() {
    return impl_ptr<impl>()->_strings;
}
