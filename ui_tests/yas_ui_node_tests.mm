//
//  yas_ui_node_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/ui.h>
#import <iostream>
#import <sstream>

using namespace yas;

namespace yas::test {
struct test_render_encoder : ui::render_encodable {
    std::vector<ui::mesh_ptr> const &meshes() {
        return this->_meshes;
    }

    void append_mesh(ui::mesh_ptr const &mesh) override {
        this->_meshes.emplace_back(mesh);
    }

    static std::shared_ptr<test_render_encoder> make_shared() {
        return std::shared_ptr<test_render_encoder>(new test_render_encoder{});
    }

   private:
    std::vector<ui::mesh_ptr> _meshes;

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
    auto node = ui::node::make_shared();

    XCTAssertEqual(node->position().x, 0.0f);
    XCTAssertEqual(node->position().y, 0.0f);
    XCTAssertEqual(node->angle()->value().degrees, 0.0f);
    XCTAssertEqual(node->scale()->value().width, 1.0f);
    XCTAssertEqual(node->scale()->value().height, 1.0f);

    XCTAssertEqual(node->color()->value().red, 1.0f);
    XCTAssertEqual(node->color()->value().green, 1.0f);
    XCTAssertEqual(node->color()->value().blue, 1.0f);
    XCTAssertEqual(node->alpha()->value(), 1.0f);

    XCTAssertFalse(node->mesh()->value());
    XCTAssertFalse(node->collider()->value());
    XCTAssertFalse(node->render_target()->value());

    XCTAssertEqual(node->children().size(), 0);
    XCTAssertFalse(node->parent());
    XCTAssertFalse(node->renderer());

    XCTAssertTrue(node->is_enabled()->value());

    XCTAssertTrue(ui::renderable_node::cast(node));
    XCTAssertTrue(ui::metal_object::cast(node));
}

- (void)test_set_variables {
    auto node = ui::node::make_shared();
    auto mesh = ui::mesh::make_shared();
    auto collider = ui::collider::make_shared();
    std::shared_ptr<ui::batch> batch = ui::batch::make_shared();
    auto render_target = ui::render_target::make_shared();

    node->set_position({1.0f, 2.0f});
    node->angle()->set_value({3.0f});
    node->scale()->set_value({4.0f, 5.0f});
    node->color()->set_value({0.1f, 0.2f, 0.3f});
    node->alpha()->set_value(0.4f);

    node->is_enabled()->set_value(true);

    XCTAssertEqual(node->position().x, 1.0f);
    XCTAssertEqual(node->position().y, 2.0f);
    XCTAssertEqual(node->angle()->value().degrees, 3.0f);
    XCTAssertEqual(node->scale()->value().width, 4.0f);
    XCTAssertEqual(node->scale()->value().height, 5.0f);
    XCTAssertEqual(node->color()->value().red, 0.1f);
    XCTAssertEqual(node->color()->value().green, 0.2f);
    XCTAssertEqual(node->color()->value().blue, 0.3f);
    XCTAssertEqual(node->alpha()->value(), 0.4f);

    node->mesh()->set_value(mesh);
    XCTAssertTrue(node->mesh()->value());
    XCTAssertEqual(node->mesh()->value(), mesh);

    node->collider()->set_value(collider);
    XCTAssertTrue(node->collider()->value());
    XCTAssertEqual(node->collider()->value(), collider);

    node->batch()->set_value(batch);
    XCTAssertTrue(node->batch()->value());
    XCTAssertEqual(node->batch()->value(), batch);

    node->batch()->set_value(nullptr);
    XCTAssertFalse(node->batch()->value());

    XCTAssertTrue(node->is_enabled()->value());

    node->render_target()->set_value(render_target);
    XCTAssertTrue(node->render_target()->value());
    XCTAssertEqual(node->render_target()->value(), render_target);

    node->render_target()->set_value(nullptr);
}

- (void)test_const_variables {
#warning 要チェック
    auto node = ui::node::make_shared();
    ui::node_ptr const &const_node = node;

    XCTAssertFalse(const_node->mesh()->value());
    XCTAssertFalse(const_node->collider()->value());
    XCTAssertFalse(const_node->batch()->value());

    node->mesh()->set_value(ui::mesh::make_shared());
    node->collider()->set_value(ui::collider::make_shared());
    node->batch()->set_value(ui::batch::make_shared());

    XCTAssertTrue(const_node->mesh()->value());
    XCTAssertTrue(const_node->collider()->value());
    XCTAssertEqual(const_node->children().size(), 0);
    XCTAssertTrue(const_node->batch()->value());
}

- (void)set_color_to_mesh {
    auto node = ui::node::make_shared();
    auto mesh = ui::mesh::make_shared();

    XCTAssertEqual(mesh->color()[0], 1.0f);
    XCTAssertEqual(mesh->color()[1], 1.0f);
    XCTAssertEqual(mesh->color()[2], 1.0f);
    XCTAssertEqual(mesh->color()[3], 1.0f);

    node->color()->set_value({0.25f, 0.5f, 0.75f});
    node->alpha()->set_value(0.125f);

    node->mesh()->set_value(mesh);

    XCTAssertEqual(mesh->color()[0], 0.25f);
    XCTAssertEqual(mesh->color()[1], 0.5f);
    XCTAssertEqual(mesh->color()[2], 0.75f);
    XCTAssertEqual(mesh->color()[3], 0.125f);

    node->color()->set_value({0.1f, 0.2f, 0.3f});
    node->alpha()->set_value(0.4f);

    XCTAssertEqual(mesh->color()[0], 0.1f);
    XCTAssertEqual(mesh->color()[1], 0.2f);
    XCTAssertEqual(mesh->color()[2], 0.3f);
    XCTAssertEqual(mesh->color()[3], 0.4f);
}

- (void)test_hierarchie {
    auto parent_node = ui::node::make_shared();

    auto sub_node1 = ui::node::make_shared();
    auto sub_node2 = ui::node::make_shared();

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
    auto parent_node = ui::node::make_shared();

    auto sub_node1 = ui::node::make_shared();
    auto sub_node2 = ui::node::make_shared();
    auto sub_node3 = ui::node::make_shared();

    parent_node->add_sub_node(sub_node1);
    parent_node->add_sub_node(sub_node3);
    parent_node->add_sub_node(sub_node2, 1);

    XCTAssertEqual(parent_node->children().at(0), sub_node1);
    XCTAssertEqual(parent_node->children().at(1), sub_node2);
    XCTAssertEqual(parent_node->children().at(2), sub_node3);
}

- (void)test_parent_changed_when_add_sub_node {
    auto parent_node1 = ui::node::make_shared();
    auto parent_node2 = ui::node::make_shared();

    auto sub_node = ui::node::make_shared();

    parent_node1->add_sub_node(sub_node);

    XCTAssertEqual(parent_node1->children().size(), 1);
    XCTAssertEqual(parent_node2->children().size(), 0);

    parent_node2->add_sub_node(sub_node);

    XCTAssertEqual(parent_node1->children().size(), 0);
    XCTAssertEqual(parent_node2->children().size(), 1);
}

- (void)test_renderable_node {
    auto node = ui::node::make_shared();
    auto renderer = ui::renderer::make_shared();

    auto const renderable = ui::renderable_node::cast(node);

    XCTAssertFalse(renderable->renderer());

    renderable->set_renderer(renderer);

    XCTAssertTrue(renderable->renderer());
    XCTAssertEqual(renderable->renderer(), renderer);
}

- (void)test_add_and_remove_node_observed {
    auto parent_node = ui::node::make_shared();
    auto sub_node = ui::node::make_shared();
    int observer_called_count = 0;
    bool added_to_super_called = false;
    bool removed_from_super_called = false;

    auto added_canceller = sub_node->observe(ui::node::method::added_to_super,
                                             [&observer_called_count, &added_to_super_called](auto const &pair) {
                                                 added_to_super_called = true;
                                                 ++observer_called_count;
                                             });

    auto removed_canceller = sub_node->observe(ui::node::method::removed_from_super,
                                               [&observer_called_count, &removed_from_super_called](auto const &pair) {
                                                   removed_from_super_called = true;
                                                   ++observer_called_count;
                                               });

    parent_node->add_sub_node(sub_node);

    XCTAssertTrue(added_to_super_called);

    sub_node->remove_from_super_node();

    XCTAssertTrue(removed_from_super_called);

    XCTAssertEqual(observer_called_count, 2);
}

- (void)test_chain_with_methods {
    std::optional<ui::node::method> called;

    auto node = ui::node::make_shared();

    auto canceller = node->observe({ui::node::method::added_to_super, ui::node::method::removed_from_super},
                                   [&called](auto const &pair) { called = pair.first; });

    auto super_node = ui::node::make_shared();

    super_node->add_sub_node(node);

    XCTAssertTrue(called);
    XCTAssertEqual(*called, ui::node::method::added_to_super);

    called = std::nullopt;

    node->remove_from_super_node();

    XCTAssertTrue(called);
    XCTAssertEqual(*called, ui::node::method::removed_from_super);
}

- (void)test_chain_renderer {
    ui::renderer_ptr notified{nullptr};

    auto node = ui::node::make_shared();

    auto observer =
        node->observe_renderer([&notified](ui::renderer_ptr const &renderer) { notified = renderer; }, false);

    auto renderer = ui::renderer::make_shared();

    ui::renderable_node::cast(node)->set_renderer(renderer);

    XCTAssertEqual(notified, renderer);

    ui::renderable_node::cast(node)->set_renderer(nullptr);

    XCTAssertTrue(!notified);
}

- (void)test_fetch_updates {
    auto node = ui::node::make_shared();

    auto mesh = ui::mesh::make_shared();
    node->mesh()->set_value(mesh);

    auto mesh_data = ui::dynamic_mesh_data::make_shared({.vertex_count = 2, .index_count = 2});
    mesh->set_mesh_data(mesh_data);

    auto sub_node = ui::node::make_shared();
    node->add_sub_node(sub_node);

    ui::tree_updates updates;

    updates = ui::tree_updates{};
    ui::renderable_node::cast(node)->clear_updates();

    ui::renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = ui::tree_updates{};
    ui::renderable_node::cast(node)->clear_updates();

    node->angle()->set_value({1.0f});
    ui::renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::geometry));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    ui::renderable_node::cast(node)->clear_updates();

    mesh->set_use_mesh_color(true);
    ui::renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertEqual(updates.mesh_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_updates.test(ui::mesh_update_reason::use_mesh_color));
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    ui::renderable_node::cast(node)->clear_updates();

    mesh_data->set_vertex_count(1);
    ui::renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertEqual(updates.mesh_data_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_data_updates.test(ui::mesh_data_update_reason::vertex_count));

    updates = ui::tree_updates{};
    ui::renderable_node::cast(node)->clear_updates();

    sub_node->is_enabled()->set_value(false);
    ui::renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::enabled));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());
}

- (void)test_fetch_updates_when_enabled_changed {
    auto node = ui::node::make_shared();

    ui::tree_updates updates;

    updates = ui::tree_updates{};
    ui::renderable_node::cast(node)->clear_updates();
    ui::renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = ui::tree_updates{};
    ui::renderable_node::cast(node)->clear_updates();

    // nodeのパラメータを変更する
    node->mesh()->set_value(ui::mesh::make_shared());
    auto mesh_data = ui::dynamic_mesh_data::make_shared({.vertex_count = 2, .index_count = 2});
    mesh_data->set_vertex_count(1);
    node->mesh()->value()->set_mesh_data(mesh_data);

    node->angle()->set_value({1.0f});
    node->is_enabled()->set_value(false);
    node->collider()->set_value(ui::collider::make_shared());
    node->batch()->set_value(ui::batch::make_shared());

    auto sub_node = ui::node::make_shared();
    node->add_sub_node(sub_node);

    // enabledがfalseの時はenabled以外の変更はフェッチされない
    ui::renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::enabled));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    ui::renderable_node::cast(node)->clear_updates();

    node->is_enabled()->set_value(true);

    // enabledをtrueにするとフェッチされる
    ui::renderable_node::cast(node)->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 6);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::enabled));
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::children));
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::geometry));
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::mesh));
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::collider));
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::batch));
    XCTAssertTrue(updates.mesh_updates.flags.any());
    XCTAssertTrue(updates.mesh_data_updates.flags.any());
}

- (void)test_is_rendering_color_exists {
    auto node = ui::node::make_shared();

    XCTAssertFalse(ui::renderable_node::cast(node)->is_rendering_color_exists());

    auto mesh = ui::mesh::make_shared();
    mesh->set_mesh_data(ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1}));
    node->mesh()->set_value(mesh);

    XCTAssertTrue(ui::renderable_node::cast(node)->is_rendering_color_exists());

    node->mesh()->set_value(nullptr);
    auto sub_node = ui::node::make_shared();
    sub_node->mesh()->set_value(mesh);
    node->add_sub_node(sub_node);

    XCTAssertTrue(ui::renderable_node::cast(node)->is_rendering_color_exists());

    node->is_enabled()->set_value(false);

    XCTAssertFalse(ui::renderable_node::cast(node)->is_rendering_color_exists());
}

- (void)test_metal_setup {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto root_mesh = ui::mesh::make_shared();
    auto root_mesh_data = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    root_mesh->set_mesh_data(root_mesh_data);

    auto sub_mesh = ui::mesh::make_shared();
    auto sub_mesh_data = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    sub_mesh->set_mesh_data(sub_mesh_data);

    auto root_node = ui::node::make_shared();
    root_node->mesh()->set_value(root_mesh);

    auto sub_node = ui::node::make_shared();
    sub_node->mesh()->set_value(sub_mesh);
    root_node->add_sub_node(sub_node);

    XCTAssertFalse(root_mesh_data->metal_system());
    XCTAssertFalse(sub_mesh_data->metal_system());

    XCTAssertTrue(ui::metal_object::cast(root_node)->metal_setup(metal_system));

    XCTAssertTrue(root_mesh_data->metal_system());
    XCTAssertTrue(sub_mesh_data->metal_system());
}

- (void)test_build_render_info_smoke {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto node = ui::node::make_shared();
    auto sub_node = ui::node::make_shared();
    auto batch_node = ui::node::make_shared();
    auto batch_sub_node = ui::node::make_shared();

    auto const mesh_data = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    auto const sub_mesh_data = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    auto const batch_sub_mesh_data = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});

    node->collider()->set_value(ui::collider::make_shared(ui::shape::make_shared(ui::circle_shape{})));
    auto const mesh = ui::mesh::make_shared();
    node->mesh()->set_value(mesh);
    mesh->set_mesh_data(mesh_data);

    auto const sub_mesh = ui::mesh::make_shared();
    sub_node->mesh()->set_value(sub_mesh);
    sub_mesh->set_mesh_data(sub_mesh_data);

    batch_node->batch()->set_value(ui::batch::make_shared());
    batch_node->add_sub_node(batch_sub_node);

    auto const batch_sub_mesh = ui::mesh::make_shared();
    batch_sub_node->mesh()->set_value(batch_sub_mesh);
    batch_sub_mesh->set_mesh_data(batch_sub_mesh_data);

    node->add_sub_node(sub_node);
    node->add_sub_node(batch_node);

    ui::metal_object::cast(node)->metal_setup(metal_system);

    auto detector = ui::detector::make_shared();
    auto render_encoder = test::test_render_encoder::make_shared();

    ui::render_info render_info{.detector = detector,
                                .render_encodable = ui::render_encodable::cast(render_encoder),
                                .matrix = matrix_identity_float4x4,
                                .mesh_matrix = matrix_identity_float4x4};

    ui::renderable_node::cast(node)->build_render_info(render_info);

    XCTAssertEqual(render_encoder->meshes().size(), 3);
    XCTAssertEqual(render_encoder->meshes().at(0), mesh);
    XCTAssertEqual(render_encoder->meshes().at(1), sub_mesh);
}

- (void)test_local_matrix {
    auto node = ui::node::make_shared();
    node->set_position(ui::point{10.0f, -20.0f});
    node->scale()->set_value(ui::size{2.0f, 0.5f});
    node->angle()->set_value({90.0f});

    simd::float4x4 expected_matrix = ui::matrix::translation(node->position().x, node->position().y) *
                                     ui::matrix::rotation(node->angle()->value().degrees) *
                                     ui::matrix::scale(node->scale()->value().width, node->scale()->value().height);

    XCTAssertTrue(is_equal(node->local_matrix(), expected_matrix));
}

- (void)test_convert_position {
    auto node = ui::node::make_shared();
    auto sub_node = ui::node::make_shared();
    node->add_sub_node(sub_node);
    node->set_position({-1.0f, -1.0f});
    node->scale()->set_value({1.0f / 200.0f, 1.0f / 100.0f});

    auto converted_position = sub_node->convert_position({1.0f, -0.5f});
    XCTAssertEqualWithAccuracy(converted_position.x, 400.0f, 0.001f);
    XCTAssertEqualWithAccuracy(converted_position.y, 50.0f, 0.001f);
}

- (void)test_matrix {
    auto root_node = ui::node::make_shared();
    root_node->set_position(ui::point{10.0f, -20.0f});
    root_node->scale()->set_value(ui::size{2.0f, 0.5f});
    root_node->angle()->set_value({90.0f});

    auto sub_node = ui::node::make_shared();
    sub_node->set_position(ui::point{-50.0f, 10.0f});
    sub_node->scale()->set_value(ui::size{0.25f, 3.0f});
    sub_node->angle()->set_value({-45.0f});

    root_node->add_sub_node(sub_node);

    simd::float4x4 root_local_matrix =
        ui::matrix::translation(root_node->position().x, root_node->position().y) *
        ui::matrix::rotation(root_node->angle()->value().degrees) *
        ui::matrix::scale(root_node->scale()->value().width, root_node->scale()->value().height);
    simd::float4x4 sub_local_matrix =
        ui::matrix::translation(sub_node->position().x, sub_node->position().y) *
        ui::matrix::rotation(sub_node->angle()->value().degrees) *
        ui::matrix::scale(sub_node->scale()->value().width, sub_node->scale()->value().height);
    simd::float4x4 expected_matrix = root_local_matrix * sub_local_matrix;

    XCTAssertTrue(is_equal(sub_node->matrix(), expected_matrix));
}

- (void)test_set_renderer_recursively {
    auto renderer = ui::renderer::make_shared();

    auto node = ui::node::make_shared();
    auto sub_node = ui::node::make_shared();
    node->add_sub_node(sub_node);

    renderer->root_node()->add_sub_node(node);

    XCTAssertTrue(node->renderer());
    XCTAssertTrue(sub_node->renderer());
}

- (void)test_node_method_to_string {
    XCTAssertEqual(to_string(ui::node::method::added_to_super), "added_to_super");
    XCTAssertEqual(to_string(ui::node::method::removed_from_super), "removed_from_super");
}

- (void)test_node_update_reason_to_string {
    XCTAssertEqual(to_string(ui::node_update_reason::geometry), "geometry");
    XCTAssertEqual(to_string(ui::node_update_reason::mesh), "mesh");
    XCTAssertEqual(to_string(ui::node_update_reason::collider), "collider");
    XCTAssertEqual(to_string(ui::node_update_reason::enabled), "enabled");
    XCTAssertEqual(to_string(ui::node_update_reason::children), "children");
    XCTAssertEqual(to_string(ui::node_update_reason::batch), "batch");
    XCTAssertEqual(to_string(ui::node_update_reason::count), "count");
}

- (void)test_node_method_ostream {
    auto const methods = {ui::node::method::added_to_super, ui::node::method::removed_from_super};

    for (auto const &method : methods) {
        std::ostringstream stream;
        stream << method;
        XCTAssertEqual(stream.str(), to_string(method));
    }
}

- (void)test_node_update_reason_ostream {
    auto const reasons = {ui::node_update_reason::geometry, ui::node_update_reason::mesh,
                          ui::node_update_reason::collider, ui::node_update_reason::enabled,
                          ui::node_update_reason::children, ui::node_update_reason::batch,
                          ui::node_update_reason::count};

    for (auto const &reason : reasons) {
        std::ostringstream stream;
        stream << reason;
        XCTAssertEqual(stream.str(), to_string(reason));
    }
}

- (void)test_attach_x_layout_guide {
    auto x_guide = ui::layout_guide::make_shared(-1.0f);

    auto node = ui::node::make_shared();
    node->attach_x_layout_guide(*x_guide);

    XCTAssertEqual(node->position().x, -1.0f);

    x_guide->set_value(1.0f);

    XCTAssertEqual(node->position().x, 1.0f);
}

- (void)test_attach_y_layout_guide {
    auto y_guide = ui::layout_guide::make_shared(-1.0f);

    auto node = ui::node::make_shared();
    node->attach_y_layout_guide(*y_guide);

    XCTAssertEqual(node->position().y, -1.0f);

    y_guide->set_value(1.0f);

    XCTAssertEqual(node->position().y, 1.0f);
}

- (void)test_attach_position_layout_guide {
    auto guide_point = ui::layout_guide_point::make_shared({-1.0f, -2.0f});

    auto node = ui::node::make_shared();
    node->attach_position_layout_guides(*guide_point);

    XCTAssertTrue(node->position() == (ui::point{-1.0f, -2.0f}));

    guide_point->set_point({1.0f, 2.0f});

    XCTAssertTrue(node->position() == (ui::point{1.0f, 2.0f}));
}

- (void)test_render_batch {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto parent_batch_node = ui::node::make_shared();
    auto child_batch_node1 = ui::node::make_shared();
    auto child_batch_node2 = ui::node::make_shared();
    auto mesh_node1a = ui::node::make_shared();
    auto mesh_node1b = ui::node::make_shared();
    auto mesh_node2 = ui::node::make_shared();

    auto parent_batch = ui::batch::make_shared();
    parent_batch_node->batch()->set_value(parent_batch);

    auto child_batch1 = ui::batch::make_shared();
    child_batch_node1->batch()->set_value(child_batch1);
    auto child_batch2 = ui::batch::make_shared();
    child_batch_node2->batch()->set_value(child_batch2);

    auto mesh1a = ui::mesh::make_shared();
    mesh1a->set_color({0.5f, 0.5f, 0.5f, 0.5f});
    auto mesh_data1a = ui::dynamic_mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data1a->write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 1.0f;
        vertex.position.y = 2.0f;
        vertex.tex_coord.x = 3.0f;
        vertex.tex_coord.y = 4.0f;

        auto &index = indices.at(0);
        index = 0;
    });
    mesh1a->set_mesh_data(mesh_data1a);
    mesh_node1a->mesh()->set_value(mesh1a);
    mesh_node1a->color()->set_value(ui::color{.red = 0.5f, .green = 0.6f, .blue = 0.7f});
    mesh_node1a->alpha()->set_value(0.8f);

    auto mesh1b = ui::mesh::make_shared();
    mesh1b->set_use_mesh_color(true);
    auto mesh_data1b = ui::dynamic_mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data1b->write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
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

    auto texture1b = ui::texture::make_shared({.point_size = {.width = 1024, .height = 1024}});
    mesh1b->set_texture(texture1b);

    mesh_node1b->mesh()->set_value(mesh1b);

    auto mesh2 = ui::mesh::make_shared();
    mesh2->set_use_mesh_color(true);
    auto mesh_data2 = ui::dynamic_mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data2->write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
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

    auto texture2 = ui::texture::make_shared({.point_size = {.width = 1024, .height = 1024}});
    mesh2->set_texture(texture2);

    mesh_node2->mesh()->set_value(mesh2);

    parent_batch_node->add_sub_node(child_batch_node1);
    parent_batch_node->add_sub_node(child_batch_node2);
    child_batch_node1->add_sub_node(mesh_node1a);
    child_batch_node1->add_sub_node(mesh_node1b);
    child_batch_node2->add_sub_node(mesh_node2);

    auto render = [&parent_batch_node, &metal_system, self]() {
        auto detector = ui::detector::make_shared();
        auto render_encoder = test::test_render_encoder::make_shared();

        ui::render_info render_info{.detector = detector,
                                    .render_encodable = ui::render_encodable::cast(render_encoder),
                                    .matrix = matrix_identity_float4x4,
                                    .mesh_matrix = matrix_identity_float4x4};

        XCTAssertTrue(ui::metal_object::cast(parent_batch_node)->metal_setup(metal_system));

        ui::tree_updates parent_updates;
        ui::renderable_node::cast(parent_batch_node)->fetch_updates(parent_updates);
        XCTAssertTrue(parent_updates.is_any_updated());

        ui::renderable_node::cast(parent_batch_node)->build_render_info(render_info);

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

        ui::renderable_node::cast(parent_batch_node)->clear_updates();
    }

    {
        ui::tree_updates parent_updates;
        ui::renderable_node::cast(parent_batch_node)->fetch_updates(parent_updates);
        XCTAssertFalse(parent_updates.is_any_updated());
    }

    mesh_data1a->write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 1.5f;
        vertex.position.y = 2.5f;
        vertex.tex_coord.x = 3.5f;
        vertex.tex_coord.y = 4.5f;

        auto &index = indices.at(0);
        index = 2;
    });
    mesh_node1a->color()->set_value(ui::color{.red = 0.51f, .green = 0.61f, .blue = 0.71f});

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

        ui::renderable_node::cast(parent_batch_node)->clear_updates();
    }

    mesh_data1b->write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
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

        ui::renderable_node::cast(parent_batch_node)->clear_updates();
    }

    mesh_data2->write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
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

        ui::renderable_node::cast(parent_batch_node)->clear_updates();
    }

    mesh_node1b->is_enabled()->set_value(false);

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

        ui::renderable_node::cast(parent_batch_node)->clear_updates();
    }

    mesh_node1a->is_enabled()->set_value(false);
    mesh_node1b->is_enabled()->set_value(true);
    mesh_node2->is_enabled()->set_value(false);

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

        ui::renderable_node::cast(parent_batch_node)->clear_updates();
    }
}

- (void)test_render_batch_alpha_exists {
    auto device = objc_ptr_with_move_object(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    auto metal_system = ui::metal_system::make_shared(device.object());

    auto batch_node = ui::node::make_shared();
    batch_node->batch()->set_value(ui::batch::make_shared());

    auto mesh_node1 = ui::node::make_shared();
    batch_node->add_sub_node(mesh_node1);

    auto mesh1 = ui::mesh::make_shared();
    mesh1->set_use_mesh_color(false);
    auto mesh_data1 = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data1->write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 1.0f;
        vertex.position.y = 2.0f;

        auto &index = indices.at(0);
        index = 0;
    });
    mesh1->set_mesh_data(mesh_data1);
    mesh_node1->mesh()->set_value(mesh1);
    mesh_node1->color()->set_value(ui::color{.red = 0.1f, .green = 0.2f, .blue = 0.3f});
    mesh_node1->alpha()->set_value(0.0f);

    auto mesh_node2 = ui::node::make_shared();
    batch_node->add_sub_node(mesh_node2);

    auto mesh2 = ui::mesh::make_shared();
    mesh2->set_use_mesh_color(false);
    auto mesh_data2 = ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1});
    mesh_data2->write([](std::vector<ui::vertex2d_t> &vertices, std::vector<ui::index2d_t> &indices) {
        auto &vertex = vertices.at(0);
        vertex.position.x = 3.0f;
        vertex.position.y = 4.0f;

        auto &index = indices.at(0);
        index = 0;
    });
    mesh2->set_mesh_data(mesh_data2);
    mesh_node2->mesh()->set_value(mesh2);
    mesh_node2->color()->set_value(ui::color{.red = 0.5f, .green = 0.6f, .blue = 0.7f});
    mesh_node2->alpha()->set_value(1.0f);

    auto render = [&batch_node, &metal_system, self]() {
        auto detector = ui::detector::make_shared();
        auto render_encoder = test::test_render_encoder::make_shared();

        ui::render_info render_info{.detector = detector,
                                    .render_encodable = ui::render_encodable::cast(render_encoder),
                                    .matrix = matrix_identity_float4x4,
                                    .mesh_matrix = matrix_identity_float4x4};

        XCTAssertTrue(ui::metal_object::cast(batch_node)->metal_setup(metal_system));

        ui::tree_updates parent_updates;
        ui::renderable_node::cast(batch_node)->fetch_updates(parent_updates);
        XCTAssertTrue(parent_updates.is_any_updated());

        ui::renderable_node::cast(batch_node)->build_render_info(render_info);

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

        ui::renderable_node::cast(batch_node)->clear_updates();
    }

    mesh_node1->alpha()->set_value(0.5f);

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

        ui::renderable_node::cast(batch_node)->clear_updates();
    }

    mesh_node2->alpha()->set_value(0.0f);

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

        ui::renderable_node::cast(batch_node)->clear_updates();
    }

    mesh_node1->alpha()->set_value(0.0f);

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

        ui::renderable_node::cast(batch_node)->clear_updates();
    }
}

@end
