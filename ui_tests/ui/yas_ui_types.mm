//
//  yas_ui_types.mm
//

#include "yas_ui_types.h"

using namespace yas;

MTLSize yas::to_mtl_size(ui::uint_size const size) {
    return MTLSize{size.width, size.height, 1};
}