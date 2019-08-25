//
//  yas_ui_node_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_objc_ptr.h>
#import <ui/yas_ui_angle.h>
#import <ui/yas_ui_math.h>
#import <ui/yas_ui_render_info.h>
#import <ui/yas_ui_umbrella.h>
#import <iostream>
#import <sstream>

using namespace yas;

namespace yas::test {
struct test_render_encoder : ui::render_encodable, std::enable_shared_from_this<test_render_encoder> {
    ui::render_encodable_ptr encodable() {
        return std::dynamic_pointer_cast<ui::render_encodable>(shared_from_this());
    }

    std::vector<ui::mesh_ptr> const &meshes() {
        return this->_meshes;
    }

    void append_mesh(ui::mesh_ptr const &mesh) override {
        _meshes.emplace_back(mesh);
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

    XCTAssertEqual(node->position()->raw().x, 0.0f);
    XCTAssertEqual(node->position()->raw().y, 0.0f);
    XCTAssertEqual(node->angle()->raw().degrees, 0.0f);
    XCTAssertEqual(node->scale()->raw().width, 1.0f);
    XCTAssertEqual(node->scale()->raw().height, 1.0f);

    XCTAssertEqual(node->color()->raw().red, 1.0f);
    XCTAssertEqual(node->color()->raw().green, 1.0f);
    XCTAssertEqual(node->color()->raw().blue, 1.0f);
    XCTAssertEqual(node->alpha()->raw(), 1.0f);

    XCTAssertFalse(node->mesh()->raw());
    XCTAssertFalse(node->collider()->raw());
    XCTAssertFalse(node->render_target()->raw());

    XCTAssertEqual(node->children().size(), 0);
    XCTAssertFalse(node->parent());
    XCTAssertFalse(node->renderer());

    XCTAssertTrue(node->is_enabled()->raw());

    XCTAssertTrue(node->renderable());
    XCTAssertTrue(node->metal());
}

- (void)test_set_variables {
    auto node = ui::node::make_shared();
    auto mesh = ui::mesh::make_shared();
    auto collider = ui::collider::make_shared();
    std::shared_ptr<ui::batch> batch = ui::batch::make_shared();
    auto render_target = ui::render_target::make_shared();

    node->position()->set_value({1.0f, 2.0f});
    node->angle()->set_value({3.0f});
    node->scale()->set_value({4.0f, 5.0f});
    node->color()->set_value({0.1f, 0.2f, 0.3f});
    node->alpha()->set_value(0.4f);

    node->is_enabled()->set_value(true);

    XCTAssertEqual(node->position()->raw().x, 1.0f);
    XCTAssertEqual(node->position()->raw().y, 2.0f);
    XCTAssertEqual(node->angle()->raw().degrees, 3.0f);
    XCTAssertEqual(node->scale()->raw().width, 4.0f);
    XCTAssertEqual(node->scale()->raw().height, 5.0f);
    XCTAssertEqual(node->color()->raw().red, 0.1f);
    XCTAssertEqual(node->color()->raw().green, 0.2f);
    XCTAssertEqual(node->color()->raw().blue, 0.3f);
    XCTAssertEqual(node->alpha()->raw(), 0.4f);

    node->mesh()->set_value(mesh);
    XCTAssertTrue(node->mesh()->raw());
    XCTAssertEqual(node->mesh()->raw(), mesh);

    node->collider()->set_value(collider);
    XCTAssertTrue(node->collider()->raw());
    XCTAssertEqual(node->collider()->raw(), collider);

    node->batch()->set_value(batch);
    XCTAssertTrue(node->batch()->raw());
    XCTAssertEqual(node->batch()->raw(), batch);

    node->batch()->set_value(nullptr);
    XCTAssertFalse(node->batch()->raw());

    XCTAssertTrue(node->is_enabled()->raw());

    node->render_target()->set_value(render_target);
    XCTAssertTrue(node->render_target()->raw());
    XCTAssertEqual(node->render_target()->raw(), render_target);

    node->render_target()->set_value(nullptr);
}

- (void)test_const_variables {
#warning 要チェック
    auto node = ui::node::make_shared();
    ui::node_ptr const &const_node = node;

    XCTAssertFalse(const_node->mesh()->raw());
    XCTAssertFalse(const_node->collider()->raw());
    XCTAssertFalse(const_node->batch()->raw());

    node->mesh()->set_value(ui::mesh::make_shared());
    node->collider()->set_value(ui::collider::make_shared());
    node->batch()->set_value(ui::batch::make_shared());

    XCTAssertTrue(const_node->mesh()->raw());
    XCTAssertTrue(const_node->collider()->raw());
    XCTAssertEqual(const_node->children().size(), 0);
    XCTAssertTrue(const_node->batch()->raw());
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

    auto const renderable = node->renderable();

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

    auto added_observer = sub_node->chain(ui::node::method::added_to_super)
                              .perform([&observer_called_count, &added_to_super_called](auto const &pair) {
                                  added_to_super_called = true;
                                  ++observer_called_count;
                              })
                              .end();
    auto remove_observer = sub_node->chain(ui::node::method::removed_from_super)
                               .perform([&observer_called_count, &removed_from_super_called](auto const &pair) {
                                   removed_from_super_called = true;
                                   ++observer_called_count;
                               })
                               .end();

    parent_node->add_sub_node(sub_node);

    XCTAssertTrue(added_to_super_called);

    sub_node->remove_from_super_node();

    XCTAssertTrue(removed_from_super_called);

    XCTAssertEqual(observer_called_count, 2);
}

- (void)test_chain_with_methods {
    std::optional<ui::node::method> called;

    auto node = ui::node::make_shared();

    auto observer = node->chain({ui::node::method::added_to_super, ui::node::method::removed_from_super})
                        .perform([&called](auto const &pair) { called = pair.first; })
                        .end();

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
        node->chain_renderer().perform([&notified](ui::renderer_ptr const &renderer) { notified = renderer; }).end();

    auto renderer = ui::renderer::make_shared();

    node->renderable()->set_renderer(renderer);

    XCTAssertEqual(notified, renderer);

    node->renderable()->set_renderer(nullptr);

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
    node->renderable()->clear_updates();

    node->renderable()->fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = ui::tree_updates{};
    node->renderable()->clear_updates();

    node->angle()->set_value({1.0f});
    node->renderable()->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::geometry));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    node->renderable()->clear_updates();

    mesh->set_use_mesh_color(true);
    node->renderable()->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertEqual(updates.mesh_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_updates.test(ui::mesh_update_reason::use_mesh_color));
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    node->renderable()->clear_updates();

    mesh_data->set_vertex_count(1);
    node->renderable()->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertEqual(updates.mesh_data_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_data_updates.test(ui::mesh_data_update_reason::vertex_count));

    updates = ui::tree_updates{};
    node->renderable()->clear_updates();

    sub_node->is_enabled()->set_value(false);
    node->renderable()->fetch_updates(updates);
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
    node->renderable()->clear_updates();
    node->renderable()->fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = ui::tree_updates{};
    node->renderable()->clear_updates();

    // nodeのパラメータを変更する
    node->mesh()->set_value(ui::mesh::make_shared());
    auto mesh_data = ui::dynamic_mesh_data::make_shared({.vertex_count = 2, .index_count = 2});
    mesh_data->set_vertex_count(1);
    node->mesh()->raw()->set_mesh_data(mesh_data);

    node->angle()->set_value({1.0f});
    node->is_enabled()->set_value(false);
    node->collider()->set_value(ui::collider::make_shared());
    node->batch()->set_value(ui::batch::make_shared());

    auto sub_node = ui::node::make_shared();
    node->add_sub_node(sub_node);

    // enabledがfalseの時はenabled以外の変更はフェッチされない
    node->renderable()->fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::enabled));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    node->renderable()->clear_updates();

    node->is_enabled()->set_value(true);

    // enabledをtrueにするとフェッチされる
    node->renderable()->fetch_updates(updates);
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

    XCTAssertFalse(node->renderable()->is_rendering_color_exists());

    auto mesh = ui::mesh::make_shared();
    mesh->set_mesh_data(ui::mesh_data::make_shared({.vertex_count = 1, .index_count = 1}));
    node->mesh()->set_value(mesh);

    XCTAssertTrue(node->renderable()->is_rendering_color_exists());

    node->mesh()->set_value(nullptr);
    auto sub_node = ui::node::make_shared();
    sub_node->mesh()->set_value(mesh);
    node->add_sub_node(sub_node);

    XCTAssertTrue(node->renderable()->is_rendering_color_exists());

    node->is_enabled()->set_value(false);

    XCTAssertFalse(node->renderable()->is_rendering_color_exists());
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

    XCTAssertTrue(root_node->metal()->metal_setup(metal_system));

    XCTAssertTrue(root_mesh_data->metal_system());
    XCTAssertTrue(sub_mesh_data->metal_system());
}

- (void)test_build_render_info_smoke {
    auto node = ui::node::make_shared();
    auto sub_node = ui::node::make_shared();
    auto batch_node = ui::node::make_shared();
    auto batch_sub_node = ui::node::make_shared();

    node->collider()->set_value(ui::collider::make_shared(ui::shape::make_shared(ui::circle_shape{})));
    node->mesh()->set_value(ui::mesh::make_shared());

    sub_node->mesh()->set_value(ui::mesh::make_shared());

    batch_node->batch()->set_value(ui::batch::make_shared());
    batch_node->add_sub_node(batch_sub_node);

    batch_sub_node->mesh()->set_value(ui::mesh::make_shared());

    node->add_sub_node(sub_node);
    node->add_sub_node(batch_node);

    auto detector = ui::detector::make_shared();
    auto render_encoder = test::test_render_encoder::make_shared();

    ui::render_info render_info{.detector = detector,
                                .render_encodable = render_encoder->encodable(),
                                .matrix = matrix_identity_float4x4,
                                .mesh_matrix = matrix_identity_float4x4};

    node->renderable()->build_render_info(render_info);

    XCTAssertEqual(render_encoder->meshes().size(), 3);
    XCTAssertEqual(render_encoder->meshes().at(0), node->mesh()->raw());
}

- (void)test_local_matrix {
    auto node = ui::node::make_shared();
    node->position()->set_value(ui::point{10.0f, -20.0f});
    node->scale()->set_value(ui::size{2.0f, 0.5f});
    node->angle()->set_value({90.0f});

    simd::float4x4 expected_matrix = ui::matrix::translation(node->position()->raw().x, node->position()->raw().y) *
                                     ui::matrix::rotation(node->angle()->raw().degrees) *
                                     ui::matrix::scale(node->scale()->raw().width, node->scale()->raw().height);

    XCTAssertTrue(is_equal(node->local_matrix(), expected_matrix));
}

- (void)test_convert_position {
    auto node = ui::node::make_shared();
    auto sub_node = ui::node::make_shared();
    node->add_sub_node(sub_node);
    node->position()->set_value({-1.0f, -1.0f});
    node->scale()->set_value({1.0f / 200.0f, 1.0f / 100.0f});

    auto converted_position = sub_node->convert_position({1.0f, -0.5f});
    XCTAssertEqualWithAccuracy(converted_position.x, 400.0f, 0.001f);
    XCTAssertEqualWithAccuracy(converted_position.y, 50.0f, 0.001f);
}

- (void)test_matrix {
    auto root_node = ui::node::make_shared();
    root_node->position()->set_value(ui::point{10.0f, -20.0f});
    root_node->scale()->set_value(ui::size{2.0f, 0.5f});
    root_node->angle()->set_value({90.0f});

    auto sub_node = ui::node::make_shared();
    sub_node->position()->set_value(ui::point{-50.0f, 10.0f});
    sub_node->scale()->set_value(ui::size{0.25f, 3.0f});
    sub_node->angle()->set_value({-45.0f});

    root_node->add_sub_node(sub_node);

    simd::float4x4 root_local_matrix =
        ui::matrix::translation(root_node->position()->raw().x, root_node->position()->raw().y) *
        ui::matrix::rotation(root_node->angle()->raw().degrees) *
        ui::matrix::scale(root_node->scale()->raw().width, root_node->scale()->raw().height);
    simd::float4x4 sub_local_matrix =
        ui::matrix::translation(sub_node->position()->raw().x, sub_node->position()->raw().y) *
        ui::matrix::rotation(sub_node->angle()->raw().degrees) *
        ui::matrix::scale(sub_node->scale()->raw().width, sub_node->scale()->raw().height);
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

    XCTAssertEqual(node->position()->raw().x, -1.0f);

    x_guide->set_value(1.0f);

    XCTAssertEqual(node->position()->raw().x, 1.0f);
}

- (void)test_attach_y_layout_guide {
    auto y_guide = ui::layout_guide::make_shared(-1.0f);

    auto node = ui::node::make_shared();
    node->attach_y_layout_guide(*y_guide);

    XCTAssertEqual(node->position()->raw().y, -1.0f);

    y_guide->set_value(1.0f);

    XCTAssertEqual(node->position()->raw().y, 1.0f);
}

- (void)test_attach_position_layout_guide {
    auto guide_point = ui::layout_guide_point::make_shared({-1.0f, -2.0f});

    auto node = ui::node::make_shared();
    node->attach_position_layout_guides(*guide_point);

    XCTAssertTrue(node->position()->raw() == (ui::point{-1.0f, -2.0f}));

    guide_point->set_point({1.0f, 2.0f});

    XCTAssertTrue(node->position()->raw() == (ui::point{1.0f, 2.0f}));
}

@end
