//
//  yas_sample_modifier_text_extension.mm
//

#include "yas_sample_modifier_text_extension.h"
#include "yas_ui_fixed_layout.h"

using namespace yas;

struct sample::modifier_text_extension::impl : base::impl {
    ui::strings_extension _strings_ext;

    impl(ui::font_atlas &&font_atlas) : _strings_ext({.font_atlas = font_atlas, .max_word_count = 64}) {
        _strings_ext.set_pivot(ui::pivot::right);

        auto &node = _strings_ext.rect_plane_extension().node();
        node.attach_position_layout_guides(_layout_guide_point);
        node.dispatch_method(ui::node::method::renderer_changed);
    }

    void prepare(sample::modifier_text_extension &ext) {
        auto &node = _strings_ext.rect_plane_extension().node();

        _renderer_observer = node.subject().make_observer(ui::node::method::renderer_changed, [
            weak_ext = to_weak(ext),
            event_observer = base{nullptr},
            right_layout = base{nullptr},
            bottom_layout = base{nullptr}
        ](auto const &context) mutable {
            if (auto ext = weak_ext.lock()) {
                auto node = context.value;
                if (auto renderer = node.renderer()) {
                    event_observer = renderer.event_manager().subject().make_observer(
                        ui::event_manager::method::modifier_changed,
                        [weak_ext, flags = std::unordered_set<ui::modifier_flags>{}](auto const &context) mutable {
                            ui::event const &event = context.value;
                            if (auto modifier_text_ext = weak_ext.lock()) {
                                auto ext_impl = modifier_text_ext.impl_ptr<sample::modifier_text_extension::impl>();

                                ext_impl->update_text(event, flags);
                            }
                        });

                    auto ext_impl = ext.impl_ptr<sample::modifier_text_extension::impl>();

                    right_layout = ui::fixed_layout{{.distance = -4.0f,
                                                     .source_guide = renderer.view_layout_guide_rect().right(),
                                                     .destination_guide = ext_impl->_layout_guide_point.x()}};
                    bottom_layout = ui::fixed_layout{{.distance = 4.0f,
                                                      .source_guide = renderer.view_layout_guide_rect().bottom(),
                                                      .destination_guide = ext_impl->_layout_guide_point.y()}};

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

        _strings_ext.set_text(joined(flag_texts, " + "));
    }

   private:
    base _renderer_observer = nullptr;
    ui::layout_guide_point _layout_guide_point;
};

sample::modifier_text_extension::modifier_text_extension(ui::font_atlas font_atlas)
    : base(std::make_shared<impl>(std::move(font_atlas))) {
    impl_ptr<impl>()->prepare(*this);
}

sample::modifier_text_extension::modifier_text_extension(std::nullptr_t) : base(nullptr) {
}

ui::strings_extension &sample::modifier_text_extension::strings_extension() {
    return impl_ptr<impl>()->_strings_ext;
}
