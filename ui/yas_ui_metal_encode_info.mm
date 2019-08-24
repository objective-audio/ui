//
//  yas_ui_metal_encode_info.mm
//

#include "yas_ui_metal_encode_info.h"
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_stl_utils.h>
#include <unordered_map>
#include <vector>
#include "yas_ui_mesh.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::metal_encode_info::impl {
    impl(ui::metal_encode_info::args &&args) {
        this->_render_pass_descriptor = args.renderPassDescriptor;
        this->_pipe_line_state_with_texture = args.pipelineStateWithTexture;
        this->_pipe_line_state_without_texture = args.pipelineStateWithoutTexture;
    }

    objc_ptr<MTLRenderPassDescriptor *> _render_pass_descriptor;
    objc_ptr<id<MTLRenderPipelineState>> _pipe_line_state_with_texture;
    objc_ptr<id<MTLRenderPipelineState>> _pipe_line_state_without_texture;
    std::vector<ui::mesh_ptr> _meshes;
    std::vector<ui::effect_ptr> _effects;
    std::unordered_map<uintptr_t, ui::texture_ptr> _textures;
};

ui::metal_encode_info::metal_encode_info(args &&args) : _impl(std::make_shared<impl>(std::move(args))) {
}

ui::metal_encode_info::~metal_encode_info() = default;

void ui::metal_encode_info::append_mesh(ui::mesh_ptr const &mesh) {
    if (auto const &texture = mesh->texture()) {
        uintptr_t const identifier = texture->identifier();
        auto &textures = this->_impl->_textures;
        if (textures.count(identifier) == 0) {
            textures.insert(std::make_pair(identifier, texture));
        }
    }
    this->_impl->_meshes.emplace_back(mesh);
}

void ui::metal_encode_info::append_effect(ui::effect_ptr const &effect) {
    this->_impl->_effects.emplace_back(effect);
}

MTLRenderPassDescriptor *ui::metal_encode_info::renderPassDescriptor() const {
    return this->_impl->_render_pass_descriptor.object();
}

id<MTLRenderPipelineState> ui::metal_encode_info::pipelineStateWithTexture() const {
    return this->_impl->_pipe_line_state_with_texture.object();
}

id<MTLRenderPipelineState> ui::metal_encode_info::pipelineStateWithoutTexture() const {
    return this->_impl->_pipe_line_state_without_texture.object();
}

std::vector<ui::mesh_ptr> const &ui::metal_encode_info::meshes() const {
    return this->_impl->_meshes;
}

std::vector<ui::effect_ptr> const &ui::metal_encode_info::effects() const {
    return this->_impl->_effects;
}

std::unordered_map<uintptr_t, ui::texture_ptr> &ui::metal_encode_info::textures() const {
    return this->_impl->_textures;
}

ui::metal_encode_info_ptr ui::metal_encode_info::make_shared(args args) {
    return std::shared_ptr<metal_encode_info>(new metal_encode_info{std::move(args)});
}
