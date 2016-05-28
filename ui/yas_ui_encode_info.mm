//
//  yas_ui_metal_encode_info.mm
//

#include <vector>
#include "yas_objc_ptr.h"
#include "yas_ui_encode_info.h"
#include "yas_ui_mesh.h"

using namespace yas;

struct ui::metal_encode_info::impl : base::impl {
    impl(MTLRenderPassDescriptor *const renderPassDesc, id<MTLRenderPipelineState> const pipelineState,
         id<MTLRenderPipelineState> const pipelineStateWithoutTexture) {
        render_pass_descriptor = renderPassDesc;
        pipe_line_state = pipelineState;
        pipe_line_state_without_texture = pipelineStateWithoutTexture;
    }

    objc_ptr<MTLRenderPassDescriptor *> render_pass_descriptor;
    objc_ptr<id<MTLRenderPipelineState>> pipe_line_state;
    objc_ptr<id<MTLRenderPipelineState>> pipe_line_state_without_texture;
    std::vector<ui::mesh> meshes;
};

ui::metal_encode_info::metal_encode_info(MTLRenderPassDescriptor *const renderPassDesc,
                                         id<MTLRenderPipelineState> const pipelineState,
                                         id<MTLRenderPipelineState> const pipelineStateWithoutTexture)
    : base(std::make_shared<impl>(renderPassDesc, pipelineState, pipelineStateWithoutTexture)) {
}

ui::metal_encode_info::metal_encode_info(std::nullptr_t) : base(nullptr) {
}

void ui::metal_encode_info::push_back_mesh(ui::mesh mesh) {
    impl_ptr<impl>()->meshes.emplace_back(std::move(mesh));
}

MTLRenderPassDescriptor *ui::metal_encode_info::renderPassDescriptor() const {
    return impl_ptr<impl>()->render_pass_descriptor.object();
}

id<MTLRenderPipelineState> ui::metal_encode_info::pipelineState() const {
    return impl_ptr<impl>()->pipe_line_state.object();
}

id<MTLRenderPipelineState> ui::metal_encode_info::pipelineStateWithoutTexture() const {
    return impl_ptr<impl>()->pipe_line_state_without_texture.object();
}

std::vector<ui::mesh> &ui::metal_encode_info::meshes() const {
    return impl_ptr<impl>()->meshes;
}
