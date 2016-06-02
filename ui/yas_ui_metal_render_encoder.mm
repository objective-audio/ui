//
//  yas_ui_metal_render_encoder.mm
//

#include "yas_objc_ptr.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_render_encoder.h"

using namespace yas;

struct ui::metal_render_encoder::impl : base::impl, render_encodable::impl {
    std::deque<ui::metal_encode_info> &all_encode_infos() {
        return _all_encode_infos;
    }

    void push_encode_info(ui::metal_encode_info info) {
        _all_encode_infos.push_front(info);
        _current_encode_infos.push_front(info);
    }

    void pop_encode_info() {
        _current_encode_infos.pop_front();
    }

    ui::metal_encode_info &current_encode_info() {
        if (_current_encode_infos.size() > 0) {
            return _current_encode_infos.front();
        } else {
            static ui::metal_encode_info _null_info{nullptr};
            return _null_info;
        }
    }

    void push_back_mesh(ui::mesh &&mesh) override {
        if (auto &info = current_encode_info()) {
            info.push_back_mesh(std::move(mesh));
        }
    }

    void render(ui::renderer_base &renderer, id<MTLCommandBuffer> const commandBuffer,
                MTLRenderPassDescriptor *const renderPassDesc) {
        for (auto &metal_encode_info : _all_encode_infos) {
            auto renderPassDesc = metal_encode_info.renderPassDescriptor();
            auto render_encoder = make_objc_ptr<id<MTLRenderCommandEncoder>>([&commandBuffer, &renderPassDesc]() {
                return [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
            });
            auto renderEncoder = render_encoder.object();

            for (auto &mesh : metal_encode_info.meshes()) {
                mesh.renderable().metal_render(renderer, renderEncoder, metal_encode_info);
            }

            [renderEncoder endEncoding];
        }
    }

   private:
    std::deque<ui::metal_encode_info> _all_encode_infos;
    std::deque<ui::metal_encode_info> _current_encode_infos;
};

ui::metal_render_encoder::metal_render_encoder() : base(std::make_shared<impl>()) {
}

ui::metal_render_encoder::metal_render_encoder(std::nullptr_t) : base(nullptr) {
}

std::deque<ui::metal_encode_info> const &ui::metal_render_encoder::all_encode_infos() {
    return impl_ptr<impl>()->all_encode_infos();
}

void ui::metal_render_encoder::push_encode_info(ui::metal_encode_info info) {
    impl_ptr<impl>()->push_encode_info(std::move(info));
}

void ui::metal_render_encoder::pop_encode_info() {
    impl_ptr<impl>()->pop_encode_info();
}

ui::metal_encode_info const &ui::metal_render_encoder::current_encode_info() {
    return impl_ptr<impl>()->current_encode_info();
}

void ui::metal_render_encoder::render(ui::renderer_base &renderer, id<MTLCommandBuffer> const commandBuffer,
                                      MTLRenderPassDescriptor *const renderPassDesc) {
    impl_ptr<impl>()->render(renderer, commandBuffer, renderPassDesc);
}

ui::render_encodable &ui::metal_render_encoder::encodable() {
    if (!_encodable) {
        _encodable = ui::render_encodable{impl_ptr<ui::render_encodable::impl>()};
    }
    return _encodable;
}
