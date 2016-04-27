//
//  yas_ui_collider_protocol.cpp
//

#include "yas_ui_collider_protocol.h"

using namespace yas;

ui::renderable_collider::renderable_collider(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

simd::float4x4 const &ui::renderable_collider::matrix() {
    return impl_ptr<impl>()->matrix();
}

void ui::renderable_collider::set_matrix(simd::float4x4 matrix) {
    impl_ptr<impl>()->set_matrix(std::move(matrix));
}
