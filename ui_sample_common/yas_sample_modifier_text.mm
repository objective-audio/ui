//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"
#include "yas_flow_utils.h"
#include "yas_stl_utils.h"

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

        this->_renderer_flow =
            node.begin_renderer_flow()
                .perform([weak_text = to_weak(text), event_observer = base{nullptr},
                          left_layout = flow::observer{nullptr}, right_layout = flow::observer{nullptr},
                          bottom_layout = flow::observer{nullptr},
                          strings_flow = flow::observer{nullptr}](ui::renderer const &value) mutable {
                    if (auto text = weak_text.lock()) {
                        auto node = context.value;
                        if (auto renderer = node.renderer()) {
                            event_observer = renderer.event_manager().subject().make_observer(
                                ui::event_manager::method::modifier_changed,
                                [weak_text,
                                 flags = std::unordered_set<ui::modifier_flags>{}](auto const &context) mutable {
                                    ui::event const &event = context.value;
                                    if (auto text = weak_text.lock()) {
                                        auto text_impl = text.impl_ptr<sample::modifier_text::impl>();

                                        text_impl->_update_text(event, flags);
                                    }
                                });

                            auto text_impl = text.impl_ptr<sample::modifier_text::impl>();
                            auto &strings = text_impl->_strings;
                            auto &strings_guide_rect = strings.frame_layout_guide_rect();
                            auto const &safe_area_guide_rect = renderer.safe_area_layout_guide_rect();

                            left_layout = safe_area_guide_rect.left()
                                              .begin_flow()
                                              .map(flow::add(4.0f))
                                              .receive(strings_guide_rect.left().receiver())
                                              .sync();

                            right_layout = safe_area_guide_rect.right()
                                               .begin_flow()
                                               .map(flow::add(-4.0f))
                                               .receive(strings_guide_rect.right().receiver())
                                               .sync();

                            bottom_layout = text_impl->_bottom_guide.begin_flow()
                                                .map(flow::add(4.0f))
                                                .receive(strings_guide_rect.bottom().receiver())
                                                .sync();

                            auto strings_handler = [top_layout =
                                                        flow::observer{nullptr}](ui::strings &strings) mutable {
                                float distance = 0.0f;

                                if (auto const &font_atlas = strings.font_atlas()) {
                                    distance += font_atlas.ascent() + font_atlas.descent();
                                }

                                top_layout = strings.frame_layout_guide_rect()
                                                 .bottom()
                                                 .begin_flow()
                                                 .map(flow::add(distance))
                                                 .receive(strings.frame_layout_guide_rect().top().receiver())
                                                 .sync();
                            };

                            strings_handler(strings);

                            strings_flow =
                                strings.begin_font_atlas_flow()
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
                            strings_flow = nullptr;
                        }
                    }
                })
                .end();
    }

   private:
    flow::observer _renderer_flow = nullptr;

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
