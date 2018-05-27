//
//  yas_ui_justified_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_ui_flow_utils.h"
#import "yas_ui_layout_guide.h"

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

- (void)test_justify_with_ratios {
    std::array<float, 2> array{1.0f, 2.0f};
    auto justify = ui::justify<2>(array);
    auto justified = justify(std::make_pair(1.0f, 7.0f));

    XCTAssertEqual(std::get<0>(justified), 1.0f);
    XCTAssertEqual(std::get<1>(justified), 3.0f);
    XCTAssertEqual(std::get<2>(justified), 7.0f);
}

- (void)test_justify_without_ratios {
    auto justify = ui::justify<2>();
    auto justified = justify(std::make_pair(1.0f, 3.0f));

    XCTAssertEqual(std::get<0>(justified), 1.0f);
    XCTAssertEqual(std::get<1>(justified), 2.0f);
    XCTAssertEqual(std::get<2>(justified), 3.0f);
}

- (void)test_flow {
    ui::layout_guide first_src_guide{1.0f};
    ui::layout_guide second_src_guide{2.0f};
    ui::layout_guide first_dst_guide;
    ui::layout_guide second_dst_guide;
    std::array<flow::receiver<float>, 2> receivers{first_dst_guide.receiver(), second_dst_guide.receiver()};

    auto layout = first_src_guide.begin_flow()
                      .combine(second_src_guide.begin_flow())
                      .map(ui::justify<1>())
                      .receive(receivers)
                      .sync();

    XCTAssertTrue(layout);

    XCTAssertEqual(first_dst_guide.value(), 1.0f);
    XCTAssertEqual(second_dst_guide.value(), 2.0f);
}

- (void)test_flow_value_changed_one_dst {
    ui::layout_guide first_src_guide{0.0f};
    ui::layout_guide second_src_guide{0.0f};
    ui::layout_guide dst_guide{100.0f};

    auto layout = first_src_guide.begin_flow()
                      .combine(second_src_guide.begin_flow())
                      .map(ui::justify<2>())
                      .map([](std::array<float, 3> const &values) { return values[1]; })
                      .receive(dst_guide.receiver())
                      .sync();

    XCTAssertEqual(dst_guide.value(), 0.0f);

    second_src_guide.set_value(2.0f);

    XCTAssertEqual(dst_guide.value(), 1.0f);

    first_src_guide.set_value(-4.0f);

    XCTAssertEqual(dst_guide.value(), -1.0f);

    first_src_guide.set_value(2.0f);
    second_src_guide.set_value(0.0f);

    XCTAssertEqual(dst_guide.value(), 1.0f);
}

- (void)test_flow_many_dst {
    ui::layout_guide first_src_guide{-1.0f};
    ui::layout_guide second_src_guide{3.0f};
    ui::layout_guide dst_guide_0;
    ui::layout_guide dst_guide_1;
    ui::layout_guide dst_guide_2;
    std::array<flow::receiver<float>, 3> receivers{dst_guide_0.receiver(), dst_guide_1.receiver(),
                                                   dst_guide_2.receiver()};

    auto layout = first_src_guide.begin_flow()
                      .combine(second_src_guide.begin_flow())
                      .map(ui::justify<2>())
                      .receive(receivers)
                      .sync();

    XCTAssertEqual(dst_guide_0.value(), -1.0f);
    XCTAssertEqual(dst_guide_1.value(), 1.0f);
    XCTAssertEqual(dst_guide_2.value(), 3.0f);
}

- (void)test_flow_with_array_receivers {
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

- (void)test_flow_with_vector_receivers {
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
