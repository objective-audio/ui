//
//  yas_ui_metal_encode_info.mm
//

#include "yas_ui_metal_encode_info.h"
#include <cpp_utils/yas_objc_ptr.h>
#include <cpp_utils/yas_stl_utils.h>
#include <ui/yas_ui_mesh.h>
#include <ui/yas_ui_texture.h>
#include <unordered_map>
#include <vector>

using namespace yas;
using namespace yas::ui;

metal_encode_info::metal_encode_info(args &&args) {
    this->_render_pass_descriptor = args.renderPassDescriptor;
    this->_pipe_line_state_with_texture = args.pipelineStateWithTexture;
    this->_pipe_line_state_without_texture = args.pipelineStateWithoutTexture;
}

metal_encode_info::~metal_encode_info() = default;

void metal_encode_info::append_mesh(std::shared_ptr<mesh> const &mesh) {
    if (auto const &texture = mesh->texture()) {
        uintptr_t const identifier = texture->identifier();
        auto &textures = this->_textures;
        if (textures.count(identifier) == 0) {
            textures.insert(std::make_pair(identifier, texture));
        }
    }
    this->_meshes.emplace_back(mesh);
}

void metal_encode_info::append_effect(std::shared_ptr<metal_encoder_effect_interface> const &effect) {
    this->_effects.emplace_back(effect);
}

MTLRenderPassDescriptor *metal_encode_info::renderPassDescriptor() const {
    return this->_render_pass_descriptor.object();
}

id<MTLRenderPipelineState> metal_encode_info::pipelineStateWithTexture() const {
    return this->_pipe_line_state_with_texture.object();
}

id<MTLRenderPipelineState> metal_encode_info::pipelineStateWithoutTexture() const {
    return this->_pipe_line_state_without_texture.object();
}

std::vector<std::shared_ptr<mesh>> const &metal_encode_info::meshes() const {
    return this->_meshes;
}

std::vector<std::shared_ptr<metal_encoder_effect_interface>> const &metal_encode_info::effects() const {
    return this->_effects;
}

std::unordered_map<uintptr_t, std::shared_ptr<texture>> const &metal_encode_info::textures() const {
    return this->_textures;
}

std::shared_ptr<metal_encode_info> metal_encode_info::make_shared(args args) {
    return std::shared_ptr<metal_encode_info>(new metal_encode_info{std::move(args)});
}
