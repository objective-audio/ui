//
//  yas_ui_fixed_colleciton_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;

@interface yas_ui_collection_layout_tests : XCTestCase

@end

@implementation yas_ui_collection_layout_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    auto layout = ui::collection_layout::make_shared();

    XCTAssertTrue(layout);

    XCTAssertTrue(layout->frame_guide_rect->region() == (ui::region{.origin = {0.0f, 0.0f}, .size = {0.0f, 0.0f}}));
    XCTAssertEqual(layout->preferred_cell_count(), 0);
    XCTAssertTrue(layout->default_cell_size() == (ui::size{1.0f, 1.0f}));
    XCTAssertEqual(layout->lines().size(), 0);
    XCTAssertEqual(layout->row_spacing(), 0.0f);
    XCTAssertEqual(layout->col_spacing(), 0.0f);
    XCTAssertEqual(layout->borders, (ui::layout_borders{0.0f, 0.0f, 0.0f, 0.0f}));
    XCTAssertEqual(layout->alignment(), ui::layout_alignment::min);
    XCTAssertEqual(layout->direction(), ui::layout_direction::vertical);
    XCTAssertEqual(layout->row_order(), ui::layout_order::ascending);
    XCTAssertEqual(layout->col_order(), ui::layout_order::ascending);
    XCTAssertEqual(layout->actual_cell_count(), 0);
    XCTAssertFalse(layout->actual_frame().has_value());
}

- (void)test_create_with_args {
    auto layout = ui::collection_layout::make_shared(
        {.frame = {.origin = {11.0f, 12.0f}, .size = {13.0f, 14.0f}},
         .preferred_cell_count = 10,
         .default_cell_size = {2.5f, 3.5f},
         .lines = {{.cell_sizes = {{2.6f, 3.6f}, {2.7f, 3.7f}}, .new_line_min_offset = 3.9f}},
         .row_spacing = 4.0f,
         .col_spacing = 4.0f,
         .borders = {.left = 5.0f, .right = 6.0f, .bottom = 7.0f, .top = 8.0f},
         .alignment = ui::layout_alignment::max,
         .direction = ui::layout_direction::horizontal,
         .row_order = ui::layout_order::descending,
         .col_order = ui::layout_order::descending});

    XCTAssertTrue(layout);

    XCTAssertTrue(layout->frame_guide_rect->region() == (ui::region{.origin = {11.0f, 12.0f}, .size = {13.0f, 14.0f}}));
    XCTAssertEqual(layout->preferred_cell_count(), 10);
    XCTAssertTrue(layout->default_cell_size() == (ui::size{2.5f, 3.5f}));
    XCTAssertEqual(layout->lines().size(), 1);
    XCTAssertEqual(layout->lines().at(0).cell_sizes.size(), 2);
    XCTAssertTrue(layout->lines().at(0).cell_sizes.at(0) == (ui::size{2.6f, 3.6f}));
    XCTAssertTrue(layout->lines().at(0).cell_sizes.at(1) == (ui::size{2.7f, 3.7f}));
    XCTAssertEqual(layout->lines().at(0).new_line_min_offset, 3.9f);
    XCTAssertEqual(layout->row_spacing(), 4.0f);
    XCTAssertEqual(layout->col_spacing(), 4.0f);
    XCTAssertEqual(layout->borders, (ui::layout_borders{.left = 5.0f, .right = 6.0f, .bottom = 7.0f, .top = 8.0f}));
    XCTAssertEqual(layout->alignment(), ui::layout_alignment::max);
    XCTAssertEqual(layout->direction(), ui::layout_direction::horizontal);
    XCTAssertEqual(layout->row_order(), ui::layout_order::descending);
    XCTAssertEqual(layout->col_order(), ui::layout_order::descending);
    XCTAssertEqual(layout->actual_cell_count(), 0);
    XCTAssertFalse(layout->actual_frame().has_value());
}

- (void)test_cell_layout_guide_rects {
    auto layout =
        ui::collection_layout::make_shared({.frame = {.origin = {2.0f, 4.0f}, .size = {8.0f, 9.0f}},
                                            .preferred_cell_count = 4,
                                            .default_cell_size = {2.0f, 3.0f},
                                            .row_spacing = 1.0f,
                                            .col_spacing = 1.0f,
                                            .borders = {.left = 1.0f, .right = 1.0f, .bottom = 1.0f, .top = 1.0f}});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.size(), 4);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->right()->value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->top()->value(), 8.0f);

    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->right()->value(), 8.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->top()->value(), 8.0f);

    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->right()->value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 9.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->top()->value(), 12.0f);

    XCTAssertEqual(cell_guide_rects.at(3)->left()->value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->right()->value(), 8.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->bottom()->value(), 9.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->top()->value(), 12.0f);
}

- (void)test_actual_cell_count {
    auto layout = ui::collection_layout::make_shared(
        {.frame = {.origin = {0.0f, 0.0f}, .size = {2.0f, 2.0f}}, .preferred_cell_count = 1});

    XCTAssertEqual(layout->actual_cell_count(), 1);

    layout->set_preferred_cell_count(5);

    XCTAssertEqual(layout->actual_cell_count(), 4);

    layout->set_preferred_cell_count(2);

    XCTAssertEqual(layout->actual_cell_count(), 2);
}

- (void)test_actual_frame {
    auto layout = ui::collection_layout::make_shared(
        {.frame = {.origin = {1.0f, 2.0f}, .size = {2.0f, 2.0f}}, .preferred_cell_count = 0});

    XCTAssertFalse(layout->actual_frame().has_value());

    layout->set_preferred_cell_count(1);

    XCTAssertTrue(layout->actual_frame().value() == (ui::region{.origin = {1.0f, 2.0f}, .size = {1.0f, 1.0f}}));

    layout->set_preferred_cell_count(2);

    XCTAssertTrue(layout->actual_frame().value() == (ui::region{.origin = {1.0f, 2.0f}, .size = {2.0f, 1.0f}}));

    layout->set_preferred_cell_count(3);

    XCTAssertTrue(layout->actual_frame().value() == (ui::region{.origin = {1.0f, 2.0f}, .size = {2.0f, 2.0f}}));

    layout->set_preferred_cell_count(4);

    XCTAssertTrue(layout->actual_frame().value() == (ui::region{.origin = {1.0f, 2.0f}, .size = {2.0f, 2.0f}}));
}

- (void)test_observe_actual_cell_count {
    auto layout = ui::collection_layout::make_shared(
        {.frame = {.origin = {0.0f, 0.0f}, .size = {2.0f, 2.0f}}, .preferred_cell_count = 1});

    std::size_t notified_count = 0;

    auto canceller =
        layout->observe_actual_cell_count([&notified_count](auto const &count) { notified_count = count; }).end();

    layout->set_preferred_cell_count(5);

    XCTAssertEqual(notified_count, 4);

    layout->set_preferred_cell_count(2);

    XCTAssertEqual(notified_count, 2);
}

- (void)test_set_frame {
    auto layout =
        ui::collection_layout::make_shared({.frame = {.origin = {2.0f, 4.0f}, .size = {8.0f, 16.0f}},
                                            .preferred_cell_count = 4,
                                            .default_cell_size = {2.0f, 3.0f},
                                            .row_spacing = 1.0f,
                                            .col_spacing = 1.0f,
                                            .borders = {.left = 1.0f, .right = 1.0f, .bottom = 1.0f, .top = 1.0f}});

    XCTAssertTrue(layout->frame_guide_rect->region() == (ui::region{.origin = {2.0f, 4.0f}, .size = {8.0f, 16.0f}}));

    XCTAssertEqual(layout->frame_guide_rect->left()->value(), 2.0f);
    XCTAssertEqual(layout->frame_guide_rect->right()->value(), 10.0f);
    XCTAssertEqual(layout->frame_guide_rect->bottom()->value(), 4.0f);
    XCTAssertEqual(layout->frame_guide_rect->top()->value(), 20.0f);

    auto const &cell_guide_rects = layout->cell_guide_rects();

    layout->frame_guide_rect->set_region({.origin = {3.0f, 5.0f}, .size = {7.0f, 16.0f}});

    XCTAssertTrue(layout->frame_guide_rect->region() == (ui::region{.origin = {3.0f, 5.0f}, .size = {7.0f, 16.0f}}));

    XCTAssertEqual(layout->frame_guide_rect->left()->value(), 3.0f);
    XCTAssertEqual(layout->frame_guide_rect->right()->value(), 10.0f);
    XCTAssertEqual(layout->frame_guide_rect->bottom()->value(), 5.0f);
    XCTAssertEqual(layout->frame_guide_rect->top()->value(), 21.0f);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 4.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->right()->value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->top()->value(), 9.0f);

    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 7.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->right()->value(), 9.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->top()->value(), 9.0f);

    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 4.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->right()->value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 10.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->top()->value(), 13.0f);

    XCTAssertEqual(cell_guide_rects.at(3)->left()->value(), 7.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->right()->value(), 9.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->bottom()->value(), 10.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->top()->value(), 13.0f);
}

- (void)test_limiting_row {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {1.0f, 0.0f}},
                                                      .preferred_cell_count = 8,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::vertical});

    // フレームの高さが0ならセルを作る範囲の制限をかけない
    XCTAssertEqual(layout->actual_cell_count(), 8);

    layout->frame_guide_rect->set_region({.size = {0.0f, 0.5f}});

    // フレームの高さが0より大きくてセルの高さよりも低い場合は作れるセルがない
    XCTAssertEqual(layout->actual_cell_count(), 0);

    layout->set_direction(ui::layout_direction::horizontal);

    // セルの並びを横にすれば高さの制限は受けない
    XCTAssertEqual(layout->actual_cell_count(), 8);

    layout->frame_guide_rect->set_region({.size = {0.0f, 0.5f}});

    XCTAssertEqual(layout->actual_cell_count(), 8);
}

- (void)test_limiting_col {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {0.0f, 1.0f}},
                                                      .preferred_cell_count = 8,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::horizontal});

    // フレームの幅が0ならセルを作る範囲の制限をかけない
    XCTAssertEqual(layout->actual_cell_count(), 8);

    layout->frame_guide_rect->set_region({.size = {0.5f, 0.0f}});

    // フレームの幅が0より大きくてセルの幅よりも低い場合は作れるセルがない
    XCTAssertEqual(layout->actual_cell_count(), 0);

    layout->set_direction(ui::layout_direction::vertical);

    // セルの並びを縦にすれば高さの制限は受けない
    XCTAssertEqual(layout->actual_cell_count(), 8);

    layout->frame_guide_rect->set_region({.size = {0.5f, 0.0f}});

    XCTAssertEqual(layout->actual_cell_count(), 8);
}

- (void)test_set_preferred_cell_count {
    auto layout = ui::collection_layout::make_shared({.preferred_cell_count = 2});

    XCTAssertEqual(layout->preferred_cell_count(), 2);

    layout->set_preferred_cell_count(3);

    XCTAssertEqual(layout->preferred_cell_count(), 3);

    layout->set_preferred_cell_count(0);

    XCTAssertEqual(layout->preferred_cell_count(), 0);
}

- (void)test_set_default_cell_size {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 0.0f}}, .preferred_cell_count = 3});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertTrue(layout->default_cell_size() == (ui::size{1.0f, 1.0f}));

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);

    layout->set_default_cell_size({2.0f, 3.0f});

    XCTAssertTrue(layout->default_cell_size() == (ui::size{2.0f, 3.0f}));

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 6.0f);
}

- (void)test_new_line_by_frame_only {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {3.0f, 0.0f}}, .preferred_cell_count = 5});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(layout->lines().size(), 0);

    layout->set_lines({{.cell_sizes = {{1.0f, 1.0f}, {2.0f, 2.0f}, {3.0f, 3.0f}, {1.0f, 1.0f}, {2.0f, 2.0f}},
                        .new_line_min_offset = 0.0f}});

    XCTAssertEqual(layout->lines().size(), 1);
    XCTAssertEqual(layout->lines().at(0).cell_sizes.size(), 5);

    XCTAssertTrue(layout->lines().at(0).cell_sizes.at(0) == (ui::size{1.0f, 1.0f}));
    XCTAssertTrue(layout->lines().at(0).cell_sizes.at(1) == (ui::size{2.0f, 2.0f}));
    XCTAssertTrue(layout->lines().at(0).cell_sizes.at(2) == (ui::size{3.0f, 3.0f}));
    XCTAssertTrue(layout->lines().at(0).cell_sizes.at(3) == (ui::size{1.0f, 1.0f}));
    XCTAssertTrue(layout->lines().at(0).cell_sizes.at(4) == (ui::size{2.0f, 2.0f}));

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->right()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->top()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->right()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->top()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->right()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->top()->value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->right()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->bottom()->value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->top()->value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->right()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->bottom()->value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->top()->value(), 7.0f);
}

- (void)test_new_line_by_lines {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {10.0f, 0.0f}}, .preferred_cell_count = 5});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    layout->set_lines({{.cell_sizes = {{1.0f, 1.0f}, {2.0f, 2.0f}, {3.0f, 3.0f}}, .new_line_min_offset = 0.0f},
                       {.cell_sizes = {{1.0f, 1.0f}, {2.0f, 2.0f}}, .new_line_min_offset = 0.0f}});

    XCTAssertEqual(layout->lines().size(), 2);
    XCTAssertEqual(layout->lines().at(0).cell_sizes.size(), 3);
    XCTAssertEqual(layout->lines().at(1).cell_sizes.size(), 2);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->right()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->top()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->right()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->top()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->right()->value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->top()->value(), 3.0f);

    XCTAssertEqual(cell_guide_rects.at(3)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->right()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->bottom()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->top()->value(), 4.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->right()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->bottom()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->top()->value(), 5.0f);
}

- (void)test_new_line_by_frame_and_lines {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 0.0f}}, .preferred_cell_count = 5});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    ui::size const cell_size = {1.0f, 1.0f};

    layout->set_lines({{.cell_sizes = {cell_size, cell_size, cell_size}, .new_line_min_offset = 0.0f},
                       {.cell_sizes = {cell_size, cell_size}, .new_line_min_offset = 0.0f}});

    XCTAssertEqual(layout->lines().size(), 2);
    XCTAssertEqual(layout->lines().at(0).cell_sizes.size(), 3);
    XCTAssertEqual(layout->lines().at(1).cell_sizes.size(), 2);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->right()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->top()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->right()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->top()->value(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->right()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->top()->value(), 2.0f);

    XCTAssertEqual(cell_guide_rects.at(3)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->right()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->bottom()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(3)->top()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->right()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->bottom()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(4)->top()->value(), 3.0f);
}

- (void)test_set_cell_sizes_zero_width {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {3.0f, 0.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {0.0f, 1.0f},
                                                      .borders = {.left = 1.0f, .right = 1.0f}});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(layout->actual_cell_count(), 3);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->right()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->top()->value(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->right()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->top()->value(), 2.0f);

    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->right()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->top()->value(), 3.0f);
}

- (void)test_set_row_spacing {
    auto layout = ui::collection_layout::make_shared(
        {.frame = {.size = {2.0f, 0.0f}}, .preferred_cell_count = 3, .default_cell_size = {1.0f, 1.0f}});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(layout->row_spacing(), 0.0f);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);

    layout->set_row_spacing(1.0f);

    XCTAssertEqual(layout->row_spacing(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 2.0f);
}

- (void)test_set_col_spacing {
    auto layout = ui::collection_layout::make_shared(
        {.frame = {.size = {3.0f, 0.0f}}, .preferred_cell_count = 3, .default_cell_size = {1.0f, 1.0f}});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(layout->col_spacing(), 0.0f);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 0.0f);

    layout->set_col_spacing(1.0f);

    XCTAssertEqual(layout->col_spacing(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);
}

- (void)test_set_aligmnent {
    auto layout = ui::collection_layout::make_shared();

    layout->set_alignment(ui::layout_alignment::mid);

    XCTAssertEqual(layout->alignment(), ui::layout_alignment::mid);

    layout->set_alignment(ui::layout_alignment::max);

    XCTAssertEqual(layout->alignment(), ui::layout_alignment::max);
}

- (void)test_alignment_mid {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {5.0f, 0.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {2.0f, 1.0f},
                                                      .alignment = ui::layout_alignment::mid});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.5f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 2.5f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 1.5f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);
}

- (void)test_alignment_max {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {5.0f, 0.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {2.0f, 1.0f},
                                                      .alignment = ui::layout_alignment::max});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);
}

- (void)test_set_direction {
    auto layout = ui::collection_layout::make_shared();

    layout->set_direction(ui::layout_direction::horizontal);

    XCTAssertEqual(layout->direction(), ui::layout_direction::horizontal);
}

- (void)test_set_row_order {
    auto layout = ui::collection_layout::make_shared();

    layout->set_row_order(ui::layout_order::descending);

    XCTAssertEqual(layout->row_order(), ui::layout_order::descending);
}

- (void)test_set_col_order {
    auto layout = ui::collection_layout::make_shared();

    layout->set_col_order(ui::layout_order::descending);

    XCTAssertEqual(layout->col_order(), ui::layout_order::descending);
}

- (void)test_vertical_each_ascending_order {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 2.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::vertical,
                                                      .row_order = ui::layout_order::ascending,
                                                      .col_order = ui::layout_order::ascending});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);
}

- (void)test_vertical_row_descending_order {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 2.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::vertical,
                                                      .row_order = ui::layout_order::descending,
                                                      .col_order = ui::layout_order::ascending});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 0.0f);
}

- (void)test_vertical_col_descending_order {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 2.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::vertical,
                                                      .row_order = ui::layout_order::ascending,
                                                      .col_order = ui::layout_order::descending});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);
}

- (void)test_vertical_each_descending_order {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 2.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::vertical,
                                                      .row_order = ui::layout_order::descending,
                                                      .col_order = ui::layout_order::descending});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 0.0f);
}

- (void)test_horizontal_each_ascending_order {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 2.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::horizontal,
                                                      .row_order = ui::layout_order::ascending,
                                                      .col_order = ui::layout_order::ascending});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 0.0f);
}

- (void)test_horizontal_row_descending_order {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 2.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::horizontal,
                                                      .row_order = ui::layout_order::descending,
                                                      .col_order = ui::layout_order::ascending});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 0.0f);
}

- (void)test_horizontal_col_descending_order {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 2.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::horizontal,
                                                      .row_order = ui::layout_order::ascending,
                                                      .col_order = ui::layout_order::descending});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);
}

- (void)test_horizontal_each_descending_order {
    auto layout = ui::collection_layout::make_shared({.frame = {.size = {2.0f, 2.0f}},
                                                      .preferred_cell_count = 3,
                                                      .default_cell_size = {1.0f, 1.0f},
                                                      .direction = ui::layout_direction::horizontal,
                                                      .row_order = ui::layout_order::descending,
                                                      .col_order = ui::layout_order::descending});

    auto const &cell_guide_rects = layout->cell_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0)->bottom()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->left()->value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1)->bottom()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->left()->value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2)->bottom()->value(), 1.0f);
}

- (void)test_is_equal_line {
    ui::collection_layout::line line1a{.cell_sizes = {{1.0f, 2.0f}}, .new_line_min_offset = 3.0f};
    ui::collection_layout::line line1b{.cell_sizes = {{1.0f, 2.0f}}, .new_line_min_offset = 3.0f};
    ui::collection_layout::line line2{.cell_sizes = {{1.0f, 2.0f}}, .new_line_min_offset = 4.0f};
    ui::collection_layout::line line3{.cell_sizes = {{5.0f, 6.0f}}, .new_line_min_offset = 3.0f};

    XCTAssertTrue(line1a == line1a);
    XCTAssertTrue(line1a == line1b);
    XCTAssertFalse(line1a == line2);
    XCTAssertFalse(line1a == line3);

    XCTAssertFalse(line1a != line1a);
    XCTAssertFalse(line1a != line1b);
    XCTAssertTrue(line1a != line2);
    XCTAssertTrue(line1a != line3);
}

- (void)test_observe_preferred_cell_count {
    auto layout = ui::collection_layout::make_shared();

    std::optional<std::size_t> notified_count;

    auto canceller =
        layout->observe_preferred_cell_count([&notified_count](auto const &count) { notified_count = count; }).end();

    XCTAssertFalse(notified_count);

    layout->set_preferred_cell_count(10);

    XCTAssertTrue(notified_count);
    XCTAssertEqual(*notified_count, 10);
}

- (void)test_observe_alignment {
    auto layout = ui::collection_layout::make_shared();

    std::optional<ui::layout_alignment> notified;

    auto observer = layout->observe_alignment([&notified](auto const &aligment) { notified = aligment; }).end();

    XCTAssertFalse(notified);

    layout->set_alignment(ui::layout_alignment::max);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, ui::layout_alignment::max);
}

- (void)test_observe_lines {
    auto layout = ui::collection_layout::make_shared();

    std::optional<std::vector<ui::collection_layout::line>> notified;

    auto observer = layout->observe_lines([&notified](auto const &lines) { notified = lines; }).end();

    XCTAssertFalse(notified);

    layout->set_lines({{}});

    XCTAssertTrue(notified);
    XCTAssertEqual(notified->size(), 1);
}

- (void)test_observe_default_cell_size {
    auto layout = ui::collection_layout::make_shared();

    std::optional<ui::size> notified;

    auto observer = layout->observe_default_cell_size([&notified](auto const &size) { notified = size; }).end();

    XCTAssertFalse(notified);

    layout->set_default_cell_size({1.0f, 2.0f});

    XCTAssertTrue(notified);
    XCTAssertEqual(notified->width, 1.0f);
    XCTAssertEqual(notified->height, 2.0f);
}

- (void)test_observe_row_order {
    auto layout = ui::collection_layout::make_shared();

    std::optional<ui::layout_order> notified;

    auto observer = layout->observe_row_order([&notified](auto const &order) { notified = order; }).end();

    XCTAssertFalse(notified);

    layout->set_row_order(ui::layout_order::descending);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, ui::layout_order::descending);
}

- (void)test_observe_col_order {
    auto layout = ui::collection_layout::make_shared();

    std::optional<ui::layout_order> notified;

    auto observer = layout->observe_col_order([&notified](auto const &order) { notified = order; }).end();

    XCTAssertFalse(notified);

    layout->set_col_order(ui::layout_order::descending);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, ui::layout_order::descending);
}

- (void)test_observe_direction {
    auto layout = ui::collection_layout::make_shared();

    std::optional<ui::layout_direction> notified;

    auto observer = layout->observe_direction([&notified](auto const &direction) { notified = direction; }).end();

    XCTAssertFalse(notified);

    layout->set_direction(ui::layout_direction::horizontal);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, ui::layout_direction::horizontal);
}

- (void)test_observe_row_spacing {
    auto layout = ui::collection_layout::make_shared();

    std::optional<float> notified;

    auto observer = layout->observe_row_spacing([&notified](auto const &spacing) { notified = spacing; }).end();

    XCTAssertFalse(notified);

    layout->set_row_spacing(11.0f);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, 11.0f);
}

- (void)test_observe_col_spacing {
    auto layout = ui::collection_layout::make_shared();

    std::optional<float> notified;

    auto observer = layout->observe_col_spacing([&notified](auto const &spacing) { notified = spacing; }).end();

    XCTAssertFalse(notified);

    layout->set_col_spacing(11.0f);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, 11.0f);
}

@end
