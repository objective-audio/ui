//
//  yas_sample_modifier_text_extension.mm
//

#include "yas_sample_modifier_text_extension.h"

using namespace yas;

struct sample::modifier_text_extension::impl : base::impl {
    ui::strings_extension _strings_ext;

    impl(ui::font_atlas &&font_atlas) : _strings_ext({.font_atlas = font_atlas, .max_word_count = 64}) {
        _strings_ext.set_pivot(ui::pivot::right);
    }

    void setup_renderer_observer() {
        auto &node = _strings_ext.rect_plane_extension().node();
        node.dispatch_method(ui::node::method::renderer_changed);
        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_modifier_text_ext = to_weak(cast<sample::modifier_text_extension>()),
            event_observer = base{nullptr},
            view_size_observer = base{nullptr}
        ](auto const &context) mutable {
            auto node = context.value;
            if (auto renderer = node.renderer()) {
                event_observer = renderer.event_manager().subject().make_observer(
                    ui::event_manager::method::modifier_changed,
                    [weak_modifier_text_ext,
                     flags = std::unordered_set<ui::modifier_flags>{}](auto const &context) mutable {
                        ui::event const &event = context.value;
                        if (auto modifier_text_ext = weak_modifier_text_ext.lock()) {
                            modifier_text_ext.impl_ptr<sample::modifier_text_extension::impl>()->update_text(event,
                                                                                                             flags);
                        }
                    });

                view_size_observer = renderer.subject().make_observer(
                    ui::renderer::method::view_size_changed, [weak_modifier_text_ext](auto const &context) {
                        if (auto modifier_text_ext = weak_modifier_text_ext.lock()) {
                            auto const &renderer = context.value;
                            modifier_text_ext.impl_ptr<modifier_text_extension::impl>()->set_node_position(
                                renderer.view_size());
                        }
                    });

                if (auto modifier_text_ext = weak_modifier_text_ext.lock()) {
                    modifier_text_ext.impl_ptr<sample::modifier_text_extension::impl>()->set_node_position(
                        renderer.view_size());
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

        _strings_ext.set_text(joined(flag_texts, " + "));
    }

    void set_node_position(ui::uint_size const &view_size) {
        auto &node = _strings_ext.rect_plane_extension().node();
        node.set_position(
            {static_cast<float>(view_size.width) * 0.5f, static_cast<float>(view_size.height) * -0.5f + 6.0f});
    }

   private:
    base _renderer_observer = nullptr;
};

sample::modifier_text_extension::modifier_text_extension(ui::font_atlas font_atlas)
    : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->setup_renderer_observer();
}

sample::modifier_text_extension::modifier_text_extension(std::nullptr_t) : base(nullptr) {
}

ui::strings_extension &sample::modifier_text_extension::strings_extension() {
    return impl_ptr<impl>()->_strings_ext;
}
