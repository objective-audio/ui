//
//  yas_ui_layout.cpp
//

#include "yas_ui_layout.h"

using namespace yas;

struct ui::layout::impl : base::impl {
    args _args;

    impl(args &&args) : _args(std::move(args)) {
    }

    void prepare(ui::layout &layout) {
        auto weak_layout = to_weak(layout);

        auto handler = [weak_layout](auto const &context) {
            if (auto layout = weak_layout.lock()) {
                layout.impl_ptr<impl>()->_update_destination_values();
            }
        };

        _guide_observers.reserve(_args.source_guides.size());

        for (auto &guide : _args.source_guides) {
            _guide_observers.emplace_back(
                guide.subject().make_observer(ui::layout_guide::method::value_changed, handler));
        }

        _update_destination_values();
    }

   private:
    std::vector<ui::layout_guide::observer_t> _guide_observers;

    void _update_destination_values() {
        if (_args.handler) {
            _args.handler(_args.source_guides, _args.destination_guides);
        }
    }
};

ui::layout::layout(args args) : base(std::make_shared<impl>(std::move(args))) {
    impl_ptr<impl>()->prepare(*this);
}

ui::layout::layout(std::nullptr_t) : base(nullptr) {
}

ui::layout::~layout() = default;

std::vector<ui::layout_guide> const &ui::layout::source_guides() const {
    return impl_ptr<impl>()->_args.source_guides;
}

std::vector<ui::layout_guide> const &ui::layout::destination_guides() const {
    return impl_ptr<impl>()->_args.destination_guides;
}
