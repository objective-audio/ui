//
//  yas_ui_fixed_colleciton_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/yas_ui_collection_layout.h>
#import <ui/yas_ui_layout_guide.h>

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
    ui::collection_layout layout;

    XCTAssertTrue(layout);

    XCTAssertTrue(layout.frame() == (ui::region{.origin = {0.0f, 0.0f}, .size = {0.0f, 0.0f}}));
    XCTAssertEqual(layout.preferred_cell_count(), 0);
    XCTAssertTrue(layout.default_cell_size() == (ui::size{1.0f, 1.0f}));
    XCTAssertEqual(layout.lines().size(), 0);
    XCTAssertEqual(layout.row_spacing(), 0.0f);
    XCTAssertEqual(layout.col_spacing(), 0.0f);
    XCTAssertEqual(layout.borders(), (ui::layout_borders{0.0f, 0.0f, 0.0f, 0.0f}));
    XCTAssertEqual(layout.alignment(), ui::layout_alignment::min);
    XCTAssertEqual(layout.direction(), ui::layout_direction::vertical);
    XCTAssertEqual(layout.row_order(), ui::layout_order::ascending);
    XCTAssertEqual(layout.col_order(), ui::layout_order::ascending);
}

- (void)test_create_with_args {
    ui::collection_layout layout{{.frame = {.origin = {11.0f, 12.0f}, .size = {13.0f, 14.0f}},
                                  .preferred_cell_count = 10,
                                  .default_cell_size = {2.5f, 3.5f},
                                  .lines = {{.cell_sizes = {{2.6f, 3.6f}, {2.7f, 3.7f}}, .new_line_min_offset = 3.9f}},
                                  .row_spacing = 4.0f,
                                  .col_spacing = 4.0f,
                                  .borders = {.left = 5.0f, .right = 6.0f, .bottom = 7.0f, .top = 8.0f},
                                  .alignment = ui::layout_alignment::max,
                                  .direction = ui::layout_direction::horizontal,
                                  .row_order = ui::layout_order::descending,
                                  .col_order = ui::layout_order::descending}};

    XCTAssertTrue(layout);

    XCTAssertTrue(layout.frame() == (ui::region{.origin = {11.0f, 12.0f}, .size = {13.0f, 14.0f}}));
    XCTAssertEqual(layout.preferred_cell_count(), 10);
    XCTAssertTrue(layout.default_cell_size() == (ui::size{2.5f, 3.5f}));
    XCTAssertEqual(layout.lines().size(), 1);
    XCTAssertEqual(layout.lines().at(0).cell_sizes.size(), 2);
    XCTAssertTrue(layout.lines().at(0).cell_sizes.at(0) == (ui::size{2.6f, 3.6f}));
    XCTAssertTrue(layout.lines().at(0).cell_sizes.at(1) == (ui::size{2.7f, 3.7f}));
    XCTAssertEqual(layout.lines().at(0).new_line_min_offset, 3.9f);
    XCTAssertEqual(layout.row_spacing(), 4.0f);
    XCTAssertEqual(layout.col_spacing(), 4.0f);
    XCTAssertEqual(layout.borders(), (ui::layout_borders{.left = 5.0f, .right = 6.0f, .bottom = 7.0f, .top = 8.0f}));
    XCTAssertEqual(layout.alignment(), ui::layout_alignment::max);
    XCTAssertEqual(layout.direction(), ui::layout_direction::horizontal);
    XCTAssertEqual(layout.row_order(), ui::layout_order::descending);
    XCTAssertEqual(layout.col_order(), ui::layout_order::descending);
}

- (void)test_create_null {
    ui::collection_layout layout{nullptr};

    XCTAssertFalse(layout);
}

- (void)test_cell_layout_guide_rects {
    ui::collection_layout layout{{.frame = {.origin = {2.0f, 4.0f}, .size = {8.0f, 9.0f}},
                                  .preferred_cell_count = 4,
                                  .default_cell_size = {2.0f, 3.0f},
                                  .row_spacing = 1.0f,
                                  .col_spacing = 1.0f,
                                  .borders = {.left = 1.0f, .right = 1.0f, .bottom = 1.0f, .top = 1.0f}}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.size(), 4);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(0).right().value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(0).top().value(), 8.0f);

    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(1).right().value(), 8.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(1).top().value(), 8.0f);

    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2).right().value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 9.0f);
    XCTAssertEqual(cell_guide_rects.at(2).top().value(), 12.0f);

    XCTAssertEqual(cell_guide_rects.at(3).left().value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(3).right().value(), 8.0f);
    XCTAssertEqual(cell_guide_rects.at(3).bottom().value(), 9.0f);
    XCTAssertEqual(cell_guide_rects.at(3).top().value(), 12.0f);
}

- (void)test_actual_cell_count {
    ui::collection_layout layout{{.frame = {.origin = {0.0f, 0.0f}, .size = {2.0f, 2.0f}}, .preferred_cell_count = 1}};

    XCTAssertEqual(layout.actual_cell_count(), 1);

    layout.set_preferred_cell_count(5);

    XCTAssertEqual(layout.actual_cell_count(), 4);

    layout.set_preferred_cell_count(2);

    XCTAssertEqual(layout.actual_cell_count(), 2);
}

- (void)test_chain_actual_cell_count {
    ui::collection_layout layout{{.frame = {.origin = {0.0f, 0.0f}, .size = {2.0f, 2.0f}}, .preferred_cell_count = 1}};

    std::size_t notified_count = 0;

    auto observer = layout.chain_actual_cell_count()
                        .perform([&notified_count](auto const &count) { notified_count = count; })
                        .end();

    layout.set_preferred_cell_count(5);

    XCTAssertEqual(notified_count, 4);

    layout.set_preferred_cell_count(2);

    XCTAssertEqual(notified_count, 2);
}

- (void)test_set_frame {
    ui::collection_layout layout{{.frame = {.origin = {2.0f, 4.0f}, .size = {8.0f, 16.0f}},
                                  .preferred_cell_count = 4,
                                  .default_cell_size = {2.0f, 3.0f},
                                  .row_spacing = 1.0f,
                                  .col_spacing = 1.0f,
                                  .borders = {.left = 1.0f, .right = 1.0f, .bottom = 1.0f, .top = 1.0f}}};

    XCTAssertTrue(layout.frame() == (ui::region{.origin = {2.0f, 4.0f}, .size = {8.0f, 16.0f}}));

    XCTAssertEqual(layout.frame_layout_guide_rect().left().value(), 2.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().right().value(), 10.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().bottom().value(), 4.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().top().value(), 20.0f);

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    layout.set_frame({.origin = {3.0f, 5.0f}, .size = {7.0f, 16.0f}});

    XCTAssertTrue(layout.frame() == (ui::region{.origin = {3.0f, 5.0f}, .size = {7.0f, 16.0f}}));

    XCTAssertEqual(layout.frame_layout_guide_rect().left().value(), 3.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().right().value(), 10.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().bottom().value(), 5.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().top().value(), 21.0f);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 4.0f);
    XCTAssertEqual(cell_guide_rects.at(0).right().value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(0).top().value(), 9.0f);

    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 7.0f);
    XCTAssertEqual(cell_guide_rects.at(1).right().value(), 9.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(1).top().value(), 9.0f);

    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 4.0f);
    XCTAssertEqual(cell_guide_rects.at(2).right().value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 10.0f);
    XCTAssertEqual(cell_guide_rects.at(2).top().value(), 13.0f);

    XCTAssertEqual(cell_guide_rects.at(3).left().value(), 7.0f);
    XCTAssertEqual(cell_guide_rects.at(3).right().value(), 9.0f);
    XCTAssertEqual(cell_guide_rects.at(3).bottom().value(), 10.0f);
    XCTAssertEqual(cell_guide_rects.at(3).top().value(), 13.0f);
}

- (void)test_limiting_row {
    ui::collection_layout layout{{.frame = {.size = {1.0f, 0.0f}},
                                  .preferred_cell_count = 8,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::vertical}};

    // フレームの高さが0ならセルを作る範囲の制限をかけない
    XCTAssertEqual(layout.actual_cell_count(), 8);

    layout.set_frame({.size = {0.0f, 0.5f}});

    // フレームの高さが0より大きくてセルの高さよりも低い場合は作れるセルがない
    XCTAssertEqual(layout.actual_cell_count(), 0);

    layout.set_direction(ui::layout_direction::horizontal);

    // セルの並びを横にすれば高さの制限は受けない
    XCTAssertEqual(layout.actual_cell_count(), 8);

    layout.set_frame({.size = {0.0f, 0.5f}});

    XCTAssertEqual(layout.actual_cell_count(), 8);
}

- (void)test_limiting_col {
    ui::collection_layout layout{{.frame = {.size = {0.0f, 1.0f}},
                                  .preferred_cell_count = 8,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::horizontal}};

    // フレームの幅が0ならセルを作る範囲の制限をかけない
    XCTAssertEqual(layout.actual_cell_count(), 8);

    layout.set_frame({.size = {0.5f, 0.0f}});

    // フレームの幅が0より大きくてセルの幅よりも低い場合は作れるセルがない
    XCTAssertEqual(layout.actual_cell_count(), 0);

    layout.set_direction(ui::layout_direction::vertical);

    // セルの並びを縦にすれば高さの制限は受けない
    XCTAssertEqual(layout.actual_cell_count(), 8);

    layout.set_frame({.size = {0.5f, 0.0f}});

    XCTAssertEqual(layout.actual_cell_count(), 8);
}

- (void)test_set_preferred_cell_count {
    ui::collection_layout layout{{.preferred_cell_count = 2}};

    XCTAssertEqual(layout.preferred_cell_count(), 2);

    layout.set_preferred_cell_count(3);

    XCTAssertEqual(layout.preferred_cell_count(), 3);

    layout.set_preferred_cell_count(0);

    XCTAssertEqual(layout.preferred_cell_count(), 0);
}

- (void)test_set_default_cell_size {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 0.0f}}, .preferred_cell_count = 3}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertTrue(layout.default_cell_size() == (ui::size{1.0f, 1.0f}));

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);

    layout.set_default_cell_size({2.0f, 3.0f});

    XCTAssertTrue(layout.default_cell_size() == (ui::size{2.0f, 3.0f}));

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 6.0f);
}

- (void)test_new_line_by_frame_only {
    ui::collection_layout layout{{.frame = {.size = {3.0f, 0.0f}}, .preferred_cell_count = 5}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(layout.lines().size(), 0);

    layout.set_lines({{.cell_sizes = {{1.0f, 1.0f}, {2.0f, 2.0f}, {3.0f, 3.0f}, {1.0f, 1.0f}, {2.0f, 2.0f}},
                       .new_line_min_offset = 0.0f}});

    XCTAssertEqual(layout.lines().size(), 1);
    XCTAssertEqual(layout.lines().at(0).cell_sizes.size(), 5);

    XCTAssertTrue(layout.lines().at(0).cell_sizes.at(0) == (ui::size{1.0f, 1.0f}));
    XCTAssertTrue(layout.lines().at(0).cell_sizes.at(1) == (ui::size{2.0f, 2.0f}));
    XCTAssertTrue(layout.lines().at(0).cell_sizes.at(2) == (ui::size{3.0f, 3.0f}));
    XCTAssertTrue(layout.lines().at(0).cell_sizes.at(3) == (ui::size{1.0f, 1.0f}));
    XCTAssertTrue(layout.lines().at(0).cell_sizes.at(4) == (ui::size{2.0f, 2.0f}));

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).right().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).top().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).right().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).top().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).right().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2).top().value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(3).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(3).right().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(3).bottom().value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(3).top().value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(4).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(4).right().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(4).bottom().value(), 5.0f);
    XCTAssertEqual(cell_guide_rects.at(4).top().value(), 7.0f);
}

- (void)test_new_line_by_lines {
    ui::collection_layout layout{{.frame = {.size = {10.0f, 0.0f}}, .preferred_cell_count = 5}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    layout.set_lines({{.cell_sizes = {{1.0f, 1.0f}, {2.0f, 2.0f}, {3.0f, 3.0f}}, .new_line_min_offset = 0.0f},
                      {.cell_sizes = {{1.0f, 1.0f}, {2.0f, 2.0f}}, .new_line_min_offset = 0.0f}});

    XCTAssertEqual(layout.lines().size(), 2);
    XCTAssertEqual(layout.lines().at(0).cell_sizes.size(), 3);
    XCTAssertEqual(layout.lines().at(1).cell_sizes.size(), 2);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).right().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).top().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).right().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).top().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2).right().value(), 6.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).top().value(), 3.0f);

    XCTAssertEqual(cell_guide_rects.at(3).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(3).right().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(3).bottom().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(3).top().value(), 4.0f);
    XCTAssertEqual(cell_guide_rects.at(4).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(4).right().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(4).bottom().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(4).top().value(), 5.0f);
}

- (void)test_new_line_by_frame_and_lines {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 0.0f}}, .preferred_cell_count = 5}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    ui::size const cell_size = {1.0f, 1.0f};

    layout.set_lines({{.cell_sizes = {cell_size, cell_size, cell_size}, .new_line_min_offset = 0.0f},
                      {.cell_sizes = {cell_size, cell_size}, .new_line_min_offset = 0.0f}});

    XCTAssertEqual(layout.lines().size(), 2);
    XCTAssertEqual(layout.lines().at(0).cell_sizes.size(), 3);
    XCTAssertEqual(layout.lines().at(1).cell_sizes.size(), 2);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).right().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).top().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).right().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).top().value(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).right().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).top().value(), 2.0f);

    XCTAssertEqual(cell_guide_rects.at(3).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(3).right().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(3).bottom().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(3).top().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(4).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(4).right().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(4).bottom().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(4).top().value(), 3.0f);
}

- (void)test_set_cell_sizes_zero_width {
    ui::collection_layout layout{{.frame = {.size = {3.0f, 0.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {0.0f, 1.0f},
                                  .borders = {.left = 1.0f, .right = 1.0f}}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(layout.actual_cell_count(), 3);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).right().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).top().value(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).right().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).top().value(), 2.0f);

    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).right().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2).top().value(), 3.0f);
}

- (void)test_set_row_spacing {
    ui::collection_layout layout{
        {.frame = {.size = {2.0f, 0.0f}}, .preferred_cell_count = 3, .default_cell_size = {1.0f, 1.0f}}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(layout.row_spacing(), 0.0f);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);

    layout.set_row_spacing(1.0f);

    XCTAssertEqual(layout.row_spacing(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 2.0f);
}

- (void)test_set_col_spacing {
    ui::collection_layout layout{
        {.frame = {.size = {3.0f, 0.0f}}, .preferred_cell_count = 3, .default_cell_size = {1.0f, 1.0f}}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(layout.col_spacing(), 0.0f);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 0.0f);

    layout.set_col_spacing(1.0f);

    XCTAssertEqual(layout.col_spacing(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);
}

- (void)test_set_aligmnent {
    ui::collection_layout layout;

    layout.set_alignment(ui::layout_alignment::mid);

    XCTAssertEqual(layout.alignment(), ui::layout_alignment::mid);

    layout.set_alignment(ui::layout_alignment::max);

    XCTAssertEqual(layout.alignment(), ui::layout_alignment::max);
}

- (void)test_alignment_mid {
    ui::collection_layout layout{{.frame = {.size = {5.0f, 0.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {2.0f, 1.0f},
                                  .alignment = ui::layout_alignment::mid}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.5f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 2.5f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 1.5f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);
}

- (void)test_alignment_max {
    ui::collection_layout layout{{.frame = {.size = {5.0f, 0.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {2.0f, 1.0f},
                                  .alignment = ui::layout_alignment::max}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);
}

- (void)test_set_direction {
    ui::collection_layout layout;

    layout.set_direction(ui::layout_direction::horizontal);

    XCTAssertEqual(layout.direction(), ui::layout_direction::horizontal);
}

- (void)test_set_row_order {
    ui::collection_layout layout;

    layout.set_row_order(ui::layout_order::descending);

    XCTAssertEqual(layout.row_order(), ui::layout_order::descending);
}

- (void)test_set_col_order {
    ui::collection_layout layout;

    layout.set_col_order(ui::layout_order::descending);

    XCTAssertEqual(layout.col_order(), ui::layout_order::descending);
}

- (void)test_vertical_each_ascending_order {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::vertical,
                                  .row_order = ui::layout_order::ascending,
                                  .col_order = ui::layout_order::ascending}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);
}

- (void)test_vertical_row_descending_order {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::vertical,
                                  .row_order = ui::layout_order::descending,
                                  .col_order = ui::layout_order::ascending}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 0.0f);
}

- (void)test_vertical_col_descending_order {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::vertical,
                                  .row_order = ui::layout_order::ascending,
                                  .col_order = ui::layout_order::descending}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);
}

- (void)test_vertical_each_descending_order {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::vertical,
                                  .row_order = ui::layout_order::descending,
                                  .col_order = ui::layout_order::descending}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 0.0f);
}

- (void)test_horizontal_each_ascending_order {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::horizontal,
                                  .row_order = ui::layout_order::ascending,
                                  .col_order = ui::layout_order::ascending}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 0.0f);
}

- (void)test_horizontal_row_descending_order {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::horizontal,
                                  .row_order = ui::layout_order::descending,
                                  .col_order = ui::layout_order::ascending}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 0.0f);
}

- (void)test_horizontal_col_descending_order {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::horizontal,
                                  .row_order = ui::layout_order::ascending,
                                  .col_order = ui::layout_order::descending}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);
}

- (void)test_horizontal_each_descending_order {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}},
                                  .preferred_cell_count = 3,
                                  .default_cell_size = {1.0f, 1.0f},
                                  .direction = ui::layout_direction::horizontal,
                                  .row_order = ui::layout_order::descending,
                                  .col_order = ui::layout_order::descending}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);
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

- (void)test_chain_preferred_cell_count {
    ui::collection_layout layout;

    std::optional<std::size_t> notified_count;

    auto observer = layout.chain_preferred_cell_count()
                        .perform([&notified_count](auto const &count) { notified_count = count; })
                        .end();

    layout.set_preferred_cell_count(10);

    XCTAssertTrue(notified_count);
    XCTAssertEqual(*notified_count, 10);
}

- (void)test_chain_alignment {
    ui::collection_layout layout;

    std::optional<ui::layout_alignment> notified;

    auto observer = layout.chain_alignment().perform([&notified](auto const &aligment) { notified = aligment; }).end();

    layout.set_alignment(ui::layout_alignment::max);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, ui::layout_alignment::max);
}

- (void)test_chain_lines {
    ui::collection_layout layout;

    std::optional<std::vector<ui::collection_layout::line>> notified;

    auto observer = layout.chain_lines().perform([&notified](auto const &lines) { notified = lines; }).end();

    layout.set_lines({{}});

    XCTAssertTrue(notified);
    XCTAssertEqual(notified->size(), 1);
}

- (void)test_chain_default_cell_size {
    ui::collection_layout layout;

    std::optional<ui::size> notified;

    auto observer = layout.chain_default_cell_size().perform([&notified](auto const &size) { notified = size; }).end();

    layout.set_default_cell_size({1.0f, 2.0f});

    XCTAssertTrue(notified);
    XCTAssertEqual(notified->width, 1.0f);
    XCTAssertEqual(notified->height, 2.0f);
}

- (void)test_chain_row_order {
    ui::collection_layout layout;

    std::optional<ui::layout_order> notified;

    auto observer = layout.chain_row_order().perform([&notified](auto const &order) { notified = order; }).end();

    layout.set_row_order(ui::layout_order::descending);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, ui::layout_order::descending);
}

- (void)test_chain_col_order {
    ui::collection_layout layout;

    std::optional<ui::layout_order> notified;

    auto observer = layout.chain_col_order().perform([&notified](auto const &order) { notified = order; }).end();

    layout.set_col_order(ui::layout_order::descending);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, ui::layout_order::descending);
}

- (void)test_chain_direction {
    ui::collection_layout layout;

    std::optional<ui::layout_direction> notified;

    auto observer =
        layout.chain_direction().perform([&notified](auto const &direction) { notified = direction; }).end();

    layout.set_direction(ui::layout_direction::horizontal);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, ui::layout_direction::horizontal);
}

- (void)test_chain_row_spacing {
    ui::collection_layout layout;

    std::optional<float> notified;

    auto observer = layout.chain_row_spacing().perform([&notified](auto const &spacing) { notified = spacing; }).end();

    layout.set_row_spacing(11.0f);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, 11.0f);
}

- (void)test_chain_col_spacing {
    ui::collection_layout layout;

    std::optional<float> notified;

    auto observer = layout.chain_col_spacing().perform([&notified](auto const &spacing) { notified = spacing; }).end();

    layout.set_col_spacing(11.0f);

    XCTAssertTrue(notified);
    XCTAssertEqual(*notified, 11.0f);
}

@end
