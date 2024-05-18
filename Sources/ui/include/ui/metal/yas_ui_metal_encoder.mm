//
//  yas_ui_metal_encoder.mm
//

#include "yas_ui_metal_encoder.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_encoder_dependency.h"
#include "yas_ui_metal_texture.h"

#include <cpp-utils/objc_ptr.h>
#include <ui/effect/yas_ui_effect.h>
#include <ui/mesh/yas_ui_mesh.h>
#include <ui/renderer/yas_ui_renderer.h>
#include <ui/texture/yas_ui_texture.h>

using namespace yas;
using namespace yas::ui;

metal_encoder::metal_encoder() {
}

std::deque<std::shared_ptr<metal_encode_info>> const &metal_encoder::all_encode_infos() {
    return this->_all_encode_infos;
}

metal_encoder::encode_result_t metal_encoder::encode(std::shared_ptr<system_for_metal_encoder> const &metal_system,
                                                     id<MTLCommandBuffer> const commandBuffer) {
    metal_system->prepare_uniforms_buffer(_mesh_count_in_all_encode_infos());

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
                metal_system->mesh_encode(mesh, renderEncoder, metal_encode_info);

                ++encoded_count;
            }
        }

        for (auto &pair : metal_encode_info->textures()) {
            [renderEncoder useResource:pair.second->metal_texture()->texture()
                                 usage:MTLResourceUsageRead
                                stages:MTLRenderStageVertex];
        }

        [renderEncoder endEncoding];

        for (auto const &effect : metal_encode_info->effects()) {
            effect->encode(commandBuffer);
        }
    }

    return encode_result_t{.encoded_mesh_count = encoded_count};
}

void metal_encoder::append_mesh(std::shared_ptr<mesh> const &mesh) {
    if (auto &info = this->current_encode_info()) {
        info->append_mesh(mesh);
    }
}

void metal_encoder::append_effect(std::shared_ptr<effect> const &effect) {
    if (auto &info = this->current_encode_info()) {
        info->append_effect(std::move(effect));
    }
}

void metal_encoder::push_encode_info(std::shared_ptr<metal_encode_info> const &info) {
    this->_all_encode_infos.push_front(info);
    this->_current_encode_infos.push_front(info);
}

void metal_encoder::pop_encode_info() {
    this->_current_encode_infos.pop_front();
}

std::shared_ptr<metal_encode_info> const &metal_encoder::current_encode_info() {
    if (this->_current_encode_infos.size() > 0) {
        return this->_current_encode_infos.front();
    } else {
        static std::shared_ptr<metal_encode_info> _null_info{nullptr};
        return _null_info;
    }
}

uint32_t metal_encoder::_mesh_count_in_all_encode_infos() const {
    uint32_t count = 0;
    for (auto &metal_encode_info : this->_all_encode_infos) {
        count += metal_encode_info->meshes().size();
    }
    return count;
}

std::shared_ptr<metal_encoder> metal_encoder::make_shared() {
    return std::shared_ptr<metal_encoder>(new metal_encoder{});
}
