//
//  yas_ui_metal_render_encoder.h
//

#pragma once

#include <Metal/Metal.h>
#include <deque>
#include "yas_ui_ptr.h"
#include "yas_ui_render_encoder_protocol.h"

namespace yas::ui {
class metal_system;

struct metal_render_encoder final : render_encodable,
                                    render_effectable,
                                    render_stackable,
                                    std::enable_shared_from_this<metal_render_encoder> {
    class impl;

    struct encode_result_t {
        std::size_t const encoded_mesh_count;
    };

    virtual ~metal_render_encoder();

    std::deque<ui::metal_encode_info_ptr> const &all_encode_infos();

    encode_result_t encode(std::shared_ptr<ui::metal_system> const &metal_system,
                           id<MTLCommandBuffer> const commandBuffer);

    ui::render_encodable_ptr encodable();
    ui::render_effectable_ptr effectable();
    ui::render_stackable_ptr stackable();

    [[nodiscard]] static metal_render_encoder_ptr make_shared();

   private:
    std::shared_ptr<impl> _impl;

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
};
}  // namespace yas::ui
