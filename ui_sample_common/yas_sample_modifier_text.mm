//
//  yas_sample_modifier_text.mm
//

#include "yas_sample_modifier_text.h"

using namespace yas;

struct sample::modifier_text::impl : base::impl {
    ui::strings _strings;

    impl(ui::font_atlas &&font_atlas) : _strings({.font_atlas = font_atlas, .max_word_count = 64}) {
        _strings.set_pivot(ui::pivot::right);
    }

    void setup_renderer_observer() {
        auto &node = _strings.rect_plane().node();
        node.dispatch_method(ui::node::method::renderer_changed);
        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_modifier_text = to_weak(cast<modifier_text>()),
            event_observer = base{nullptr},
            view_size_observer = base{nullptr}
        ](auto const &context) mutable {
            auto node = context.value;
            if (auto renderer = node.renderer()) {
                event_observer = renderer.event_manager().subject().make_observer(
                    ui::event_manager::method::modifier_changed,
                    [weak_modifier_text,
                     flags = std::unordered_set<ui::modifier_flags>{}](auto const &context) mutable {
                        ui::event const &event = context.value;
                        if (auto modifier_text = weak_modifier_text.lock()) {
                            modifier_text.impl_ptr<modifier_text::impl>()->update_text(event, flags);
                        }
                    });

                view_size_observer = renderer.subject().make_observer(
                    ui::renderer::method::view_size_changed, [weak_modifier_text](auto const &context) {
                        if (auto modifier_text = weak_modifier_text.lock()) {
                            auto const &renderer = context.value;
                            modifier_text.impl_ptr<modifier_text::impl>()->set_node_position(renderer.view_size());
                        }
                    });

                if (auto modifier_text = weak_modifier_text.lock()) {
                    modifier_text.impl_ptr<modifier_text::impl>()->set_node_position(renderer.view_size());
                }
            } else {
                event_observer = nullptr;
                view_size_observer = nullptr;
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

    void set_node_position(ui::uint_size const &view_size) {
        auto &node = _strings.rect_plane().node();
        node.set_position(
            {static_cast<float>(view_size.width) * 0.5f, static_cast<float>(view_size.height) * -0.5f + 6.0f});
    }

   private:
    base _renderer_observer = nullptr;
};

sample::modifier_text::modifier_text(ui::font_atlas font_atlas) : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::modifier_text::modifier_text(std::nullptr_t) : base(nullptr) {
}

ui::strings &sample::modifier_text::strings() {
    return impl_ptr<impl>()->_strings;
}
