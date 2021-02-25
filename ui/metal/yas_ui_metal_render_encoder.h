//
//  yas_ui_metal_render_encoder.h
//

#pragma once

#include <Metal/Metal.h>
#include <ui/yas_ui_ptr.h>
#include <ui/yas_ui_render_info_dependency.h>

#include <deque>

namespace yas::ui {
class metal_system;

struct metal_render_encoder final : render_encodable, render_effectable, render_stackable {
    struct encode_result_t {
        std::size_t const encoded_mesh_count;
    };

    virtual ~metal_render_encoder();

    [[nodiscard]] std::deque<ui::metal_encode_info_ptr> const &all_encode_infos();

    encode_result_t encode(std::shared_ptr<ui::metal_system> const &metal_system,
                           id<MTLCommandBuffer> const commandBuffer);

    [[nodiscard]] static metal_render_encoder_ptr make_shared();

   private:
    std::deque<ui::metal_encode_info_ptr> _all_encode_infos;
    std::deque<ui::metal_encode_info_ptr> _current_encode_infos;

    metal_render_encoder();

    metal_render_encoder(metal_render_encoder const &) = delete;
    metal_render_encoder(metal_render_encoder &&) = delete;
    metal_render_encoder &operator=(metal_render_encoder const &) = delete;
    metal_render_encoder &operator=(metal_render_encoder &&) = delete;

    void append_mesh(ui::mesh_ptr const &mesh) override;
    void append_effect(ui::effect_ptr const &effect) override;
    void push_encode_info(ui::metal_encode_info_ptr const &) override;
    void pop_encode_info() override;
    ui::metal_encode_info_ptr const &current_encode_info() override;

    uint32_t _mesh_count_in_all_encode_infos() const;
};
}  // namespace yas::ui
