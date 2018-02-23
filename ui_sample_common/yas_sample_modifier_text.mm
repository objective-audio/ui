//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"

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

        this->_renderer_observer = node.dispatch_and_make_observer(ui::node::method::renderer_changed, [
            weak_text = to_weak(text), event_observer = base{nullptr}, left_layout = ui::layout{nullptr},
            right_layout = ui::layout{nullptr}, bottom_layout = ui::layout{nullptr},
            strings_observer = ui::strings::observer_t{nullptr}
        ](auto const &context) mutable {
            if (auto text = weak_text.lock()) {
                auto node = context.value;
                if (auto renderer = node.renderer()) {
                    event_observer = renderer.event_manager().subject().make_observer(
                        ui::event_manager::method::modifier_changed,
                        [weak_text, flags = std::unordered_set<ui::modifier_flags>{}](auto const &context) mutable {
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

                    left_layout = ui::make_layout({.distance = 4.0f,
                                                   .source_guide = safe_area_guide_rect.left(),
                                                   .destination_guide = strings_guide_rect.left()});

                    right_layout = ui::make_layout({.distance = -4.0f,
                                                    .source_guide = safe_area_guide_rect.right(),
                                                    .destination_guide = strings_guide_rect.right()});

                    bottom_layout = ui::make_layout({.distance = 4.0f,
                                                     .source_guide = text_impl->_bottom_guide,
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
                    event_observer = nullptr;
                    left_layout = nullptr;
                    right_layout = nullptr;
                    bottom_layout = nullptr;
                    strings_observer = nullptr;
                }
            }
        });
    }

   private:
    ui::node::observer_t _renderer_observer = nullptr;

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
