//
//  yas_sample_modifier_node.mm
//

#include "yas_sample_modifier_node.h"

using namespace yas;

struct sample::modifier_node::impl : base::impl {
    ui::strings_node strings_node;

    impl(ui::font_atlas const &font_atlas) : strings_node(font_atlas, 64) {
        strings_node.set_pivot(ui::pivot::right);
    }

    void setup_renderer_observer() {
        auto &node = strings_node.square_node().node();
        node.dispatch_method(ui::node_method::renderer_changed);
        _renderer_observer = node.subject().make_observer(ui::node_method::renderer_changed, [
            weak_mod_node = to_weak(cast<modifier_node>()),
            event_observer = base{nullptr},
            view_size_observer = base{nullptr}
        ](auto const &context) mutable {
            if (auto mod_node = weak_mod_node.lock()) {
                auto impl = mod_node.impl_ptr<modifier_node::impl>();
                auto node = context.value;
                if (auto renderer = node.renderer()) {
                    event_observer = impl::_make_event_observer(impl->strings_node, renderer.event_manager());
                    view_size_observer =
                        impl::_make_view_size_observer(impl->strings_node.square_node().node(), renderer);
                } else {
                    event_observer = nullptr;
                    view_size_observer = nullptr;
                }
            }
        });
    }

   private:
    static base _make_event_observer(ui::strings_node &str_node, ui::event_manager &event_manager) {
        return event_manager.subject().make_observer(
            ui::event_method::modifier_changed,
            [weak_str_node = to_weak(str_node),
             flags = std::unordered_set<ui::modifier_flags>{}](auto const &context) mutable {
                ui::event const &event = context.value;
                auto flag = event.get<ui::modifier>().flag();

                if (event.phase() == ui::event_phase::began) {
                    flags.insert(flag);
                } else if (event.phase() == ui::event_phase::ended) {
                    flags.erase(flag);
                }

                if (auto str_node = weak_str_node.lock()) {
                    std::vector<std::string> flag_texts;
                    flag_texts.reserve(flags.size());

                    for (auto const &flg : flags) {
                        flag_texts.emplace_back(to_string(flg));
                    }

                    str_node.set_text(joined(flag_texts, " + "));
                }
            });
    }

    static base _make_view_size_observer(ui::node &node, ui::node_renderer &renderer) {
        auto set_position = [](ui::node &node, ui::uint_size const &view_size) {
            node.set_position(
                {static_cast<float>(view_size.width) * 0.5f, static_cast<float>(view_size.height) * -0.5f + 6.0f});
        };

        set_position(node, renderer.view_size());

        return renderer.subject().make_observer(
            ui::renderer_method::view_size_changed,
            [weak_node = to_weak(node), set_position = std::move(set_position)](auto const &context) {
                if (auto node = weak_node.lock()) {
                    auto const &renderer = context.value;
                    set_position(node, renderer.view_size());
                }
            });
    }

    base _renderer_observer = nullptr;
};

sample::modifier_node::modifier_node(ui::font_atlas const &font_atlas) : base(std::make_shared<impl>(font_atlas)) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::modifier_node::modifier_node(std::nullptr_t) : base(nullptr) {
}

ui::strings_node &sample::modifier_node::strings_node() {
    return impl_ptr<impl>()->strings_node;
}
