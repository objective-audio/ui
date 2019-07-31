//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"
#include <chaining/yas_chaining_utils.h>
#include <cpp_utils/yas_stl_utils.h>

using namespace yas;

struct sample::modifier_text::impl : base::impl {
    ui::strings _strings;
    ui::layout_guide _bottom_guide;

    impl(ui::font_atlas &&font_atlas, ui::layout_guide &&bottom_guide)
        : _strings({.font_atlas = std::move(font_atlas), .max_word_count = 64, .alignment = ui::layout_alignment::max}),
          _bottom_guide(std::move(bottom_guide)) {
    }

    void prepare(sample::modifier_text &text) {
        auto &node = this->_strings.rect_plane().node();

        this->_renderer_observer =
            node.chain_renderer()
                .perform([weak_text = to_weak(text), event_observer = chaining::any_observer{nullptr},
                          left_layout = chaining::any_observer{nullptr}, right_layout = chaining::any_observer{nullptr},
                          bottom_layout = chaining::any_observer{nullptr},
                          strings_observer = chaining::any_observer{nullptr}](ui::renderer const &value) mutable {
                    if (auto text = weak_text.lock()) {
                        if (auto renderer = value) {
                            event_observer = renderer.event_manager()
                                                 .chain(ui::event_manager::method::modifier_changed)
                                                 .perform([weak_text, flags = std::unordered_set<ui::modifier_flags>{}](
                                                              ui::event const &event) mutable {
                                                     if (auto text = weak_text.lock()) {
                                                         auto text_impl = text.impl_ptr<sample::modifier_text::impl>();

                                                         text_impl->_update_text(event, flags);
                                                     }
                                                 })
                                                 .end();

                            auto text_impl = text.impl_ptr<sample::modifier_text::impl>();
                            auto &strings = text_impl->_strings;
                            auto &strings_guide_rect = strings.frame_layout_guide_rect();
                            auto const &safe_area_guide_rect = renderer.safe_area_layout_guide_rect();

                            left_layout = safe_area_guide_rect.left()
                                              .chain()
                                              .to(chaining::add(4.0f))
                                              .send_to(strings_guide_rect.left())
                                              .sync();

                            right_layout = safe_area_guide_rect.right()
                                               .chain()
                                               .to(chaining::add(-4.0f))
                                               .send_to(strings_guide_rect.right())
                                               .sync();

                            bottom_layout = text_impl->_bottom_guide.chain()
                                                .to(chaining::add(4.0f))
                                                .send_to(strings_guide_rect.bottom())
                                                .sync();

                            auto strings_handler = [top_layout =
                                                        chaining::any_observer{nullptr}](ui::strings &strings) mutable {
                                float distance = 0.0f;

                                if (auto const &font_atlas = strings.font_atlas()) {
                                    distance += font_atlas.ascent() + font_atlas.descent();
                                }

                                top_layout = strings.frame_layout_guide_rect()
                                                 .bottom()
                                                 .chain()
                                                 .to(chaining::add(distance))
                                                 .send_to(strings.frame_layout_guide_rect().top())
                                                 .sync();
                            };

                            strings_handler(strings);

                            strings_observer =
                                strings.chain_font_atlas()
                                    .perform([strings_handler = std::move(strings_handler),
                                              weak_strings = to_weak(strings)](ui::font_atlas const &value) mutable {
                                        if (auto strings = weak_strings.lock()) {
                                            strings_handler(strings);
                                        }
                                    })
                                    .end();
                        } else {
                            event_observer = nullptr;
                            left_layout = nullptr;
                            right_layout = nullptr;
                            bottom_layout = nullptr;
                            strings_observer = nullptr;
                        }
                    }
                })
                .end();
    }

   private:
    chaining::any_observer_ptr _renderer_observer = nullptr;

    void _update_text(ui::event const &event, std::unordered_set<ui::modifier_flags> &flags) {
        auto flag = event.get<ui::modifier>().flag();

        if (event.phase() == ui::event_phase::began) {
            flags.insert(flag);
        } else if (event.phase() == ui::event_phase::ended) {
            flags.erase(flag);
        }

        std::vector<std::string> flag_texts;
        flag_texts.reserve(flags.size());

        for (auto const &flg : flags) {
            flag_texts.emplace_back(to_string(flg));
        }

        this->_strings.set_text(joined(flag_texts, " + "));
    }
};

sample::modifier_text::modifier_text(ui::font_atlas font_atlas, ui::layout_guide bottom_guide)
    : base(std::make_shared<impl>(std::move(font_atlas), std::move(bottom_guide))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::modifier_text::modifier_text(std::nullptr_t) : base(nullptr) {
}

ui::strings &sample::modifier_text::strings() {
    return impl_ptr<impl>()->_strings;
}
