//
//  yas_ui_node_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import <sstream>
#import "yas_objc_ptr.h"
#import "yas_ui.h"
#import "yas_ui_angle.h"
#import "yas_ui_math.h"
#import "yas_ui_render_info.h"

using namespace yas;

namespace yas::test {
struct test_render_encoder : base {
    struct impl : base::impl, ui::render_encodable::impl {
        void append_mesh(ui::mesh &&mesh) {
            _meshes.emplace_back(std::move(mesh));
        }

        std::vector<ui::mesh> _meshes;
    };

    test_render_encoder() : base(std::make_shared<impl>()) {
    }

    ui::render_encodable encodable() {
        return ui::render_encodable{impl_ptr<ui::render_encodable::impl>()};
    }

    std::vector<ui::mesh> &meshes() {
        return impl_ptr<impl>()->_meshes;
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
    ui::node node;

    XCTAssertEqual(node.position().x, 0.0f);
    XCTAssertEqual(node.position().y, 0.0f);
    XCTAssertEqual(node.angle().degrees, 0.0f);
    XCTAssertEqual(node.scale().width, 1.0f);
    XCTAssertEqual(node.scale().height, 1.0f);

    XCTAssertEqual(node.color().red, 1.0f);
    XCTAssertEqual(node.color().green, 1.0f);
    XCTAssertEqual(node.color().blue, 1.0f);
    XCTAssertEqual(node.alpha(), 1.0f);

    XCTAssertFalse(node.mesh());
    XCTAssertFalse(node.collider());

    XCTAssertEqual(node.children().size(), 0);
    XCTAssertFalse(node.parent());
    XCTAssertFalse(node.renderer());

    XCTAssertTrue(node.is_enabled());

    XCTAssertTrue(node.renderable());
    XCTAssertTrue(node.metal());
}

- (void)test_create_null {
    ui::node node{nullptr};

    XCTAssertFalse(node);
}

- (void)test_set_variables {
    ui::node node;
    ui::mesh mesh;
    ui::collider collider;
    ui::batch batch;

    node.set_position({1.0f, 2.0f});
    node.set_angle({3.0f});
    node.set_scale({4.0f, 5.0f});
    node.set_color({0.1f, 0.2f, 0.3f});
    node.set_alpha(0.4f);

    node.set_enabled(true);

    XCTAssertEqual(node.position().x, 1.0f);
    XCTAssertEqual(node.position().y, 2.0f);
    XCTAssertEqual(node.angle().degrees, 3.0f);
    XCTAssertEqual(node.scale().width, 4.0f);
    XCTAssertEqual(node.scale().height, 5.0f);
    XCTAssertEqual(node.color().red, 0.1f);
    XCTAssertEqual(node.color().green, 0.2f);
    XCTAssertEqual(node.color().blue, 0.3f);
    XCTAssertEqual(node.alpha(), 0.4f);

    node.set_mesh(mesh);
    XCTAssertTrue(node.mesh());
    XCTAssertEqual(node.mesh(), mesh);

    node.set_collider(collider);
    XCTAssertTrue(node.collider());
    XCTAssertEqual(node.collider(), collider);

    node.set_batch(batch);
    XCTAssertTrue(node.batch());
    XCTAssertEqual(node.batch(), batch);

    node.set_batch(nullptr);
    XCTAssertFalse(node.batch());

    XCTAssertTrue(node.is_enabled());
}

- (void)test_const_variables {
    ui::node node;
    ui::node const &const_node = node;

    XCTAssertFalse(const_node.mesh());
    XCTAssertFalse(const_node.collider());
    XCTAssertFalse(const_node.batch());

    node.set_mesh(ui::mesh{});
    node.set_collider(ui::collider{});
    node.set_batch(ui::batch{});

    XCTAssertTrue(const_node.mesh());
    XCTAssertTrue(const_node.collider());
    XCTAssertEqual(const_node.children().size(), 0);
    XCTAssertTrue(const_node.batch());
}

- (void)set_color_to_mesh {
    ui::node node;
    ui::mesh mesh;

    XCTAssertEqual(mesh.color()[0], 1.0f);
    XCTAssertEqual(mesh.color()[1], 1.0f);
    XCTAssertEqual(mesh.color()[2], 1.0f);
    XCTAssertEqual(mesh.color()[3], 1.0f);

    node.set_color({0.25f, 0.5f, 0.75f});
    node.set_alpha(0.125f);

    node.set_mesh(mesh);

    XCTAssertEqual(mesh.color()[0], 0.25f);
    XCTAssertEqual(mesh.color()[1], 0.5f);
    XCTAssertEqual(mesh.color()[2], 0.75f);
    XCTAssertEqual(mesh.color()[3], 0.125f);

    node.set_color({0.1f, 0.2f, 0.3f});
    node.set_alpha(0.4f);

    XCTAssertEqual(mesh.color()[0], 0.1f);
    XCTAssertEqual(mesh.color()[1], 0.2f);
    XCTAssertEqual(mesh.color()[2], 0.3f);
    XCTAssertEqual(mesh.color()[3], 0.4f);
}

- (void)test_is_equal {
    ui::node node1;
    ui::node node1b = node1;
    ui::node node2;

    XCTAssertTrue(node1 == node1);
    XCTAssertTrue(node1 == node1b);
    XCTAssertFalse(node1 == node2);

    XCTAssertFalse(node1 != node1);
    XCTAssertFalse(node1 != node1b);
    XCTAssertTrue(node1 != node2);
}

- (void)test_hierarchie {
    ui::node parent_node;

    ui::node sub_node1;
    ui::node sub_node2;

    XCTAssertEqual(parent_node.children().size(), 0);
    XCTAssertFalse(sub_node1.parent());
    XCTAssertFalse(sub_node2.parent());

    parent_node.add_sub_node(sub_node1);

    XCTAssertEqual(parent_node.children().size(), 1);
    XCTAssertTrue(sub_node1.parent());

    parent_node.add_sub_node(sub_node2);

    XCTAssertEqual(parent_node.children().size(), 2);
    XCTAssertTrue(sub_node1.parent());
    XCTAssertTrue(sub_node2.parent());

    XCTAssertEqual(parent_node.children().at(0), sub_node1);
    XCTAssertEqual(parent_node.children().at(1), sub_node2);
    XCTAssertEqual(sub_node1.parent(), parent_node);
    XCTAssertEqual(sub_node2.parent(), parent_node);

    sub_node1.remove_from_super_node();

    XCTAssertEqual(parent_node.children().size(), 1);
    XCTAssertFalse(sub_node1.parent());
    XCTAssertTrue(sub_node2.parent());

    XCTAssertEqual(parent_node.children().at(0), sub_node2);

    sub_node2.remove_from_super_node();

    XCTAssertEqual(parent_node.children().size(), 0);
    XCTAssertFalse(sub_node2.parent());
}

- (void)test_add_sub_node_with_index {
    ui::node parent_node;

    ui::node sub_node1;
    ui::node sub_node2;
    ui::node sub_node3;

    parent_node.add_sub_node(sub_node1);
    parent_node.add_sub_node(sub_node3);
    parent_node.add_sub_node(sub_node2, 1);

    XCTAssertEqual(parent_node.children().at(0), sub_node1);
    XCTAssertEqual(parent_node.children().at(1), sub_node2);
    XCTAssertEqual(parent_node.children().at(2), sub_node3);
}

- (void)test_parent_changed_when_add_sub_node {
    ui::node parent_node1;
    ui::node parent_node2;

    ui::node sub_node;

    parent_node1.add_sub_node(sub_node);

    XCTAssertEqual(parent_node1.children().size(), 1);
    XCTAssertEqual(parent_node2.children().size(), 0);

    parent_node2.add_sub_node(sub_node);

    XCTAssertEqual(parent_node1.children().size(), 0);
    XCTAssertEqual(parent_node2.children().size(), 1);
}

- (void)test_renderable_node {
    ui::node node;
    ui::renderer renderer;

    auto &renderable = node.renderable();

    XCTAssertFalse(renderable.renderer());

    renderable.set_renderer(renderer);

    XCTAssertTrue(renderable.renderer());
    XCTAssertEqual(renderable.renderer(), renderer);
}

- (void)test_add_and_remove_node_observed {
    ui::node parent_node;
    ui::node sub_node;
    int observer_called_count = 0;
    bool added_to_super_called = false;
    bool removed_from_super_called = false;

    auto flow_added = sub_node.begin_flow(ui::node::method::added_to_super)
                          .perform([&observer_called_count, &added_to_super_called](auto const &pair) {
                              added_to_super_called = true;
                              ++observer_called_count;
                          })
                          .end();
    auto flow_removed = sub_node.begin_flow(ui::node::method::removed_from_super)
                            .perform([&observer_called_count, &removed_from_super_called](auto const &pair) {
                                removed_from_super_called = true;
                                ++observer_called_count;
                            })
                            .end();

    parent_node.add_sub_node(sub_node);

    XCTAssertTrue(added_to_super_called);

    sub_node.remove_from_super_node();

    XCTAssertTrue(removed_from_super_called);

    XCTAssertEqual(observer_called_count, 2);
}

- (void)test_begin_flow_with_method {
    {
        opt_t<ui::node::method> called;

        ui::node node;

        auto flow = node.begin_flow(ui::node::method::position_changed)
                        .perform([&called](auto const &pair) { called = pair.first; })
                        .end();

        node.set_position({1.0f, 2.0f});

        XCTAssertEqual(*called, ui::node::method::position_changed);
    }
}

- (void)test_begin_flow_with_methods {
    opt_t<ui::node::method> called;

    ui::node node;

    auto flow = node.begin_flow({ui::node::method::position_changed, ui::node::method::angle_changed})
                    .perform([&called](auto const &pair) { called = pair.first; })
                    .end();

    node.set_position({1.0f, 2.0f});

    XCTAssertTrue(called);
    XCTAssertEqual(*called, ui::node::method::position_changed);

    called = nullopt;

    node.set_angle({90.0f});

    XCTAssertTrue(called);
    XCTAssertEqual(*called, ui::node::method::angle_changed);

    called = nullopt;

    node.set_alpha(0.5f);

    XCTAssertFalse(called);
}

- (void)test_begin_renderer_flow {
    ui::renderer notified{nullptr};

    ui::node node;

    auto flow =
        node.begin_renderer_flow().perform([&notified](ui::renderer const &renderer) { notified = renderer; }).end();

    ui::renderer renderer;

    node.renderable().set_renderer(renderer);

    XCTAssertEqual(notified, renderer);

    node.renderable().set_renderer(nullptr);

    XCTAssertTrue(!notified);
}

- (void)test_fetch_updates {
    ui::node node;

    ui::mesh mesh;
    node.set_mesh(mesh);

    ui::dynamic_mesh_data mesh_data{{.vertex_count = 2, .index_count = 2}};
    mesh.set_mesh_data(mesh_data);

    ui::node sub_node;
    node.add_sub_node(sub_node);

    ui::tree_updates updates;

    updates = ui::tree_updates{};
    node.renderable().clear_updates();

    node.renderable().fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = ui::tree_updates{};
    node.renderable().clear_updates();

    node.set_angle({1.0f});
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::geometry));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    node.renderable().clear_updates();

    mesh.set_use_mesh_color(true);
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertEqual(updates.mesh_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_updates.test(ui::mesh_update_reason::use_mesh_color));
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    node.renderable().clear_updates();

    mesh_data.set_vertex_count(1);
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertFalse(updates.node_updates.flags.any());
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertEqual(updates.mesh_data_updates.flags.count(), 1);
    XCTAssertTrue(updates.mesh_data_updates.test(ui::mesh_data_update_reason::vertex_count));

    updates = ui::tree_updates{};
    node.renderable().clear_updates();

    sub_node.set_enabled(false);
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::enabled));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());
}

- (void)test_fetch_updates_when_enabled_changed {
    ui::node node;

    ui::tree_updates updates;

    updates = ui::tree_updates{};
    node.renderable().clear_updates();
    node.renderable().fetch_updates(updates);
    XCTAssertFalse(updates.is_any_updated());

    updates = ui::tree_updates{};
    node.renderable().clear_updates();

    // nodeのパラメータを変更する
    node.set_mesh(ui::mesh{});
    ui::dynamic_mesh_data mesh_data{{.vertex_count = 2, .index_count = 2}};
    mesh_data.set_vertex_count(1);
    node.mesh().set_mesh_data(mesh_data);

    node.set_angle({1.0f});
    node.set_enabled(false);
    node.set_collider(ui::collider{});
    node.set_batch(ui::batch{});

    ui::node sub_node;
    node.add_sub_node(sub_node);

    // enabledがfalseの時はenabled以外の変更はフェッチされない
    node.renderable().fetch_updates(updates);
    XCTAssertTrue(updates.is_any_updated());
    XCTAssertEqual(updates.node_updates.flags.count(), 1);
    XCTAssertTrue(updates.node_updates.test(ui::node_update_reason::enabled));
    XCTAssertFalse(updates.mesh_updates.flags.any());
    XCTAssertFalse(updates.mesh_data_updates.flags.any());

    updates = ui::tree_updates{};
    node.renderable().clear_updates();

    node.set_enabled(true);

    // enabledをtrueにするとフェッチされる
    node.renderable().fetch_updates(updates);
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
    ui::node node;

    XCTAssertFalse(node.renderable().is_rendering_color_exists());

    ui::mesh mesh;
    mesh.set_mesh_data(ui::mesh_data{{.vertex_count = 1, .index_count = 1}});
    node.set_mesh(mesh);

    XCTAssertTrue(node.renderable().is_rendering_color_exists());

    node.set_mesh(nullptr);
    ui::node sub_node;
    sub_node.set_mesh(mesh);
    node.add_sub_node(sub_node);

    XCTAssertTrue(node.renderable().is_rendering_color_exists());

    node.set_enabled(false);

    XCTAssertFalse(node.renderable().is_rendering_color_exists());
}

- (void)test_metal_setup {
    auto device = make_objc_ptr(MTLCreateSystemDefaultDevice());
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    ui::metal_system metal_system{device.object()};

    ui::mesh root_mesh;
    ui::mesh_data root_mesh_data{{.vertex_count = 1, .index_count = 1}};
    root_mesh.set_mesh_data(root_mesh_data);

    ui::mesh sub_mesh;
    ui::mesh_data sub_mesh_data{{.vertex_count = 1, .index_count = 1}};
    sub_mesh.set_mesh_data(sub_mesh_data);

    ui::node root_node;
    root_node.set_mesh(root_mesh);

    ui::node sub_node;
    sub_node.set_mesh(sub_mesh);
    root_node.add_sub_node(sub_node);

    XCTAssertFalse(root_mesh_data.metal_system());
    XCTAssertFalse(sub_mesh_data.metal_system());

    XCTAssertTrue(root_node.metal().metal_setup(metal_system));

    XCTAssertTrue(root_mesh_data.metal_system());
    XCTAssertTrue(sub_mesh_data.metal_system());
}

- (void)test_build_render_info_smoke {
    ui::node node;
    ui::node sub_node;
    ui::node batch_node;
    ui::node batch_sub_node;

    node.set_collider(ui::collider{ui::shape{ui::circle_shape{}}});
    node.set_mesh(ui::mesh{});

    sub_node.set_mesh(ui::mesh{});

    batch_node.set_batch(ui::batch{});
    batch_node.add_sub_node(batch_sub_node);

    batch_sub_node.set_mesh(ui::mesh{});

    node.add_sub_node(sub_node);
    node.add_sub_node(batch_node);

    ui::detector detector;
    test::test_render_encoder render_encoder;

    ui::render_info render_info{.detector = detector,
                                .render_encodable = render_encoder.encodable(),
                                .matrix = matrix_identity_float4x4,
                                .mesh_matrix = matrix_identity_float4x4};

    node.renderable().build_render_info(render_info);

    XCTAssertEqual(render_encoder.meshes().size(), 3);
    XCTAssertEqual(render_encoder.meshes().at(0), node.mesh());
}

- (void)test_local_matrix {
    ui::node node;
    node.set_position(ui::point{10.0f, -20.0f});
    node.set_scale(ui::size{2.0f, 0.5f});
    node.set_angle({90.0f});

    simd::float4x4 expected_matrix = ui::matrix::translation(node.position().x, node.position().y) *
                                     ui::matrix::rotation(node.angle().degrees) *
                                     ui::matrix::scale(node.scale().width, node.scale().height);

    XCTAssertTrue(is_equal(node.local_matrix(), expected_matrix));
}

- (void)test_convert_position {
    ui::node node;
    ui::node sub_node;
    node.add_sub_node(sub_node);
    node.set_position({-1.0f, -1.0f});
    node.set_scale({1.0f / 200.0f, 1.0f / 100.0f});

    auto converted_position = sub_node.convert_position({1.0f, -0.5f});
    XCTAssertEqualWithAccuracy(converted_position.x, 400.0f, 0.001f);
    XCTAssertEqualWithAccuracy(converted_position.y, 50.0f, 0.001f);
}

- (void)test_matrix {
    ui::node root_node;
    root_node.set_position(ui::point{10.0f, -20.0f});
    root_node.set_scale(ui::size{2.0f, 0.5f});
    root_node.set_angle({90.0f});

    ui::node sub_node;
    sub_node.set_position(ui::point{-50.0f, 10.0f});
    sub_node.set_scale(ui::size{0.25f, 3.0f});
    sub_node.set_angle({-45.0f});

    root_node.add_sub_node(sub_node);

    simd::float4x4 root_local_matrix = ui::matrix::translation(root_node.position().x, root_node.position().y) *
                                       ui::matrix::rotation(root_node.angle().degrees) *
                                       ui::matrix::scale(root_node.scale().width, root_node.scale().height);
    simd::float4x4 sub_local_matrix = ui::matrix::translation(sub_node.position().x, sub_node.position().y) *
                                      ui::matrix::rotation(sub_node.angle().degrees) *
                                      ui::matrix::scale(sub_node.scale().width, sub_node.scale().height);
    simd::float4x4 expected_matrix = root_local_matrix * sub_local_matrix;

    XCTAssertTrue(is_equal(sub_node.matrix(), expected_matrix));
}

- (void)test_set_renderer_recursively {
    ui::renderer renderer{};

    ui::node node;
    ui::node sub_node;
    node.add_sub_node(sub_node);

    renderer.root_node().add_sub_node(node);

    XCTAssertTrue(node.renderer());
    XCTAssertTrue(sub_node.renderer());
}

- (void)test_node_method_to_string {
    XCTAssertEqual(to_string(ui::node::method::added_to_super), "added_to_super");
    XCTAssertEqual(to_string(ui::node::method::removed_from_super), "removed_from_super");
    XCTAssertEqual(to_string(ui::node::method::parent_changed), "parent_changed");
    XCTAssertEqual(to_string(ui::node::method::renderer_changed), "renderer_changed");
    XCTAssertEqual(to_string(ui::node::method::position_changed), "position_changed");
    XCTAssertEqual(to_string(ui::node::method::angle_changed), "angle_changed");
    XCTAssertEqual(to_string(ui::node::method::scale_changed), "scale_changed");
    XCTAssertEqual(to_string(ui::node::method::color_changed), "color_changed");
    XCTAssertEqual(to_string(ui::node::method::alpha_changed), "alpha_changed");
    XCTAssertEqual(to_string(ui::node::method::mesh_changed), "mesh_changed");
    XCTAssertEqual(to_string(ui::node::method::collider_changed), "collider_changed");
    XCTAssertEqual(to_string(ui::node::method::enabled_changed), "enabled_changed");
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
    auto const methods = {
        ui::node::method::added_to_super,   ui::node::method::removed_from_super, ui::node::method::parent_changed,
        ui::node::method::renderer_changed, ui::node::method::position_changed,   ui::node::method::angle_changed,
        ui::node::method::scale_changed,    ui::node::method::color_changed,      ui::node::method::alpha_changed,
        ui::node::method::mesh_changed,     ui::node::method::collider_changed,   ui::node::method::enabled_changed};

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
    ui::layout_guide x_guide{-1.0f};

    ui::node node;
    node.attach_x_layout_guide(x_guide);

    XCTAssertEqual(node.position().x, -1.0f);

    x_guide.set_value(1.0f);

    XCTAssertEqual(node.position().x, 1.0f);
}

- (void)test_attach_y_layout_guide {
    ui::layout_guide y_guide{-1.0f};

    ui::node node;
    node.attach_y_layout_guide(y_guide);

    XCTAssertEqual(node.position().y, -1.0f);

    y_guide.set_value(1.0f);

    XCTAssertEqual(node.position().y, 1.0f);
}

- (void)test_attach_position_layout_guide {
    ui::layout_guide_point guide_point{{-1.0f, -2.0f}};

    ui::node node;
    node.attach_position_layout_guides(guide_point);

    XCTAssertTrue(node.position() == (ui::point{-1.0f, -2.0f}));

    guide_point.set_point({1.0f, 2.0f});

    XCTAssertTrue(node.position() == (ui::point{1.0f, 2.0f}));
}

@end
