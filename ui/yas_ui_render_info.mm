//
//  yas_ui_render_info.mm
//

#include "yas_ui_encode_info.h"
#include "yas_ui_render_info.h"

using namespace yas;

void ui::render_info::push_encode_info(encode_info info) {
    all_encode_infos.push_front(info);
    _current_encode_infos.push_front(info);
}

void ui::render_info::pop_endoce_info() {
    _current_encode_infos.pop_front();
}

ui::encode_info const &ui::render_info::current_encode_info() {
    if (_current_encode_infos.size() > 0) {
        return _current_encode_infos.front();
    } else {
        static ui::encode_info const _null_info{nullptr};
        return _null_info;
    }
}
