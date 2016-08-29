//
//  yas_ui_fixed_colleciton_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_collection_layout.h"
#import "yas_ui_layout_guide.h"

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

    XCTAssertEqual(layout.frame(), (ui::float_region{.origin = {0.0f, 0.0f}, .size = {0.0f, 0.0f}}));
    XCTAssertEqual(layout.preferred_cell_count(), 0);
    XCTAssertEqual(layout.cell_sizes().size(), 1);
    XCTAssertEqual(layout.cell_sizes().at(0), (ui::float_size{1.0f, 1.0f}));
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
                                  .cell_sizes = {{2.0f, 3.0f}},
                                  .row_spacing = 4.0f,
                                  .col_spacing = 4.0f,
                                  .borders = {.left = 5.0f, .right = 6.0f, .bottom = 7.0f, .top = 8.0f},
                                  .alignment = ui::layout_alignment::max,
                                  .direction = ui::layout_direction::horizontal,
                                  .row_order = ui::layout_order::descending,
                                  .col_order = ui::layout_order::descending}};

    XCTAssertTrue(layout);

    XCTAssertEqual(layout.frame(), (ui::float_region{.origin = {11.0f, 12.0f}, .size = {13.0f, 14.0f}}));
    XCTAssertEqual(layout.preferred_cell_count(), 10);
    XCTAssertEqual(layout.cell_sizes().size(), 1);
    XCTAssertEqual(layout.cell_sizes().at(0), (ui::float_size{2.0f, 3.0f}));
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
                                  .cell_sizes = {{2.0f, 3.0f}},
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
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}}, .preferred_cell_count = 1}};

    XCTAssertEqual(layout.actual_cell_count(), 1);

    layout.set_preferred_cell_count(5);

    XCTAssertEqual(layout.actual_cell_count(), 4);

    layout.set_preferred_cell_count(2);

    XCTAssertEqual(layout.actual_cell_count(), 2);
}

- (void)test_notify_actual_cell_count {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 2.0f}}, .preferred_cell_count = 1}};

    std::size_t notified_count = 0;

    auto observer = layout.subject().make_observer(
        ui::collection_layout::method::actual_cell_count_changed,
        [&notified_count](auto const &context) { notified_count = context.value.actual_cell_count(); });

    layout.set_preferred_cell_count(5);

    XCTAssertEqual(notified_count, 4);

    layout.set_preferred_cell_count(2);

    XCTAssertEqual(notified_count, 2);
}

- (void)test_set_frame {
    ui::collection_layout layout{{.frame = {.origin = {2.0f, 4.0f}, .size = {8.0f, 16.0f}},
                                  .preferred_cell_count = 4,
                                  .cell_sizes = {{2.0f, 3.0f}},
                                  .row_spacing = 1.0f,
                                  .col_spacing = 1.0f,
                                  .borders = {.left = 1.0f, .right = 1.0f, .bottom = 1.0f, .top = 1.0f}}};

    XCTAssertEqual(layout.frame(), (ui::float_region{.origin = {2.0f, 4.0f}, .size = {8.0f, 16.0f}}));

    XCTAssertEqual(layout.frame_layout_guide_rect().left().value(), 2.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().right().value(), 10.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().bottom().value(), 4.0f);
    XCTAssertEqual(layout.frame_layout_guide_rect().top().value(), 20.0f);

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    layout.set_frame({.origin = {3.0f, 5.0f}, .size = {7.0f, 16.0f}});

    XCTAssertEqual(layout.frame(), (ui::float_region{.origin = {3.0f, 5.0f}, .size = {7.0f, 16.0f}}));

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
    ui::collection_layout layout{
        {.frame = {.size = {1.0f, 0.0f}}, .preferred_cell_count = 8, .cell_sizes = {{1.0f, 1.0f}}}};

    XCTAssertEqual(layout.actual_cell_count(), 8);

    layout.set_frame({.size = {0.0f, 1.0f}});

    XCTAssertEqual(layout.actual_cell_count(), 0);

    layout.set_direction(ui::layout_direction::horizontal);

    XCTAssertEqual(layout.actual_cell_count(), 8);

    layout.set_frame({.size = {1.0f, 0.0f}});
}

- (void)test_set_preferred_cell_count {
    ui::collection_layout layout{{.preferred_cell_count = 2}};

    XCTAssertEqual(layout.preferred_cell_count(), 2);

    layout.set_preferred_cell_count(3);

    XCTAssertEqual(layout.preferred_cell_count(), 3);

    layout.set_preferred_cell_count(0);

    XCTAssertEqual(layout.preferred_cell_count(), 0);
}

- (void)test_set_cell_sizes_single {
    ui::collection_layout layout{{.frame = {.size = {2.0f, 0.0f}}, .preferred_cell_count = 3}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(layout.cell_sizes().size(), 1);
    XCTAssertEqual(layout.cell_sizes().at(0), (ui::float_size{1.0f, 1.0f}));

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 1.0f);

    layout.set_cell_sizes({{2.0f, 3.0f}});

    XCTAssertEqual(layout.cell_sizes().size(), 1);
    XCTAssertEqual(layout.cell_sizes().at(0), (ui::float_size{2.0f, 3.0f}));

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 6.0f);
}

- (void)test_set_cell_sizes_plural {
    ui::collection_layout layout{{.frame = {.size = {3.0f, 0.0f}}, .preferred_cell_count = 5}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(layout.cell_sizes().size(), 1);
    XCTAssertEqual(layout.cell_sizes().at(0), (ui::float_size{1.0f, 1.0f}));

    layout.set_cell_sizes({{1.0f, 1.0f}, {2.0f, 2.0f}, {3.0f, 3.0f}});

    XCTAssertEqual(layout.cell_sizes().size(), 3);
    XCTAssertEqual(layout.cell_sizes().at(0), (ui::float_size{1.0f, 1.0f}));
    XCTAssertEqual(layout.cell_sizes().at(1), (ui::float_size{2.0f, 2.0f}));
    XCTAssertEqual(layout.cell_sizes().at(2), (ui::float_size{3.0f, 3.0f}));

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

- (void)test_set_cell_sizes_zero_width {
    ui::collection_layout layout{
        {.frame = {.size = {3.0f, 0.0f}}, .preferred_cell_count = 3, .cell_sizes = {{0.0f, 1.0f}}}};

    auto const &cell_guide_rects = layout.cell_layout_guide_rects();

    XCTAssertEqual(layout.actual_cell_count(), 3);

    XCTAssertEqual(cell_guide_rects.at(0).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).right().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(0).bottom().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(0).top().value(), 1.0f);

    XCTAssertEqual(cell_guide_rects.at(1).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(1).right().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(1).bottom().value(), 1.0f);
    XCTAssertEqual(cell_guide_rects.at(1).top().value(), 2.0f);

    XCTAssertEqual(cell_guide_rects.at(2).left().value(), 0.0f);
    XCTAssertEqual(cell_guide_rects.at(2).right().value(), 3.0f);
    XCTAssertEqual(cell_guide_rects.at(2).bottom().value(), 2.0f);
    XCTAssertEqual(cell_guide_rects.at(2).top().value(), 3.0f);
}

- (void)test_set_row_spacing {
    ui::collection_layout layout{
        {.frame = {.size = {2.0f, 0.0f}}, .preferred_cell_count = 3, .cell_sizes = {{1.0f, 1.0f}}}};

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
        {.frame = {.size = {3.0f, 0.0f}}, .preferred_cell_count = 3, .cell_sizes = {{1.0f, 1.0f}}}};

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
                                  .cell_sizes = {{2.0f, 1.0f}},
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
                                  .cell_sizes = {{2.0f, 1.0f}},
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
                                  .cell_sizes = {{1.0f, 1.0f}},
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
                                  .cell_sizes = {{1.0f, 1.0f}},
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
                                  .cell_sizes = {{1.0f, 1.0f}},
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
                                  .cell_sizes = {{1.0f, 1.0f}},
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
                                  .cell_sizes = {{1.0f, 1.0f}},
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
                                  .cell_sizes = {{1.0f, 1.0f}},
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
                                  .cell_sizes = {{1.0f, 1.0f}},
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
                                  .cell_sizes = {{1.0f, 1.0f}},
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

@end