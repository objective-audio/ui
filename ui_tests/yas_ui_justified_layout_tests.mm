//
//  yas_ui_justified_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_layout.h"

using namespace yas;

@interface yas_ui_justified_layout_tests : XCTestCase

@end

@implementation yas_ui_justified_layout_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_make_flow {
    ui::layout_guide first_src_guide{1.0f};
    ui::layout_guide second_src_guide{2.0f};
    ui::layout_guide first_dst_guide;
    ui::layout_guide second_dst_guide;

    auto layout = ui::make_flow({.first_source_guide = first_src_guide,
                                 .second_source_guide = second_src_guide,
                                 .destination_guides = {first_dst_guide, second_dst_guide}});

    XCTAssertTrue(layout);

    XCTAssertEqual(first_dst_guide.value(), 1.0f);
    XCTAssertEqual(second_dst_guide.value(), 2.0f);
}

- (void)test_value_changed_one_dst {
    ui::layout_guide first_src_guide{0.0f};
    ui::layout_guide second_src_guide{0.0f};
    ui::layout_guide dst_guide{100.0f};

    auto layout = ui::make_flow({.first_source_guide = first_src_guide,
                                 .second_source_guide = second_src_guide,
                                 .destination_guides = {dst_guide}});

    XCTAssertEqual(dst_guide.value(), 0.0f);

    second_src_guide.set_value(2.0f);

    XCTAssertEqual(dst_guide.value(), 1.0f);

    first_src_guide.set_value(-4.0f);

    XCTAssertEqual(dst_guide.value(), -1.0f);

    first_src_guide.set_value(2.0f);
    second_src_guide.set_value(0.0f);

    XCTAssertEqual(dst_guide.value(), 1.0f);
}

- (void)test_many_dst {
    ui::layout_guide first_src_guide{-1.0f};
    ui::layout_guide second_src_guide{3.0f};
    ui::layout_guide dst_guide_0;
    ui::layout_guide dst_guide_1;
    ui::layout_guide dst_guide_2;

    auto layout = ui::make_flow({.first_source_guide = first_src_guide,
                                 .second_source_guide = second_src_guide,
                                 .destination_guides = {dst_guide_0, dst_guide_1, dst_guide_2}});

    XCTAssertEqual(dst_guide_0.value(), -1.0f);
    XCTAssertEqual(dst_guide_1.value(), 1.0f);
    XCTAssertEqual(dst_guide_2.value(), 3.0f);
}

- (void)test_ratios {
    ui::layout_guide first_src_guide{0.0f};
    ui::layout_guide second_src_guide{3.0f};
    ui::layout_guide dst_guide_0;
    ui::layout_guide dst_guide_1;
    ui::layout_guide dst_guide_2;

    auto layout = ui::make_flow({.first_source_guide = first_src_guide,
                                 .second_source_guide = second_src_guide,
                                 .destination_guides = {dst_guide_0, dst_guide_1, dst_guide_2},
                                 .ratios = {1.0f, 2.0f}});

    XCTAssertEqual(dst_guide_0.value(), 0.0f);
    XCTAssertEqual(dst_guide_1.value(), 1.0f);
    XCTAssertEqual(dst_guide_2.value(), 3.0f);
}

- (void)test_justify {
    std::array<float, 2> array{1.0f, 2.0f};
    auto justify = ui::justify<2>(array);
    auto justified = justify(std::make_pair(1.0f, 7.0f));

    XCTAssertEqual(std::get<0>(justified), 1.0f);
    XCTAssertEqual(std::get<1>(justified), 3.0f);
    XCTAssertEqual(std::get<2>(justified), 7.0f);
}

- (void)test_justify_flow_with_array_receivers {
    ui::layout_guide first_src_guide{0.0f};
    ui::layout_guide second_src_guide{3.0f};
    ui::layout_guide dst_guide_0;
    ui::layout_guide dst_guide_1;
    ui::layout_guide dst_guide_2;
    std::array<flow::receiver<float>, 3> receivers{dst_guide_0.receiver(), dst_guide_1.receiver(),
                                                   dst_guide_2.receiver()};

    std::array<float, 2> array{1.0f, 2.0f};

    auto flow = first_src_guide.begin_flow()
                    .combine(second_src_guide.begin_flow())
                    .map(ui::justify<2>(array))
                    .receive(receivers)
                    .sync();

    XCTAssertEqual(dst_guide_0.value(), 0.0f);
    XCTAssertEqual(dst_guide_1.value(), 1.0f);
    XCTAssertEqual(dst_guide_2.value(), 3.0f);
}

- (void)test_justify_flow_with_vector_receivers {
    ui::layout_guide first_src_guide{0.0f};
    ui::layout_guide second_src_guide{3.0f};
    ui::layout_guide dst_guide_0;
    ui::layout_guide dst_guide_1;
    ui::layout_guide dst_guide_2;
    std::vector<flow::receiver<float>> receivers{dst_guide_0.receiver(), dst_guide_1.receiver(),
                                                 dst_guide_2.receiver()};

    std::array<float, 2> array{1.0f, 2.0f};

    auto flow = first_src_guide.begin_flow()
                    .combine(second_src_guide.begin_flow())
                    .map(ui::justify<2>(array))
                    .receive(receivers)
                    .sync();

    XCTAssertEqual(dst_guide_0.value(), 0.0f);
    XCTAssertEqual(dst_guide_1.value(), 1.0f);
    XCTAssertEqual(dst_guide_2.value(), 3.0f);
}

@end
