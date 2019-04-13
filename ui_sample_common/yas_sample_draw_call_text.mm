//
//  yas_sample_draw_call_text.mm
//

#include "yas_sample_draw_call_text.hpp"
#include <chaining/yas_chaining_utils.h>
#include <cpp_utils/yas_timer.h>

using namespace yas;

struct sample::draw_call_text::impl : base::impl {
    ui::strings _strings;

    impl(ui::font_atlas &&font_atlas)
        : _strings({.text = "---",
                    .alignment = ui::layout_alignment::max,
                    .font_atlas = std::move(font_atlas),
                    .max_word_count = 32}) {
    }

    void prepare(sample::draw_call_text &text) {
        auto &node = this->_strings.rect_plane().node();

        this->_renderer_observer =
            node.chain_renderer()
                .perform([weak_text = to_weak(text), left_layout = chaining::any_observer{nullptr},
                          right_layout = chaining::any_observer{nullptr},
                          bottom_layout = chaining::any_observer{nullptr},
                          strings_observer = chaining::any_observer{nullptr}](ui::renderer const &value) mutable {
                    if (auto text = weak_text.lock()) {
                        if (auto renderer = value) {
                            auto &strings = text.strings();
                            auto &strings_guide_rect = strings.frame_layout_guide_rect();
                            auto const &safe_area_guide_rect = renderer.safe_area_layout_guide_rect();
                            left_layout = safe_area_guide_rect.left()
                                              .chain()
                                              .to(chaining::add(4.0f))
                                              .send_to(strings_guide_rect.right().receiver())
                                              .sync();

                            right_layout = safe_area_guide_rect.right()
                                               .chain()
                                               .to(chaining::add(-4.0f))
                                               .send_to(strings_guide_rect.right().receiver())
                                               .sync();

                            bottom_layout = safe_area_guide_rect.bottom()
                                                .chain()
                                                .to(chaining::add(4.0f))
                                                .send_to(strings_guide_rect.bottom().receiver())
                                                .sync();

                            auto strings_handler = [top_layout =
                                                        chaining::any_observer{nullptr}](ui::strings &strings) mutable {
                                float distance = 0.0f;

                                if (strings.font_atlas()) {
                                    auto const &font_atlas = strings.font_atlas();
                                    distance += font_atlas.ascent() + font_atlas.descent();
                                }

                                top_layout = strings.frame_layout_guide_rect()
                                                 .bottom()
                                                 .chain()
                                                 .send_to(strings.frame_layout_guide_rect().top().receiver())
                                                 .sync();
                            };

                            strings_handler(strings);

                            strings_observer =
                                strings.chain_font_atlas()
                                    .perform([strings_handler = std::move(strings_handler),
                                              weak_strings = to_weak(strings)](ui::font_atlas const &) mutable {
                                        if (auto strings = weak_strings.lock()) {
                                            strings_handler(strings);
                                        }
                                    })
                                    .end();
                        } else {
                            left_layout = nullptr;
                            right_layout = nullptr;
                            bottom_layout = nullptr;
                            strings_observer = nullptr;
                        }
                    }
                })
                .end();

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
    chaining::any_observer _renderer_observer = nullptr;
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
