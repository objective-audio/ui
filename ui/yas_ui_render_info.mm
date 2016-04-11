//
//  yas_ui_render_info.mm
//

#include "yas_ui_encode_info.h"
#include "yas_ui_render_info.h"

using namespace yas;

struct ui::render_info::impl : base::impl {
    std::deque<encode_info> all_encode_infos;
    std::deque<encode_info> current_encode_infos;
};

ui::render_info::render_info() : super_class(std::make_shared<impl>()) {
}

ui::render_info::render_info(std::nullptr_t) : super_class(nullptr) {
}

void ui::render_info::push_encode_info(encode_info info) {
    impl_ptr<impl>()->all_encode_infos.push_front(info);
    impl_ptr<impl>()->current_encode_infos.push_front(info);
}

void ui::render_info::pop_endoce_info() {
    impl_ptr<impl>()->current_encode_infos.pop_front();
}

ui::encode_info const &ui::render_info::current_encode_info() {
    if (impl_ptr<impl>()->current_encode_infos.size() > 0) {
        return impl_ptr<impl>()->current_encode_infos.front();
    } else {
        static ui::encode_info const _null_info{nullptr};
        return _null_info;
    }
}

std::deque<ui::encode_info> const &ui::render_info::all_encode_infos() {
    return impl_ptr<impl>()->all_encode_infos;
}
