//
//  yas_ui_node_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>
#import <sstream>

using namespace yas;
using namespace yas::ui;

namespace yas::test {
struct test_render_encoder : render_encodable {
    std::vector<std::shared_ptr<mesh>> const &meshes() {
        return this->_meshes;
    }

    void append_mesh(std::shared_ptr<mesh> const &mesh) override {
        this->_meshes.emplace_back(mesh);
    }

    static std::shared_ptr<test_render_encoder> make_shared() {
        return std::shared_ptr<test_render_encoder>(new test_render_encoder{});
    }

   private:
    std::vector<std::shared_ptr<mesh>> _meshes;

    test_render_encoder() {
    }
};
}

@interface yas_ui_node_tests : XCTestCase

@end

@implementation yas_ui_node_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    auto node = node::make_shared();

    XCTAssertEqual(node->position().x, 0.0f);
    XCTAssertEqual(node->position().y, 0.0f);
    XCTAssertEqual(node->angle().degrees, 0.0f);
    XCTAssertEqual(node->scale().width, 1.0f);
    XCTAssertEqual(node->scale().height, 1.0f);

    XCTAssertEqual(node->color().red, 1.0f);
    XCTAssertEqual(node->color().green, 1.0f);
    XCTAssertEqual(node->color().blue, 1.0f);
    XCTAssertEqual(node->alpha(), 1.0f);

    XCTAssertFalse(node->mesh());
    XCTAssertFalse(node->collider());
    XCTAssertFalse(node->render_target());

    XCTAssertEqual(node->children().size(), 0);
    XCTAssertFalse(node->parent());
    XCTAssertFalse(node->renderer());

    XCTAssertTrue(node->is_enabled());

    XCTAssertTrue(renderable_node::cast(node));
    XCTAssertTrue(metal_object::cast(node));
}

- (void)test_set_variables {
    auto node = node::make_shared();
    auto mesh = mesh::make_shared();
    auto collider = collider::make_shared();
    std::shared_ptr<batch> batch = batch::make_shared();
    auto render_target = render_target::make_shared();

    node->set_position({1.0f, 2.0f});
    node->set_angle({3.0f});
    node->set_scale({4.0f, 5.0f});
    node->set_color({0.1f, 0.2f, 0.3f});
    node->set_alpha(0.4f);

    node->set_is_enabled(true);

    XCTAssertEqual(node->position().x, 1.0f);
    XCTAssertEqual(node->position().y, 2.0f);
    XCTAssertEqual(node->angle().degrees, 3.0f);
    XCTAssertEqual(node->scale().width, 4.0f);
    XCTAssertEqual(node->scale().height, 5.0f);
    XCTAssertEqual(node->color().red, 0.1f);
    XCTAssertEqual(node->color().green, 0.2f);
    XCTAssertEqual(node->color().blue, 0.3f);
    XCTAssertEqual(node->alpha(), 0.4f);

    node->set_mesh(mesh);
    XCTAssertTrue(node->mesh());
    XCTAssertEqual(node->mesh(), mesh);

    node->set_collider(collider);
    XCTAssertTrue(node->collider());
    XCTAssertEqual(node->collider(), collider);

    node->set_batch(batch);
    XCTAssertTrue(node->batch());
    XCTAssertEqual(node->batch(), batch);

    node->set_batch(nullptr);
    XCTAssertFalse(node->batch());

    XCTAssertTrue(node->is_enabled());

    node->set_render_target(render_target);
    XCTAssertTrue(node->render_target());
    XCTAssertEqual(node->render_target(), render_target);

    node->set_render_target(nullptr);
}

- (void)set_color_to_mesh {
    auto node = node::make_shared();
    auto mesh = mesh::make_shared();

    XCTAssertEqual(mesh->color()[0], 1.0f);
    XCTAssertEqual(mesh->color()[1], 1.0f);
    XCTAssertEqual(mesh->color()[2], 1.0f);
    XCTAssertEqual(mesh->color()[3], 1.0f);

    node->set_color({0.25f, 0.5f, 0.75f});
    node->set_alpha(0.125f);

    node->set_mesh(mesh);

    XCTAssertEqual(mesh->color()[0], 0.25f);
    XCTAssertEqual(mesh->color()[1], 0.5f);
    XCTAssertEqual(mesh->color()[2], 0.75f);
    XCTAssertEqual(mesh->color()[3], 0.125f);

    node->set_color({0.1f, 0.2f, 0.3f});
    node->set_alpha(0.4f);

    XCTAssertEqual(mesh->color()[0], 0.1f);
    XCTAssertEqual(mesh->color()[1], 0.2f);
    XCTAssertEqual(mesh->color()[2], 0.3f);
    XCTAssertEqual(mesh->color()[3], 0.4f);
}

- (void)test_hierarchie {
    auto parent_node = node::make_shared();

    auto sub_node1 = node::make_shared();
    auto sub_node2 = node::make_shared();

    XCTAssertEqual(parent_node->children().size(), 0);
    XCTAssertFalse(sub_node1->parent());
    XCTAssertFalse(sub_node2->parent());

    parent_node->add_sub_node(sub_node1);

    XCTAssertEqual(parent_node->children().size(), 1);
    XCTAssertTrue(sub_node1->parent());

    parent_node->add_sub_node(sub_node2);

    XCTAssertEqual(parent_node->children().size(), 2);
    XCTAssertTrue(sub_node1->parent());
    XCTAssertTrue(sub_node2->parent());

    XCTAssertEqual(parent_node->children().at(0), sub_node1);
    XCTAssertEqual(parent_node->children().at(1), sub_node2);
    XCTAssertEqual(sub_node1->parent(), parent_node);
    XCTAssertEqual(sub_node2->parent(), parent_node);

    sub_node1->remove_from_super_node();

    XCTAssertEqual(parent_node->children().size(), 1);
    XCTAssertFalse(sub_node1->parent());
    XCTAssertTrue(sub_node2->parent());

    XCTAssertEqual(parent_node->children().at(0), sub_node2);

    sub_node2->remove_from_super_node();

    XCTAssertEqual(parent_node->children().size(), 0);
    XCTAssertFalse(sub_node2->parent());
}

- (void)test_add_sub_node_with_index {
    auto parent_node = node::make_shared();

    auto sub_node1 = node::make_shared();
    auto sub_node2 = node::make_shared();
    auto sub_node3 = node::make_shared();

    parent_node->add_sub_node(sub_node1);
    parent_node->add_sub_node(sub_node3);
    parent_node->add_sub_node(sub_node2, 1);

    XCTAssertEqual(parent_node->children().at(0), sub_node1);
    XCTAssertEqual(parent_node->children().at(1), sub_node2);
    XCTAssertEqual(parent_node->children().at(2), sub_node3);
}

- (void)test_parent_changed_when_add_sub_node {
    auto parent_node1 = node::make_shared();
    auto parent_node2 = node::make_shared();

    auto sub_node = node::make_shared();

    parent_node1->add_sub_node(sub_node);

    XCTAssertEqual(parent_node1->children().size(), 1);
    XCTAssertEqual(parent_node2->children().size(), 0);

    parent_node2->add_sub_node(sub_node);

    XCTAssertEqual(parent_node1->children().size(), 0);
    XCTAssertEqual(parent_node2->children().size(), 1);
}

- (void)test_renderable_node {
    auto node = node::make_shared();
    auto renderer = renderer::make_shared();

    auto const renderable = renderable_node::cast(node);

    XCTAssertFalse(renderable->renderer());

    renderable->set_renderer(renderer);

    XCTAssertTrue(renderable->renderer());
    XCTAssertEqual(renderable->renderer(), renderer);
}

- (void)test_observe_add_and_remove_node {
    auto parent_node = node::make_shared();
    auto sub_node = node::make_shared();
    std::vector<node::method> called;

    auto canceller = sub_node->observe([&called](node::method const &method) { called.emplace_back(method); });

    parent_node->add_sub_node(sub_node);

    XCTAssertEqual(called.size(), 1);
    XCTAssertEqual(called.at(0), node::method::added_to_super);

    sub_node->remove_from_super_node();

    XCTAssertEqual(called.size(), 2);
    XCTAssertEqual(called.at(1), node::method::removed_from_super);
}

- (void)test_observe_on_super_destructor {
    auto sub_node = node::make_shared();

    std::vector<node::method> called;

    auto canceller = sub_node->observe([&called](node::method const &method) { called.emplace_back(method); });

    {
        auto parent_node = node::make_shared();

        parent_node->add_sub_node(sub_node);

        XCTAssertEqual(called.size(), 1);
        XCTAssertEqual(called.at(0), node::method::added_to_super);
    }

    XCTAssertEqual(called.size(), 2);
    XCTAssertEqual(called.at(1), node::method::removed_from_super);
}

- (void)test_observe_renderer {
    std::shared_ptr<renderer> notified{nullptr};

    auto node = node::make_shared();

    auto observer =
        node->observe_renderer([&notified](std::shared_ptr<renderer> const &renderer) { notified = renderer; }).end();

    auto renderer = renderer::make_shared();

    renderable_node::cast(node)->set_renderer(renderer);

    XCTAssertEqual(notified, renderer);

    renderable_node::cast(node)->set_renderer(nullptr);

    XCTAssertTrue(!notified);
}

- (void)test_fetch_updates {
    auto node = node::make_shared();

    auto mesh = mesh::make_shared();
    node->set_mesh(mesh);

    auto mesh_data = dynamic_mesh_data::make_shared({.vertex_count = 2, .index_count = 2});
    mesh->set_mesh_data(mesh_data);

    auto sub_node = node::make_shared();
    node->add_sub_node(sub_node);

    tree_updates updates;

    updates = tree_updates{};
    renderable_node::cast(node)->clear_updates();

    renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = tree_updates{};
    renderable_node::cast(node)->clear_updates();

    node->set_angle({1.0f});
    renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(node_update_reason::geometry));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = tree_updates{};
    renderable_node::cast(node)->clear_updates();

    mesh->set_use_mesh_color(true);
    renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertEqual(updates.mesh_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_updates.test(mesh_update_reason::use_mesh_color));
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = tree_updates{};
    renderable_node::cast(node)->clear_updates();

    mesh_data->set_vertex_count(1);
    renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertEqual(updates.mesh_data_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_data_updates.test(mesh_data_update_reason::vertex_count));

    updates = tree_updates{};
    renderable_node::cast(node)->clear_updates();

    sub_node->set_is_enabled(false);
    renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(node_update_reason::enabled));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());
}

- (void)test_fetch_updates_when_enabled_changed {
    auto node = node::make_shared();

    tree_updates updates;

    updates = tree_updates{};
    renderable_node::cast(node)->clear_updates();
    renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = tree_updates{};
    renderable_node::cast(node)->clear_updates();

    // nodeのパラメータを変更する
    node->set_mesh(mesh::make_shared());
    auto mesh_data = dynamic_mesh_data::make_shared({.vertex_count = 2, .index_count = 2});
    mesh_data->set_vertex_count(1);
    node->mesh()->set_mesh_data(mesh_data);

    node->set_angle({1.0f});
    node->set_is_enabled(false);
    node->set_collider(collider::make_shared());
    node->set_batch(batch::make_shared());

    auto sub_node = node::make_shared();
    node->add_sub_node(sub_node);

    // enabledがfalseの時はenabled以外の変更はフェッチされない
    renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(node_update_reason::enabled));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = tree_updates{};
    renderable_node::cast(node)->clear_updates();

    node->set_is_enabled(true);

    // enabledをtrueにするとフェッチされる
    renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 6);
    XCTAssertTrue(updates.node_updates.test(node_update_reason::enabled));
    XCTAssertTrue(updates.node_updates.test(node_update_reason::children));
    XCTAssertTrue(updates.node_updates.test(node_update_reason::geometry));
    XCTAssertTrue(updates.node_updates.test(node_update_reason::mesh));
    XCTAssertTrue(updates.node_updates.test(node_update_reason::collider));
    XCTAssertTrue(updates.node_updates.test(node_update_reason::batch));
    XCTAssertTrue(updates.mesh_updates.flags.any());
    XCTAssertTrue(updates.mesh_data_updates.flags.any());
}

- (void)test_is_rendering_color_exists {
    auto node = node::make_shared();

    XCTAssertFalse(renderable_node::cast(node)->is_rendering_color_exists());

    auto mesh = mesh::make_shared();
    mesh->set_mesh_data(mesh_data::make_shared({.vertex_count = 1, .index_count = 1}));
    node->set_mesh(mesh);

    XCTAssertTrue(renderable_node::cast(node)->is_rendering_color_exists());

    node->set_mesh(nullptr);
    auto sub_node = node::make_shared();
    sub_node->set_mesh(mesh);
    node->add_sub_node(sub_node);

    XCTAssertTrue(renderable_node::cast(node)->is_rendering_color_exists());

    node->set_is_enabled(false);

    XCTAssertFalse(renderable_node::cast(node)->is_rendering_color_exists());
}

- (void)test_metal_setup {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object());

    auto root_mesh = mesh::make_shared();
    auto root_mesh_data = mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    root_mesh->set_mesh_data(root_mesh_data);

    auto sub_mesh = mesh::make_shared();
    auto sub_mesh_data = mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    sub_mesh->set_mesh_data(sub_mesh_data);

    auto root_node = node::make_shared();
    root_node->set_mesh(root_mesh);

    auto sub_node = node::make_shared();
    sub_node->set_mesh(sub_mesh);
    root_node->add_sub_node(sub_node);

    XCTAssertFalse(root_mesh_data->metal_system());
    XCTAssertFalse(sub_mesh_data->metal_system());

    XCTAssertTrue(metal_object::cast(root_node)->metal_setup(metal_system));

    XCTAssertTrue(root_mesh_data->metal_system());
    XCTAssertTrue(sub_mesh_data->metal_system());
}

- (void)test_build_render_info_smoke {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object());

    auto node = node::make_shared();
    auto sub_node = node::make_shared();
    auto batch_node = node::make_shared();
    auto batch_sub_node = node::make_shared();

    auto const mesh_data = mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    auto const sub_mesh_data = mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    auto const batch_sub_mesh_data = mesh_data::make_shared({.vertex_count = 1, .index_count = 1});

    node->set_collider(collider::make_shared(shape::make_shared(circle_shape{})));
    auto const mesh = mesh::make_shared();
    node->set_mesh(mesh);
    mesh->set_mesh_data(mesh_data);

    auto const sub_mesh = mesh::make_shared();
    sub_node->set_mesh(sub_mesh);
    sub_mesh->set_mesh_data(sub_mesh_data);

    batch_node->set_batch(batch::make_shared());
    batch_node->add_sub_node(batch_sub_node);

    auto const batch_sub_mesh = mesh::make_shared();
    batch_sub_node->set_mesh(batch_sub_mesh);
    batch_sub_mesh->set_mesh_data(batch_sub_mesh_data);

    node->add_sub_node(sub_node);
    node->add_sub_node(batch_node);

    metal_object::cast(node)->metal_setup(metal_system);

    auto detector = detector::make_shared();
    auto render_encoder = test::test_render_encoder::make_shared();

    render_info render_info{.detector = detector,
                            .render_encodable = render_encodable::cast(render_encoder),
                            .matrix = matrix_identity_float4x4,
                            .mesh_matrix = matrix_identity_float4x4};

    renderable_node::cast(node)->build_render_info(render_info);

    XCTAssertEqual(render_encoder->meshes().size(), 3);
    XCTAssertEqual(render_encoder->meshes().at(0), mesh);
    XCTAssertEqual(render_encoder->meshes().at(1), sub_mesh);
}

- (void)test_local_matrix {
    auto node = node::make_shared();
    node->set_position(point{10.0f, -20.0f});
    node->set_scale(size{2.0f, 0.5f});
    node->set_angle({90.0f});

    simd::float4x4 expected_matrix = matrix::translation(node->position().x, node->position().y) *
                                     matrix::rotation(node->angle().degrees) *
                                     matrix::scale(node->scale().width, node->scale().height);

    XCTAssertTrue(is_equal(node->local_matrix(), expected_matrix));
}

- (void)test_convert_position {
    auto node = node::make_shared();
    auto sub_node = node::make_shared();
    node->add_sub_node(sub_node);
    node->set_position({-1.0f, -1.0f});
    node->set_scale({1.0f / 200.0f, 1.0f / 100.0f});

    auto converted_position = sub_node->convert_position({1.0f, -0.5f});
    XCTAssertEqualWithAccuracy(converted_position.x, 400.0f, 0.001f);
    XCTAssertEqualWithAccuracy(converted_position.y, 50.0f, 0.001f);
}

- (void)test_matrix {
    auto root_node = node::make_shared();
    root_node->set_position(point{10.0f, -20.0f});
    root_node->set_scale(size{2.0f, 0.5f});
    root_node->set_angle({90.0f});

    auto sub_node = node::make_shared();
    sub_node->set_position(point{-50.0f, 10.0f});
    sub_node->set_scale(size{0.25f, 3.0f});
    sub_node->set_angle({-45.0f});

    root_node->add_sub_node(sub_node);

    simd::float4x4 root_local_matrix = matrix::translation(root_node->position().x, root_node->position().y) *
                                       matrix::rotation(root_node->angle().degrees) *
                                       matrix::scale(root_node->scale().width, root_node->scale().height);
    simd::float4x4 sub_local_matrix = matrix::translation(sub_node->position().x, sub_node->position().y) *
                                      matrix::rotation(sub_node->angle().degrees) *
                                      matrix::scale(sub_node->scale().width, sub_node->scale().height);
    simd::float4x4 expected_matrix = root_local_matrix * sub_local_matrix;

    XCTAssertTrue(is_equal(sub_node->matrix(), expected_matrix));
}

- (void)test_set_renderer_recursively {
    auto renderer = renderer::make_shared();

    auto node = node::make_shared();
    auto sub_node = node::make_shared();
    node->add_sub_node(sub_node);

    renderer->root_node()->add_sub_node(node);

    XCTAssertTrue(node->renderer());
    XCTAssertTrue(sub_node->renderer());
}

- (void)test_node_method_to_string {
    XCTAssertEqual(to_string(node::method::added_to_super), "added_to_super");
    XCTAssertEqual(to_string(node::method::removed_from_super), "removed_from_super");
}

- (void)test_node_update_reason_to_string {
    XCTAssertEqual(to_string(node_update_reason::geometry), "geometry");
    XCTAssertEqual(to_string(node_update_reason::mesh), "mesh");
    XCTAssertEqual(to_string(node_update_reason::collider), "collider");
    XCTAssertEqual(to_string(node_update_reason::enabled), "enabled");
    XCTAssertEqual(to_string(node_update_reason::children), "children");
    XCTAssertEqual(to_string(node_update_reason::batch), "batch");
    XCTAssertEqual(to_string(node_update_reason::count), "count");
}

- (void)test_node_method_ostream {
    auto const methods = {node::method::added_to_super, node::method::removed_from_super};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

- (void)test_node_update_reason_ostream {
    auto const reasons = {node_update_reason::geometry, node_update_reason::mesh,     node_update_reason::collider,
                          node_update_reason::enabled,  node_update_reason::children, node_update_reason::batch,
                          node_update_reason::count};

    for (auto const &reason : reasons) {
        std::ostringstream stream;
        stream << reason;
        XCTAssertEqual(stream.str(), to_string(reason));
    }
}

- (void)test_attach_x_layout_guide {
    auto x_guide = layout_value_guide::make_shared(-1.0f);

    auto node = node::make_shared();
    node->attach_x_layout_guide(*x_guide);

    XCTAssertEqual(node->position().x, -1.0f);

    x_guide->set_value(1.0f);

    XCTAssertEqual(node->position().x, 1.0f);
}

- (void)test_attach_y_layout_guide {
    auto y_guide = layout_value_guide::make_shared(-1.0f);

    auto node = node::make_shared();
    node->attach_y_layout_guide(*y_guide);

    XCTAssertEqual(node->position().y, -1.0f);

    y_guide->set_value(1.0f);

    XCTAssertEqual(node->position().y, 1.0f);
}

- (void)test_attach_position_layout_guide {
    auto guide_point = layout_point_guide::make_shared({-1.0f, -2.0f});

    auto node = node::make_shared();
    node->attach_position_layout_guides(*guide_point);

    XCTAssertTrue(node->position() == (point{-1.0f, -2.0f}));

    guide_point->set_point({1.0f, 2.0f});

    XCTAssertTrue(node->position() == (point{1.0f, 2.0f}));
}

- (void)test_render_batch {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object());

    auto parent_batch_node = node::make_shared();
    auto child_batch_node1 = node::make_shared();
    auto child_batch_node2 = node::make_shared();
    auto mesh_node1a = node::make_shared();
    auto mesh_node1b = node::make_shared();
    auto mesh_node2 = node::make_shared();

    auto parent_batch = batch::make_shared();
    parent_batch_node->set_batch(parent_batch);

    auto child_batch1 = batch::make_shared();
    child_batch_node1->set_batch(child_batch1);
    auto child_batch2 = batch::make_shared();
    child_batch_node2->set_batch(child_batch2);

    auto mesh1a = mesh::make_shared();
    mesh1a->set_color({0.5f, 0.5f, 0.5f, 0.5f});
    auto mesh_data1a = dynamic_mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data1a->write([](std::vector<vertex2d_t> &vertices, std::vector<index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 1.0f;
        vertex.position.y = 2.0f;
        vertex.tex_coord.x = 3.0f;
        vertex.tex_coord.y = 4.0f;

        auto &index = indices.at(0);
        index = 0;
    });
    mesh1a->set_mesh_data(mesh_data1a);
    mesh_node1a->set_mesh(mesh1a);
    mesh_node1a->set_color(color{.red = 0.5f, .green = 0.6f, .blue = 0.7f});
    mesh_node1a->set_alpha(0.8f);

    auto mesh1b = mesh::make_shared();
    mesh1b->set_use_mesh_color(true);
    auto mesh_data1b = dynamic_mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data1b->write([](std::vector<vertex2d_t> &vertices, std::vector<index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 10.0f;
        vertex.position.y = 20.0f;
        vertex.tex_coord.x = 30.0f;
        vertex.tex_coord.y = 40.0f;
        vertex.color[0] = 0.1f;
        vertex.color[1] = 0.2f;
        vertex.color[2] = 0.3f;
        vertex.color[3] = 0.4f;

        auto &index = indices.at(0);
        index = 0;
    });
    mesh1b->set_mesh_data(mesh_data1b);

    auto texture1b = texture::make_shared({.point_size = {.width = 1024, .height = 1024}});
    mesh1b->set_texture(texture1b);

    mesh_node1b->set_mesh(mesh1b);

    auto mesh2 = mesh::make_shared();
    mesh2->set_use_mesh_color(true);
    auto mesh_data2 = dynamic_mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data2->write([](std::vector<vertex2d_t> &vertices, std::vector<index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 100.0f;
        vertex.position.y = 200.0f;
        vertex.tex_coord.x = 300.0f;
        vertex.tex_coord.y = 400.0f;
        vertex.color[0] = 0.01f;
        vertex.color[1] = 0.02f;
        vertex.color[2] = 0.03f;
        vertex.color[3] = 0.04f;

        auto &index = indices.at(0);
        index = 0;
    });
    mesh2->set_mesh_data(mesh_data2);

    auto texture2 = texture::make_shared({.point_size = {.width = 1024, .height = 1024}});
    mesh2->set_texture(texture2);

    mesh_node2->set_mesh(mesh2);

    parent_batch_node->add_sub_node(child_batch_node1);
    parent_batch_node->add_sub_node(child_batch_node2);
    child_batch_node1->add_sub_node(mesh_node1a);
    child_batch_node1->add_sub_node(mesh_node1b);
    child_batch_node2->add_sub_node(mesh_node2);

    auto render = [&parent_batch_node, &metal_system, self]() {
        auto detector = detector::make_shared();
        auto render_encoder = test::test_render_encoder::make_shared();

        render_info render_info{.detector = detector,
                                .render_encodable = render_encodable::cast(render_encoder),
                                .matrix = matrix_identity_float4x4,
                                .mesh_matrix = matrix_identity_float4x4};

        XCTAssertTrue(metal_object::cast(parent_batch_node)->metal_setup(metal_system));

        tree_updates parent_updates;
        renderable_node::cast(parent_batch_node)->fetch_updates(parent_updates);
        XCTAssertTrue(parent_updates.is_any_updated());

        renderable_node::cast(parent_batch_node)->build_render_info(render_info);

        return render_encoder;
    };

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 3);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 1.0f);
            XCTAssertEqual(rendered_vertex.position.y, 2.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 3.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 4.0f);
            XCTAssertEqual(rendered_vertex.color[0], 0.5f);
            XCTAssertEqual(rendered_vertex.color[1], 0.6f);
            XCTAssertEqual(rendered_vertex.color[2], 0.7f);
            XCTAssertEqual(rendered_vertex.color[3], 0.8f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 0);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(1)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 10.0f);
            XCTAssertEqual(rendered_vertex.position.y, 20.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 30.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 40.0f);
            XCTAssertEqual(rendered_vertex.color[0], 0.1f);
            XCTAssertEqual(rendered_vertex.color[1], 0.2f);
            XCTAssertEqual(rendered_vertex.color[2], 0.3f);
            XCTAssertEqual(rendered_vertex.color[3], 0.4f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 0);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(2)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 100.0f);
            XCTAssertEqual(rendered_vertex.position.y, 200.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 300.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 400.0f);
            XCTAssertEqual(rendered_vertex.color[0], 0.01f);
            XCTAssertEqual(rendered_vertex.color[1], 0.02f);
            XCTAssertEqual(rendered_vertex.color[2], 0.03f);
            XCTAssertEqual(rendered_vertex.color[3], 0.04f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 0);
        }

        renderable_node::cast(parent_batch_node)->clear_updates();
    }

    {
        tree_updates parent_updates;
        renderable_node::cast(parent_batch_node)->fetch_updates(parent_updates);
        XCTAssertFalse(parent_updates.is_any_updated());
    }

    mesh_data1a->write([](std::vector<vertex2d_t> &vertices, std::vector<index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 1.5f;
        vertex.position.y = 2.5f;
        vertex.tex_coord.x = 3.5f;
        vertex.tex_coord.y = 4.5f;

        auto &index = indices.at(0);
        index = 2;
    });
    mesh_node1a->set_color(color{.red = 0.51f, .green = 0.61f, .blue = 0.71f});

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 3);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 1.5f);
            XCTAssertEqual(rendered_vertex.position.y, 2.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 3.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 4.5f);
            XCTAssertEqual(rendered_vertex.color[0], 0.51f);
            XCTAssertEqual(rendered_vertex.color[1], 0.61f);
            XCTAssertEqual(rendered_vertex.color[2], 0.71f);
            XCTAssertEqual(rendered_vertex.color[3], 0.8f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 2);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(1)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 10.0f);
            XCTAssertEqual(rendered_vertex.position.y, 20.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 30.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 40.0f);
            XCTAssertEqual(rendered_vertex.color[0], 0.1f);
            XCTAssertEqual(rendered_vertex.color[1], 0.2f);
            XCTAssertEqual(rendered_vertex.color[2], 0.3f);
            XCTAssertEqual(rendered_vertex.color[3], 0.4f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 0);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(2)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 100.0f);
            XCTAssertEqual(rendered_vertex.position.y, 200.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 300.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 400.0f);
            XCTAssertEqual(rendered_vertex.color[0], 0.01f);
            XCTAssertEqual(rendered_vertex.color[1], 0.02f);
            XCTAssertEqual(rendered_vertex.color[2], 0.03f);
            XCTAssertEqual(rendered_vertex.color[3], 0.04f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 0);
        }

        renderable_node::cast(parent_batch_node)->clear_updates();
    }

    mesh_data1b->write([](std::vector<vertex2d_t> &vertices, std::vector<index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 10.5f;
        vertex.position.y = 20.5f;
        vertex.tex_coord.x = 30.5f;
        vertex.tex_coord.y = 40.5f;
        vertex.color[0] = 0.15f;
        vertex.color[1] = 0.25f;
        vertex.color[2] = 0.35f;
        vertex.color[3] = 0.45f;

        auto &index = indices.at(0);
        index = 3;
    });

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 3);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 1.5f);
            XCTAssertEqual(rendered_vertex.position.y, 2.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 3.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 4.5f);
            XCTAssertEqual(rendered_vertex.color[0], 0.51f);
            XCTAssertEqual(rendered_vertex.color[1], 0.61f);
            XCTAssertEqual(rendered_vertex.color[2], 0.71f);
            XCTAssertEqual(rendered_vertex.color[3], 0.8f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 2);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(1)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 10.5f);
            XCTAssertEqual(rendered_vertex.position.y, 20.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 30.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 40.5f);
            XCTAssertEqual(rendered_vertex.color[0], 0.15f);
            XCTAssertEqual(rendered_vertex.color[1], 0.25f);
            XCTAssertEqual(rendered_vertex.color[2], 0.35f);
            XCTAssertEqual(rendered_vertex.color[3], 0.45f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 3);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(2)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 100.0f);
            XCTAssertEqual(rendered_vertex.position.y, 200.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 300.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 400.0f);
            XCTAssertEqual(rendered_vertex.color[0], 0.01f);
            XCTAssertEqual(rendered_vertex.color[1], 0.02f);
            XCTAssertEqual(rendered_vertex.color[2], 0.03f);
            XCTAssertEqual(rendered_vertex.color[3], 0.04f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 0);
        }

        renderable_node::cast(parent_batch_node)->clear_updates();
    }

    mesh_data2->write([](std::vector<vertex2d_t> &vertices, std::vector<index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 111.0f;
        vertex.position.y = 222.0f;
        vertex.tex_coord.x = 333.0f;
        vertex.tex_coord.y = 444.0f;
        vertex.color[0] = 0.05f;
        vertex.color[1] = 0.06f;
        vertex.color[2] = 0.07f;
        vertex.color[3] = 0.08f;

        auto &index = indices.at(0);
        index = 4;
    });

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 3);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 1.5f);
            XCTAssertEqual(rendered_vertex.position.y, 2.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 3.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 4.5f);
            XCTAssertEqual(rendered_vertex.color[0], 0.51f);
            XCTAssertEqual(rendered_vertex.color[1], 0.61f);
            XCTAssertEqual(rendered_vertex.color[2], 0.71f);
            XCTAssertEqual(rendered_vertex.color[3], 0.8f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 2);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(1)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 10.5f);
            XCTAssertEqual(rendered_vertex.position.y, 20.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 30.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 40.5f);
            XCTAssertEqual(rendered_vertex.color[0], 0.15f);
            XCTAssertEqual(rendered_vertex.color[1], 0.25f);
            XCTAssertEqual(rendered_vertex.color[2], 0.35f);
            XCTAssertEqual(rendered_vertex.color[3], 0.45f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 3);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(2)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 111.0f);
            XCTAssertEqual(rendered_vertex.position.y, 222.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 333.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 444.0f);
            XCTAssertEqual(rendered_vertex.color[0], 0.05f);
            XCTAssertEqual(rendered_vertex.color[1], 0.06f);
            XCTAssertEqual(rendered_vertex.color[2], 0.07f);
            XCTAssertEqual(rendered_vertex.color[3], 0.08f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 4);
        }

        renderable_node::cast(parent_batch_node)->clear_updates();
    }

    mesh_node1b->set_is_enabled(false);

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 2);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 1.5f);
            XCTAssertEqual(rendered_vertex.position.y, 2.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 3.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 4.5f);
            XCTAssertEqual(rendered_vertex.color[0], 0.51f);
            XCTAssertEqual(rendered_vertex.color[1], 0.61f);
            XCTAssertEqual(rendered_vertex.color[2], 0.71f);
            XCTAssertEqual(rendered_vertex.color[3], 0.8f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 2);
        }

        if (auto const &rendered_mesh = render_encoder->meshes().at(1)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 111.0f);
            XCTAssertEqual(rendered_vertex.position.y, 222.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 333.0f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 444.0f);
            XCTAssertEqual(rendered_vertex.color[0], 0.05f);
            XCTAssertEqual(rendered_vertex.color[1], 0.06f);
            XCTAssertEqual(rendered_vertex.color[2], 0.07f);
            XCTAssertEqual(rendered_vertex.color[3], 0.08f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 4);
        }

        renderable_node::cast(parent_batch_node)->clear_updates();
    }

    mesh_node1a->set_is_enabled(false);
    mesh_node1b->set_is_enabled(true);
    mesh_node2->set_is_enabled(false);

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 1);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertTrue(rendered_mesh->is_use_mesh_color());
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 1);
            auto const &rendered_vertex = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex.position.x, 10.5f);
            XCTAssertEqual(rendered_vertex.position.y, 20.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.x, 30.5f);
            XCTAssertEqual(rendered_vertex.tex_coord.y, 40.5f);
            XCTAssertEqual(rendered_vertex.color[0], 0.15f);
            XCTAssertEqual(rendered_vertex.color[1], 0.25f);
            XCTAssertEqual(rendered_vertex.color[2], 0.35f);
            XCTAssertEqual(rendered_vertex.color[3], 0.45f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 1);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 3);
        }

        renderable_node::cast(parent_batch_node)->clear_updates();
    }
}

- (void)test_render_batch_alpha_exists {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = metal_system::make_shared(device.object());

    auto batch_node = node::make_shared();
    batch_node->set_batch(batch::make_shared());

    auto mesh_node1 = node::make_shared();
    batch_node->add_sub_node(mesh_node1);

    auto mesh1 = mesh::make_shared();
    mesh1->set_use_mesh_color(false);
    auto mesh_data1 = mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data1->write([](std::vector<vertex2d_t> &vertices, std::vector<index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 1.0f;
        vertex.position.y = 2.0f;

        auto &index = indices.at(0);
        index = 0;
    });
    mesh1->set_mesh_data(mesh_data1);
    mesh_node1->set_mesh(mesh1);
    mesh_node1->set_color(color{.red = 0.1f, .green = 0.2f, .blue = 0.3f});
    mesh_node1->set_alpha(0.0f);

    auto mesh_node2 = node::make_shared();
    batch_node->add_sub_node(mesh_node2);

    auto mesh2 = mesh::make_shared();
    mesh2->set_use_mesh_color(false);
    auto mesh_data2 = mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data2->write([](std::vector<vertex2d_t> &vertices, std::vector<index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 3.0f;
        vertex.position.y = 4.0f;

        auto &index = indices.at(0);
        index = 0;
    });
    mesh2->set_mesh_data(mesh_data2);
    mesh_node2->set_mesh(mesh2);
    mesh_node2->set_color(color{.red = 0.5f, .green = 0.6f, .blue = 0.7f});
    mesh_node2->set_alpha(1.0f);

    auto render = [&batch_node, &metal_system, self]() {
        auto detector = detector::make_shared();
        auto render_encoder = test::test_render_encoder::make_shared();

        render_info render_info{.detector = detector,
                                .render_encodable = render_encodable::cast(render_encoder),
                                .matrix = matrix_identity_float4x4,
                                .mesh_matrix = matrix_identity_float4x4};

        XCTAssertTrue(metal_object::cast(batch_node)->metal_setup(metal_system));

        tree_updates parent_updates;
        renderable_node::cast(batch_node)->fetch_updates(parent_updates);
        XCTAssertTrue(parent_updates.is_any_updated());

        renderable_node::cast(batch_node)->build_render_info(render_info);

        return render_encoder;
    };

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 1);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 2);
            auto const &rendered_vertex_0 = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex_0.position.x, 1.0f);
            XCTAssertEqual(rendered_vertex_0.position.y, 2.0f);
            XCTAssertEqual(rendered_vertex_0.color[0], 0.1f);
            XCTAssertEqual(rendered_vertex_0.color[1], 0.2f);
            XCTAssertEqual(rendered_vertex_0.color[2], 0.3f);
            XCTAssertEqual(rendered_vertex_0.color[3], 0.0f);

            auto const &rendered_vertex_1 = rendered_mesh_data->vertices()[1];
            XCTAssertEqual(rendered_vertex_1.position.x, 3.0f);
            XCTAssertEqual(rendered_vertex_1.position.y, 4.0f);
            XCTAssertEqual(rendered_vertex_1.color[0], 0.5f);
            XCTAssertEqual(rendered_vertex_1.color[1], 0.6f);
            XCTAssertEqual(rendered_vertex_1.color[2], 0.7f);
            XCTAssertEqual(rendered_vertex_1.color[3], 1.0f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 2);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 0);
            XCTAssertEqual(rendered_indices[1], 1);
        }

        renderable_node::cast(batch_node)->clear_updates();
    }

    mesh_node1->set_alpha(0.5f);

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 1);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 2);
            auto const &rendered_vertex_0 = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex_0.color[3], 0.5f);

            auto const &rendered_vertex_1 = rendered_mesh_data->vertices()[1];
            XCTAssertEqual(rendered_vertex_1.color[3], 1.0f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 2);
            auto const &rendered_indices = rendered_mesh_data->indices();
            XCTAssertEqual(rendered_indices[0], 0);
            XCTAssertEqual(rendered_indices[1], 1);
        }

        renderable_node::cast(batch_node)->clear_updates();
    }

    mesh_node2->set_alpha(0.0f);

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 1);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 2);
            auto const &rendered_vertex_0 = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex_0.color[3], 0.5f);

            auto const &rendered_vertex_1 = rendered_mesh_data->vertices()[1];
            XCTAssertEqual(rendered_vertex_1.color[3], 0.0f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 2);
        }

        renderable_node::cast(batch_node)->clear_updates();
    }

    mesh_node1->set_alpha(0.0f);

    {
        auto render_encoder = render();

        XCTAssertEqual(render_encoder->meshes().size(), 1);

        if (auto const &rendered_mesh = render_encoder->meshes().at(0)) {
            auto const &rendered_mesh_data = rendered_mesh->mesh_data();
            XCTAssertEqual(rendered_mesh_data->vertex_count(), 2);
            auto const &rendered_vertex_0 = rendered_mesh_data->vertices()[0];
            XCTAssertEqual(rendered_vertex_0.color[3], 0.0f);

            auto const &rendered_vertex_1 = rendered_mesh_data->vertices()[1];
            XCTAssertEqual(rendered_vertex_1.color[3], 0.0f);

            XCTAssertEqual(rendered_mesh_data->index_count(), 2);
        }

        renderable_node::cast(batch_node)->clear_updates();
    }
}

@end
