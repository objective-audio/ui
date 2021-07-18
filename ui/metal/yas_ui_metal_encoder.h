//
//  yas_ui_metal_encoder.h
//

#pragma once

#include <Metal/Metal.h>
#include <ui/yas_ui_metal_encoder_dependency.h>
#include <ui/yas_ui_render_info_dependency.h>

#include <deque>

namespace yas::ui {
struct metal_encoder final : render_encodable, render_effectable, render_stackable {
    struct encode_result_t {
        std::size_t const encoded_mesh_count;
    };

    virtual ~metal_encoder();

    [[nodiscard]] std::deque<std::shared_ptr<metal_encode_info>> const &all_encode_infos();

    encode_result_t encode(std::shared_ptr<ui::metal_encoder_system_interface> const &metal_system,
                           id<MTLCommandBuffer> const commandBuffer);

    [[nodiscard]] static std::shared_ptr<metal_encoder> make_shared();

   private:
    std::deque<std::shared_ptr<metal_encode_info>> _all_encode_infos;
    std::deque<std::shared_ptr<metal_encode_info>> _current_encode_infos;

    metal_encoder();

    metal_encoder(metal_encoder const &) = delete;
    metal_encoder(metal_encoder &&) = delete;
    metal_encoder &operator=(metal_encoder const &) = delete;
    metal_encoder &operator=(metal_encoder &&) = delete;

    void append_mesh(std::shared_ptr<mesh> const &mesh) override;
    void append_effect(std::shared_ptr<effect> const &effect) override;
    void push_encode_info(std::shared_ptr<metal_encode_info> const &) override;
    void pop_encode_info() override;
    std::shared_ptr<metal_encode_info> const &current_encode_info() override;

    uint32_t _mesh_count_in_all_encode_infos() const;
};
}  // namespace yas::ui
