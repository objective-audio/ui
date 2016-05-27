//
//  yas_ui_batch_protocol.mm
//

#include "yas_ui_batch_protocol.h"

using namespace yas;

ui::renderable_batch::renderable_batch(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}
