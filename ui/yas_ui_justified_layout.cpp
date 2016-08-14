//
//  yas_ui_justified_layout.cpp
//

#include "yas_each_index.h"
#include "yas_ui_justified_layout.h"

using namespace yas;

struct ui::justified_layout::impl : base::impl {
    args _args;

    impl(args &&args) : _args(std::move(args)) {
        if (!_args.first_source_guide) {
            throw "first_source_guide is null.";
        }

        if (!_args.second_source_guide) {
            throw "second_source_guide is null.";
        }

        if (_args.destination_guides.size() == 0) {
            throw "destination_guides is empty.";
        }
    }

    void prepare(ui::justified_layout &layout) {
        auto weak_layout = to_weak(layout);

        _first_src_observer = _args.first_source_guide.subject().make_observer(
            ui::layout_guide::method::value_changed, [weak_layout](auto const &context) {
                if (auto layout = weak_layout.lock()) {
                    layout.impl_ptr<impl>()->update_destination_values();
                }
            });

        _second_src_observer = _args.second_source_guide.subject().make_observer(
            ui::layout_guide::method::value_changed, [weak_layout](auto const &context) {
                if (auto layout = weak_layout.lock()) {
                    layout.impl_ptr<impl>()->update_destination_values();
                }
            });

        update_destination_values();
    }

    void update_destination_values() {
        auto const count = _args.destination_guides.size();
        auto const rate = 1.0f / static_cast<float>(count + 1);
        auto const first_value = _args.first_source_guide.value();
        auto const distance = _args.second_source_guide.value() - first_value;
        auto idx = 1;

        for (auto &dst_guide : _args.destination_guides) {
            dst_guide.set_value(first_value + distance * rate * idx);
            ++idx;
        }
    }

   private:
    ui::layout_guide::subject_t::observer_t _first_src_observer;
    ui::layout_guide::subject_t::observer_t _second_src_observer;
};

ui::justified_layout::justified_layout(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::justified_layout::justified_layout(std::nullptr_t) : base(nullptr) {
}

ui::justified_layout::~justified_layout() = default;

ui::layout_guide const &ui::justified_layout::first_source_guide() const {
    return impl_ptr<impl>()->_args.first_source_guide;
}

ui::layout_guide const &ui::justified_layout::second_source_guide() const {
    return impl_ptr<impl>()->_args.second_source_guide;
}
std::vector<ui::layout_guide> const &ui::justified_layout::destination_guides() const {
    return impl_ptr<impl>()->_args.destination_guides;
}