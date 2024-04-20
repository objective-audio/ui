//
//  yas_ui_metal_encode_info.h
//

#pragma once

#include <cpp-utils/yas_objc_ptr.h>
#include <ui/effect/yas_ui_effect.h>
#include <ui/mesh/yas_ui_mesh.h>
#include <ui/metal/yas_ui_metal_encode_info_types.h>

#include <unordered_map>
#include <vector>

namespace yas::ui {
struct metal_encode_info final {
    using args = metal_encode_info_args;

    void append_mesh(std::shared_ptr<mesh> const &);
    void append_effect(std::shared_ptr<effect_for_metal_encoder> const &);

    [[nodiscard]] MTLRenderPassDescriptor *renderPassDescriptor() const;
    [[nodiscard]] id<MTLRenderPipelineState> pipelineStateWithTexture() const;
    [[nodiscard]] id<MTLRenderPipelineState> pipelineStateWithoutTexture() const;

    [[nodiscard]] std::vector<std::shared_ptr<mesh>> const &meshes() const;
    [[nodiscard]] std::vector<std::shared_ptr<effect_for_metal_encoder>> const &effects() const;
    [[nodiscard]] std::unordered_map<uintptr_t, std::shared_ptr<texture>> const &textures() const;

    [[nodiscard]] static std::shared_ptr<metal_encode_info> make_shared(args);

   private:
    objc_ptr<MTLRenderPassDescriptor *> _render_pass_descriptor;
    objc_ptr<id<MTLRenderPipelineState>> _pipe_line_state_with_texture;
    objc_ptr<id<MTLRenderPipelineState>> _pipe_line_state_without_texture;
    std::vector<std::shared_ptr<mesh>> _meshes;
    std::vector<std::shared_ptr<effect_for_metal_encoder>> _effects;
    std::unordered_map<uintptr_t, std::shared_ptr<texture>> _textures;

    metal_encode_info(args &&);

    metal_encode_info(metal_encode_info const &) = delete;
    metal_encode_info(metal_encode_info &&) = delete;
    metal_encode_info &operator=(metal_encode_info const &) = delete;
    metal_encode_info &operator=(metal_encode_info &&) = delete;
};
}  // namespace yas::ui
