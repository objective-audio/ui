//
//  yas_ui_renderer.mm
//

#include <chrono>
#include <unordered_map>
#include "yas_objc_ptr.h"
#include "yas_observing.h"
#include "yas_ui_action.h"
#include "yas_ui_batch.h"
#include "yas_ui_batch_protocol.h"
#include "yas_ui_collision_detector.h"
#include "yas_ui_encode_info.h"
#include "yas_ui_mesh.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"
#include "yas_ui_renderer_impl.h"
#include "yas_ui_renderer_protocol.h"
#include "yas_ui_types.h"

using namespace yas;
using namespace simd;

#pragma mark - renderer_base

ui::renderer_base::renderer_base(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
}

ui::renderer_base::renderer_base(std::nullptr_t) : base(nullptr) {
}

id<MTLDevice> ui::renderer_base::device() const {
    return impl_ptr<impl>()->device();
}

ui::uint_size const &ui::renderer_base::view_size() const {
    return impl_ptr<impl>()->view_size();
}

ui::uint_size const &ui::renderer_base::drawable_size() const {
    return impl_ptr<impl>()->drawable_size();
}

double ui::renderer_base::scale_factor() const {
    return impl_ptr<impl>()->scale_factor();
}

simd::float4x4 const &ui::renderer_base::projection_matrix() const {
    return impl_ptr<impl>()->projection_matrix();
}

id<MTLBuffer> ui::renderer_base::currentConstantBuffer() const {
    return impl_ptr<impl>()->currentConstantBuffer();
}

uint32_t ui::renderer_base::constant_buffer_offset() const {
    return impl_ptr<impl>()->constant_buffer_offset();
}

void ui::renderer_base::set_constant_buffer_offset(uint32_t const offset) {
    impl_ptr<impl>()->set_constant_buffer_offset(offset);
}

ui::view_renderable ui::renderer_base::view_renderable() {
    return ui::view_renderable{impl_ptr<view_renderable::impl>()};
}

subject<ui::renderer_base, ui::renderer_method> &ui::renderer_base::subject() {
    return impl_ptr<impl>()->subject();
}

ui::event_manager &ui::renderer_base::event_manager() {
    return impl_ptr<impl>()->event_manager();
}

#pragma mark - renderer

class ui::renderer::impl : public renderer_base::impl {
   public:
    impl(id<MTLDevice> const device) : renderer_base::impl(device) {
    }

    void view_configure(YASUIMetalView *const view) override {
        renderer_base::impl::view_configure(view);
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

    std::unordered_map<uintptr_t, ui::batch> &batches() {
        return _batches;
    }

    void insert_batch(ui::batch &&batch) {
        _batches.emplace(std::make_pair(batch.identifier(), std::move(batch)));
    }

    void erase_batch(ui::batch const &batch) {
        auto const identifier = batch.identifier();
        if (_batches.count(identifier)) {
            auto &removing_batch = _batches.at(identifier);
            removing_batch.render_node().remove_from_super_node();
            _batches.erase(identifier);
        }
    }

    bool pre_render() override {
        _root_node.metal().setup(device());

        _action.updatable().update(std::chrono::system_clock::now());

        return _root_node.renderable().needs_update_for_render();
    }

    void render(id<MTLCommandBuffer> const commandBuffer, MTLRenderPassDescriptor *const renderPassDesc) override {
        _detector.updatable().clear_colliders_if_needed();

        ui::render_info render_info;
        render_info.collision_detector = _detector;

        render_info.push_encode_info(
            {renderPassDesc, multiSamplePipelineState(), multiSamplePipelineStateWithoutTexture()});

        auto const &matrix = projection_matrix();
        render_info.render_matrix = matrix;

        _root_node.update_render_info(render_info);

        _detector.updatable().finalize();

        auto renderer = cast<ui::renderer_base>();

        for (auto &encode_info : render_info.all_encode_infos) {
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
    std::unordered_map<uintptr_t, ui::batch> _batches;
    ui::collision_detector _detector;
};

ui::renderer::renderer(id<MTLDevice> const device) : renderer_base(std::make_shared<impl>(device)) {
    impl_ptr<impl>()->_root_node.renderable().set_renderer(*this);
}

ui::renderer::renderer(std::nullptr_t) : renderer_base(nullptr) {
}

ui::node const &ui::renderer::root_node() const {
    return impl_ptr<impl>()->_root_node;
}

ui::node &ui::renderer::root_node() {
    return impl_ptr<impl>()->_root_node;
}

std::vector<ui::action> ui::renderer::actions() const {
    return impl_ptr<impl>()->_action.actions();
}

void ui::renderer::insert_action(ui::action action) {
    impl_ptr<impl>()->insert_action(std::move(action));
}

void ui::renderer::erase_action(ui::action const &action) {
    impl_ptr<impl>()->erase_action(action);
}

void ui::renderer::erase_action(ui::node const &target) {
    impl_ptr<impl>()->erase_action(target);
}

std::vector<ui::batch> ui::renderer::batches() const {
    return to_vector<ui::batch>(impl_ptr<impl>()->batches(), [](auto &pair) { return pair.second; });
}

void ui::renderer::insert_batch(ui::batch batch) {
    impl_ptr<impl>()->insert_batch(std::move(batch));
}

void ui::renderer::erase_batch(ui::batch const &batch) {
    impl_ptr<impl>()->erase_batch(batch);
}

ui::collision_detector const &ui::renderer::collision_detector() const {
    return impl_ptr<impl>()->_detector;
}

ui::collision_detector &ui::renderer::collision_detector() {
    return impl_ptr<impl>()->_detector;
}
