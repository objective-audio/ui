//
//  yas_ui_metal_encode_info.mm
//

#include <vector>
#include "yas_objc_ptr.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"

using namespace yas;

struct ui::metal_encode_info::impl : base::impl {
    impl(ui::metal_encode_info::args &&args) {
        this->_render_pass_descriptor = args.renderPassDescriptor;
        this->_pipe_line_state_with_texture = args.pipelineStateWithTexture;
        this->_pipe_line_state_without_texture = args.pipelineStateWithoutTexture;
    }

    objc_ptr<MTLRenderPassDescriptor *> _render_pass_descriptor;
    objc_ptr<id<MTLRenderPipelineState>> _pipe_line_state_with_texture;
    objc_ptr<id<MTLRenderPipelineState>> _pipe_line_state_without_texture;
    std::vector<ui::mesh> _meshes;
};

ui::metal_encode_info::metal_encode_info(args args) : base(std::make_shared<impl>(std::move(args))) {
}

ui::metal_encode_info::metal_encode_info(std::nullptr_t) : base(nullptr) {
}

ui::metal_encode_info::~metal_encode_info() = default;

void ui::metal_encode_info::push_back_mesh(ui::mesh mesh) {
    impl_ptr<impl>()->_meshes.emplace_back(std::move(mesh));
}

MTLRenderPassDescriptor *ui::metal_encode_info::renderPassDescriptor() const {
    return impl_ptr<impl>()->_render_pass_descriptor.object();
}

id<MTLRenderPipelineState> ui::metal_encode_info::pipelineStateWithTexture() const {
    return impl_ptr<impl>()->_pipe_line_state_with_texture.object();
}

id<MTLRenderPipelineState> ui::metal_encode_info::pipelineStateWithoutTexture() const {
    return impl_ptr<impl>()->_pipe_line_state_without_texture.object();
}

std::vector<ui::mesh> &ui::metal_encode_info::meshes() const {
    return impl_ptr<impl>()->_meshes;
}
