//
//  yas_sample_modifier_node.mm
//

#include "yas_sample_modifier_node.h"

using namespace yas;

struct sample::modifier_node::impl : base::impl {
    ui::strings_node strings_node;

    impl(ui::font_atlas &&font_atlas) : strings_node({.font_atlas = font_atlas, .max_word_count = 64}) {
        strings_node.set_pivot(ui::pivot::right);
    }

    void setup_renderer_observer() {
        auto &node = strings_node.square_node().node();
        node.dispatch_method(ui::node::method::renderer_changed);
        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_modifier_node = to_weak(cast<modifier_node>()),
            event_observer = base{nullptr},
            view_size_observer = base{nullptr}
        ](auto const &context) mutable {
            auto node = context.value;
            if (auto renderer = node.renderer()) {
                event_observer = renderer.event_manager().subject().make_observer(
                    ui::event_manager::method::modifier_changed,
                    [weak_modifier_node,
                     flags = std::unordered_set<ui::modifier_flags>{}](auto const &context) mutable {
                        ui::event const &event = context.value;
                        if (auto modifier_node = weak_modifier_node.lock()) {
                            modifier_node.impl_ptr<modifier_node::impl>()->update_text(event, flags);
                        }
                    });

                view_size_observer = renderer.subject().make_observer(
                    ui::renderer::method::view_size_changed, [weak_modifier_node](auto const &context) {
                        if (auto modifier_node = weak_modifier_node.lock()) {
                            auto const &renderer = context.value;
                            modifier_node.impl_ptr<modifier_node::impl>()->set_node_position(renderer.view_size());
                        }
                    });

                if (auto modifier_node = weak_modifier_node.lock()) {
                    modifier_node.impl_ptr<modifier_node::impl>()->set_node_position(renderer.view_size());
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

        strings_node.set_text(joined(flag_texts, " + "));
    }

    void set_node_position(ui::uint_size const &view_size) {
        auto &node = strings_node.square_node().node();
        node.set_position(
            {static_cast<float>(view_size.width) * 0.5f, static_cast<float>(view_size.height) * -0.5f + 6.0f});
    }

   private:
    base _renderer_observer = nullptr;
};

sample::modifier_node::modifier_node(ui::font_atlas font_atlas) : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::modifier_node::modifier_node(std::nullptr_t) : base(nullptr) {
}

ui::strings_node &sample::modifier_node::strings_node() {
    return impl_ptr<impl>()->strings_node;
}
