//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"

using namespace yas;

struct sample::modifier_text::impl : base::impl {
    ui::dynamic_strings _strings;

    impl(ui::font_atlas &&font_atlas)
        : _strings({.font_atlas = font_atlas, .max_word_count = 64, .alignment = ui::layout_alignment::max}) {
        auto &node = _strings.rect_plane().node();
        node.dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::modifier_text &text) {
        auto &node = _strings.rect_plane().node();

        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_text = to_weak(text),
            event_observer = base{nullptr},
            left_layout = ui::layout{nullptr},
            right_layout = ui::layout{nullptr},
            top_layout = ui::layout{nullptr},
            bottom_layout = ui::layout{nullptr}
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

                                text_impl->update_text(event, flags);
                            }
                        });

                    auto text_impl = text.impl_ptr<sample::modifier_text::impl>();
                    auto &strings = text_impl->_strings;
                    auto &strings_guide_rect = strings.frame_layout_guide_rect();
                    auto const &font_atlas = strings.font_atlas();
                    float const string_height = font_atlas.ascent() + font_atlas.descent();

                    left_layout = ui::make_layout({.distance = 4.0f,
                                                   .source_guide = renderer.view_layout_guide_rect().left(),
                                                   .destination_guide = strings_guide_rect.left()});

                    right_layout = ui::make_layout({.distance = -4.0f,
                                                    .source_guide = renderer.view_layout_guide_rect().right(),
                                                    .destination_guide = strings_guide_rect.right()});

                    bottom_layout = ui::make_layout({.distance = 4.0f,
                                                     .source_guide = renderer.view_layout_guide_rect().bottom(),
                                                     .destination_guide = strings_guide_rect.bottom()});

                    top_layout = ui::make_layout({.distance = 4.0f + string_height,
                                                  .source_guide = renderer.view_layout_guide_rect().bottom(),
                                                  .destination_guide = strings_guide_rect.top()});

                } else {
                    event_observer = nullptr;
                    left_layout = nullptr;
                    right_layout = nullptr;
                    bottom_layout = nullptr;
                    top_layout = nullptr;
                }
            }
        });
    }

    void update_text(ui::event const &event, std::unordered_set<ui::modifier_flags> &flags) {
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

        _strings.set_text(joined(flag_texts, " + "));
    }

   private:
    ui::node::observer_t _renderer_observer = nullptr;
};

sample::modifier_text::modifier_text(ui::font_atlas font_atlas) : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::modifier_text::modifier_text(std::nullptr_t) : base(nullptr) {
}

ui::dynamic_strings &sample::modifier_text::strings() {
    return impl_ptr<impl>()->_strings;
}
