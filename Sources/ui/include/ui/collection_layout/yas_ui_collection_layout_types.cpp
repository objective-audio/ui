//
//  yas_ui_collection_layout_types.cpp
//

#include "yas_ui_collection_layout_types.h"

#include <cpp-utils/fast_each.h>

using namespace yas;
using namespace yas::ui;

bool collection_layout_line::operator==(collection_layout_line const &rhs) const {
    if (this->new_line_min_offset != rhs.new_line_min_offset) {
        return false;
    }

    auto const cell_count = this->cell_sizes.size();

    if (cell_count != rhs.cell_sizes.size()) {
        return false;
    }

    auto each = make_fast_each(cell_count);
    while (yas_each_next(each)) {
        auto const &idx = yas_each_index(each);
        if (this->cell_sizes.at(idx) != rhs.cell_sizes.at(idx)) {
            return false;
        }
    }

    return true;
}

bool collection_layout_line::operator!=(collection_layout_line const &rhs) const {
    return !(*this == rhs);
}
