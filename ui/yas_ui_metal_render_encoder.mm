//
//  yas_ui_metal_render_encoder.mm
//

#include "yas_ui_metal_render_encoder.h"
#include <cpp_utils/yas_objc_ptr.h>
#include "yas_ui_effect.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_system.h"
#include "yas_ui_metal_texture.h"
#include "yas_ui_renderer.h"
#include "yas_ui_texture.h"

using namespace yas;

struct ui::metal_render_encoder::impl : base::impl,
                                        render_encodable::impl,
                                        render_effectable::impl,
                                        render_stackable::impl {
    std::deque<ui::metal_encode_info> &all_encode_infos() {
        return this->_all_encode_infos;
    }

    void push_encode_info(ui::metal_encode_info &&info) override {
        this->_all_encode_infos.push_front(info);
        this->_current_encode_infos.push_front(info);
    }

    void pop_encode_info() override {
        this->_current_encode_infos.pop_front();
    }

    ui::metal_encode_info &current_encode_info() override {
        if (this->_current_encode_infos.size() > 0) {
            return this->_current_encode_infos.front();
        } else {
            static ui::metal_encode_info _null_info{nullptr};
            return _null_info;
        }
    }

    void append_mesh(ui::mesh &&mesh) override {
        if (auto &info = this->current_encode_info()) {
            info.append_mesh(std::move(mesh));
        }
    }

    void append_effect(ui::effect &&effect) override {
        if (auto &info = this->current_encode_info()) {
            info.append_effect(std::move(effect));
        }
    }

    encode_result_t encode(ui::metal_system &metal_system, id<MTLCommandBuffer> const commandBuffer) {
        metal_system.renderable().prepare_uniforms_buffer(_mesh_count_in_all_encode_infos());

        std::size_t encoded_count = 0;

        for (auto &metal_encode_info : this->_all_encode_infos) {
            auto renderPassDesc = metal_encode_info.renderPassDescriptor();
            auto render_encoder = objc_ptr<id<MTLRenderCommandEncoder>>([&commandBuffer, &renderPassDesc]() {
                return [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
            });
            auto renderEncoder = render_encoder.object();

            for (auto &mesh : metal_encode_info.meshes()) {
                auto &mesh_renderable = mesh.renderable();
                if (mesh_renderable.pre_render()) {
                    metal_system.renderable().mesh_encode(mesh, renderEncoder, metal_encode_info);

                    ++encoded_count;
                }
            }

            for (auto &pair : metal_encode_info.textures()) {
                [renderEncoder useResource:pair.second.metal_texture().texture() usage:MTLResourceUsageSample];
            }

            [renderEncoder endEncoding];

            for (auto &effect : metal_encode_info.effects()) {
                effect.encodable().encode(commandBuffer);
            }
        }

        return encode_result_t{.encoded_mesh_count = encoded_count};
    }

   private:
    std::deque<ui::metal_encode_info> _all_encode_infos;
    std::deque<ui::metal_encode_info> _current_encode_infos;

    uint32_t _mesh_count_in_all_encode_infos() const {
        uint32_t count = 0;
        for (auto &metal_encode_info : this->_all_encode_infos) {
            count += metal_encode_info.meshes().size();
        }
        return count;
    }
};

ui::metal_render_encoder::metal_render_encoder() : base(std::make_shared<impl>()) {
}

ui::metal_render_encoder::metal_render_encoder(std::nullptr_t) : base(nullptr) {
}

ui::metal_render_encoder::~metal_render_encoder() = default;

std::deque<ui::metal_encode_info> const &ui::metal_render_encoder::all_encode_infos() {
    return impl_ptr<impl>()->all_encode_infos();
}

ui::metal_render_encoder::encode_result_t ui::metal_render_encoder::encode(ui::metal_system &metal_system,
                                                                           id<MTLCommandBuffer> const commandBuffer) {
    return impl_ptr<impl>()->encode(metal_system, commandBuffer);
}

ui::render_encodable &ui::metal_render_encoder::encodable() {
    if (!this->_encodable) {
        this->_encodable = ui::render_encodable{impl_ptr<ui::render_encodable::impl>()};
    }
    return this->_encodable;
}

ui::render_effectable &ui::metal_render_encoder::effectable() {
    if (!this->_effectable) {
        this->_effectable = ui::render_effectable{impl_ptr<ui::render_effectable::impl>()};
    }
    return this->_effectable;
}

ui::render_stackable &ui::metal_render_encoder::stackable() {
    if (!this->_stackable) {
        this->_stackable = ui::render_stackable{impl_ptr<ui::render_stackable::impl>()};
    }
    return this->_stackable;
}
