//
//  yas_ui_renderer.mm
//

#include <chrono>
#include <unordered_set>
#include "yas_objc_ptr.h"
#include "yas_ui_action.h"
#include "yas_ui_encode_info.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"
#include "yas_ui_renderer_impl.h"
#include "yas_ui_renderer_protocol.h"

using namespace yas;
using namespace simd;

#pragma mark - renderer

ui::renderer::renderer(std::shared_ptr<impl> &&impl) : super_class(std::move(impl)) {
}

ui::renderer::renderer(std::nullptr_t) : super_class(nullptr) {
}

simd::float4x4 const &ui::renderer::projection_matrix() const {
    return impl_ptr<impl>()->projection_matrix();
}

id<MTLBuffer> ui::renderer::current_constant_buffer() const {
    return impl_ptr<impl>()->currentConstantBuffer();
}

uint32_t ui::renderer::constant_buffer_offset() const {
    return impl_ptr<impl>()->constant_buffer_offset();
}

void ui::renderer::set_constant_buffer_offset(uint32_t const offset) {
    impl_ptr<impl>()->set_constant_buffer_offset(offset);
}

ui::view_renderable ui::renderer::view_renderable() {
    return ui::view_renderable{impl_ptr<view_renderable::impl>()};
}

subject<ui::renderer> &ui::renderer::subject() {
    return impl_ptr<impl>()->subject();
}

#pragma mark - node_renderer

class ui::node_renderer::impl : public renderer::impl {
    using super_class = renderer::impl;

   public:
    impl(id<MTLDevice> const device) : super_class(device) {
    }

    void view_configure(YASUIMetalView *const view) override {
        super_class::view_configure(view);
    }

    void insert_action(ui::action action) {
        _action.insert_action(action);
    }

    void erase_action(ui::action const &action) {
        _action.erase_action(action);
    }

    void erase_action(ui::node const &target) {
        for (auto const &action : _action.actions()) {
            if (action.target() == target) {
                _action.erase_action(action);
            }
        }
    }

    void render(id<MTLCommandBuffer> const commandBuffer, MTLRenderPassDescriptor *const renderPassDesc) override {
        _root_node.metal().setup(device());

        _action.updatable().update(std::chrono::system_clock::now());

        //        [gesuture_recognizer.object() clearTouchesIfNeeded];

        ui::render_info render_info;

        render_info.push_encode_info(
            {renderPassDesc, multiSamplePipelineState(), multiSamplePipelineStateWithoutTexture()});

        auto const &matrix = projection_matrix();
        render_info.render_matrix = matrix;
        render_info.touch_matrix = matrix;

        _root_node.update_render_info(render_info);

        //        [gesuture_recognizer.object() finalizeTouches];

        auto renderer = cast<ui::renderer>();

        for (auto &encode_info : render_info.all_encode_infos()) {
            auto renderPassDesc = encode_info.renderPassDescriptor();
            auto render_encoder = make_objc_ptr<id<MTLRenderCommandEncoder>>([&commandBuffer, &renderPassDesc]() {
                return [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
            });

            auto renderEncoder = render_encoder.object();

            for (auto &mesh : encode_info.meshes()) {
                mesh.renderable().render(renderer, renderEncoder, encode_info);
            }

            [renderEncoder endEncoding];
        }
    }

    ui::node _root_node;
    ui::parallel_action _action;

    objc_ptr<YASUIGestureRecognizer *> gesuture_recognizer;
};

ui::node_renderer::node_renderer(id<MTLDevice> const device) : super_class(std::make_shared<impl>(device)) {
    impl_ptr<impl>()->_root_node.renderable().set_renderer(*this);
}

ui::node_renderer::node_renderer(std::nullptr_t) : super_class(nullptr) {
}

ui::node const &ui::node_renderer::root_node() const {
    return impl_ptr<impl>()->_root_node;
}

std::vector<ui::action> ui::node_renderer::actions() const {
    return impl_ptr<impl>()->_action.actions();
}

void ui::node_renderer::insert_action(ui::action action) {
    impl_ptr<impl>()->insert_action(std::move(action));
}

void ui::node_renderer::erase_action(ui::action const &action) {
    impl_ptr<impl>()->erase_action(action);
}

void ui::node_renderer::erase_action(ui::node const &target) {
    impl_ptr<impl>()->erase_action(target);
}
