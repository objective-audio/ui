//
//  yas_ui_metal_render_encoder.mm
//

#include "yas_ui_metal_render_encoder.h"
#include <cpp_utils/yas_objc_ptr.h>
#include "yas_ui_effect.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

ui::metal_render_encoder::metal_render_encoder() {
}

ui::metal_render_encoder::~metal_render_encoder() = default;

std::deque<ui::metal_encode_info_ptr> const &ui::metal_render_encoder::all_encode_infos() {
    return this->_all_encode_infos;
}

ui::metal_render_encoder::encode_result_t ui::metal_render_encoder::encode(ui::metal_system_ptr const &metal_system,
                                                                           id<MTLCommandBuffer> const commandBuffer) {
    ui::renderable_metal_system::cast(metal_system)->prepare_uniforms_buffer(_mesh_count_in_all_encode_infos());

    std::size_t encoded_count = 0;

    for (auto &metal_encode_info : this->_all_encode_infos) {
        auto renderPassDesc = metal_encode_info->renderPassDescriptor();
        auto render_encoder = objc_ptr<id<MTLRenderCommandEncoder>>([&commandBuffer, &renderPassDesc]() {
            return [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        });
        auto renderEncoder = render_encoder.object();

        for (auto &mesh : metal_encode_info->meshes()) {
            auto renderable = renderable_mesh::cast(mesh);
            if (renderable->pre_render()) {
                ui::renderable_metal_system::cast(metal_system)->mesh_encode(mesh, renderEncoder, metal_encode_info);

                ++encoded_count;
            }
        }

        for (auto &pair : metal_encode_info->textures()) {
            [renderEncoder useResource:pair.second->metal_texture()->texture() usage:MTLResourceUsageSample];
        }

        [renderEncoder endEncoding];

        for (auto const &effect : metal_encode_info->effects()) {
            encodable_effect::cast(effect)->encode(commandBuffer);
        }
    }

    return encode_result_t{.encoded_mesh_count = encoded_count};
}

void ui::metal_render_encoder::append_mesh(ui::mesh_ptr const &mesh) {
    if (auto &info = this->current_encode_info()) {
        info->append_mesh(mesh);
    }
}

void ui::metal_render_encoder::append_effect(ui::effect_ptr const &effect) {
    if (auto &info = this->current_encode_info()) {
        info->append_effect(std::move(effect));
    }
}

void ui::metal_render_encoder::push_encode_info(ui::metal_encode_info_ptr const &info) {
    this->_all_encode_infos.push_front(info);
    this->_current_encode_infos.push_front(info);
}

void ui::metal_render_encoder::pop_encode_info() {
    this->_current_encode_infos.pop_front();
}

ui::metal_encode_info_ptr const &ui::metal_render_encoder::current_encode_info() {
    if (this->_current_encode_infos.size() > 0) {
        return this->_current_encode_infos.front();
    } else {
        static ui::metal_encode_info_ptr _null_info{nullptr};
        return _null_info;
    }
}

uint32_t ui::metal_render_encoder::_mesh_count_in_all_encode_infos() const {
    uint32_t count = 0;
    for (auto &metal_encode_info : this->_all_encode_infos) {
        count += metal_encode_info->meshes().size();
    }
    return count;
}

ui::metal_render_encoder_ptr ui::metal_render_encoder::make_shared() {
    return std::shared_ptr<metal_render_encoder>(new metal_render_encoder{});
}
