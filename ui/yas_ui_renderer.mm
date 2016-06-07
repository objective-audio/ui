//
//  yas_ui_renderer.mm
//

#include <chrono>
#include "yas_objc_ptr.h"
#include "yas_observing.h"
#include "yas_ui_action.h"
#include "yas_ui_collision_detector.h"
#include "yas_ui_mesh.h"
#include "yas_ui_metal_encode_info.h"
#include "yas_ui_metal_render_encoder.h"
#include "yas_ui_node.h"
#include "yas_ui_render_info.h"
#include "yas_ui_renderer.h"
#include "yas_ui_renderer_impl.h"
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

ui::view_renderable &ui::renderer_base::view_renderable() {
    if (!_view_renderable) {
        _view_renderable = ui::view_renderable{impl_ptr<view_renderable::impl>()};
    }
    return _view_renderable;
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

    bool pre_render() override {
        _action.updatable().update(std::chrono::system_clock::now());

        ui::tree_updates tree_updates;
        _root_node.renderable().fetch_tree_updates(tree_updates);
        return tree_updates.is_any_updated();
    }

    void render(id<MTLCommandBuffer> const commandBuffer, MTLRenderPassDescriptor *const renderPassDesc) override {
        ui::metal_render_encoder metal_render_encoder;
        metal_render_encoder.push_encode_info(
            {renderPassDesc, multiSamplePipelineState(), multiSamplePipelineStateWithoutTexture()});

        ui::render_info render_info{.collision_detector = _detector,
                                    .render_encodable = metal_render_encoder.encodable(),
                                    .matrix = projection_matrix(),
                                    .mesh_matrix = projection_matrix()};

        _root_node.metal().metal_setup(device());

        auto &detector_updatable = _detector.updatable();

        detector_updatable.clear_colliders_if_needed();
        _root_node.renderable().update_render_info(render_info);
        detector_updatable.finalize();

        for (auto &batch : render_info.batches) {
            batch.metal().metal_setup(device());
        }

        auto renderer = cast<ui::renderer_base>();
        metal_render_encoder.render(renderer, commandBuffer, renderPassDesc);
    }

    ui::node _root_node;
    ui::parallel_action _action;
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

ui::collision_detector const &ui::renderer::collision_detector() const {
    return impl_ptr<impl>()->_detector;
}

ui::collision_detector &ui::renderer::collision_detector() {
    return impl_ptr<impl>()->_detector;
}
