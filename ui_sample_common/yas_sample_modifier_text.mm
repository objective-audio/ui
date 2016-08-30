//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"

using namespace yas;

struct sample::modifier_text::impl : base::impl {
    ui::strings _strings;

    impl(ui::font_atlas &&font_atlas) : _strings({.font_atlas = font_atlas, .max_word_count = 64}) {
        _strings.set_pivot(ui::pivot::right);

        auto &node = _strings.rect_plane().node();
        node.attach_position_layout_guides(_layout_guide_point);
        node.dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::modifier_text &text) {
        auto &node = _strings.rect_plane().node();

        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_text = to_weak(text),
            event_observer = base{nullptr},
            right_layout = ui::layout{nullptr},
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

                    right_layout = ui::make_fixed_layout({.distance = -4.0f,
                                                          .source_guide = renderer.view_layout_guide_rect().right(),
                                                          .destination_guide = text_impl->_layout_guide_point.x()});
                    bottom_layout = ui::make_fixed_layout({.distance = 4.0f,
                                                           .source_guide = renderer.view_layout_guide_rect().bottom(),
                                                           .destination_guide = text_impl->_layout_guide_point.y()});
                } else {
                    event_observer = nullptr;
                    right_layout = nullptr;
                    bottom_layout = nullptr;
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
    ui::layout_guide_point _layout_guide_point;
};

sample::modifier_text::modifier_text(ui::font_atlas font_atlas) : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::modifier_text::modifier_text(std::nullptr_t) : base(nullptr) {
}

ui::strings &sample::modifier_text::strings() {
    return impl_ptr<impl>()->_strings;
}
