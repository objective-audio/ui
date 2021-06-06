//
//  yas_ui_justified_layout_tests.mm
//

#import <XCTest/XCTest.h>
#import <ui/ui.h>

using namespace yas;
using namespace yas::ui;

@interface yas_ui_justified_layout_tests : XCTestCase

@end

@implementation yas_ui_justified_layout_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_justify_with_array_ratios {
    std::array<float, 2> array{1.0f, 2.0f};
    auto justified = justify<2>(1.0f, 7.0f, array);

    XCTAssertEqual(std::get<0>(justified), 1.0f);
    XCTAssertEqual(std::get<1>(justified), 3.0f);
    XCTAssertEqual(std::get<2>(justified), 7.0f);
}

- (void)test_justify_without_ratios {
    auto justified = justify<2>(1.0f, 3.0f);

    XCTAssertEqual(std::get<0>(justified), 1.0f);
    XCTAssertEqual(std::get<1>(justified), 2.0f);
    XCTAssertEqual(std::get<2>(justified), 3.0f);
}

- (void)test_justify_functional_ratios {
    auto justified = justify(0.0f, 6.0f, 3, [](std::size_t const &idx) { return float(idx + 1); });

    XCTAssertEqual(justified.size(), 4);
    XCTAssertEqual(justified.at(0), 0.0f);
    XCTAssertEqual(justified.at(1), 1.0f);
    XCTAssertEqual(justified.at(2), 3.0f);
    XCTAssertEqual(justified.at(3), 6.0f);
}

- (void)test_justify_vector_ratios {
    std::vector ratios{1.0f, 2.0f, 3.0f};
    auto justified = justify(0.0f, 6.0f, ratios);

    XCTAssertEqual(justified.size(), 4);
    XCTAssertEqual(justified.at(0), 0.0f);
    XCTAssertEqual(justified.at(1), 1.0f);
    XCTAssertEqual(justified.at(2), 3.0f);
    XCTAssertEqual(justified.at(3), 6.0f);
}

- (void)test_observe {
    auto first_src_guide = layout_value_guide::make_shared(1.0f);
    auto second_src_guide = layout_value_guide::make_shared(2.0f);
    auto first_dst_guide = layout_value_guide::make_shared();
    auto second_dst_guide = layout_value_guide::make_shared();
    std::array<std::shared_ptr<layout_value_guide>, 2> receivers{first_dst_guide, second_dst_guide};

    auto first_cache = std::make_shared<std::optional<float>>();
    auto second_cache = std::make_shared<std::optional<float>>();

    auto justifying = [first_cache, second_cache, &receivers] {
        if (first_cache->has_value() && second_cache->has_value()) {
            auto const justified = justify<1>(**first_cache, **second_cache);
            receivers.at(0)->set_value(justified.at(0));
            receivers.at(1)->set_value(justified.at(1));
        }
    };

    auto first_layout = first_src_guide
                            ->observe([first_cache, justifying](float const &value) {
                                *first_cache = value;
                                justifying();
                            })
                            .sync();

    auto second_layout = second_src_guide
                             ->observe([second_cache, justifying](float const &value) {
                                 *second_cache = value;
                                 justifying();
                             })
                             .sync();

    XCTAssertTrue(first_layout);
    XCTAssertTrue(second_layout);

    XCTAssertEqual(first_dst_guide->value(), 1.0f);
    XCTAssertEqual(second_dst_guide->value(), 2.0f);
}

- (void)test_observe_value_changed_one_dst {
    auto first_src_guide = layout_value_guide::make_shared(0.0f);
    auto second_src_guide = layout_value_guide::make_shared(0.0f);
    auto dst_guide = layout_value_guide::make_shared(100.0f);

    auto first_cache = std::make_shared<std::optional<float>>();
    auto second_cache = std::make_shared<std::optional<float>>();

    auto justifying = [&dst_guide, first_cache, second_cache] {
        if (first_cache->has_value() && second_cache->has_value()) {
            auto justified = justify<2>(**first_cache, **second_cache);
            dst_guide->set_value(justified.at(1));
        }
    };

    auto first_layout = first_src_guide
                            ->observe([justifying, first_cache](float const &value) {
                                *first_cache = value;
                                justifying();
                            })
                            .sync();

    auto second_layout = second_src_guide
                             ->observe([justifying, second_cache](float const &value) {
                                 *second_cache = value;
                                 justifying();
                             })
                             .sync();

    XCTAssertEqual(dst_guide->value(), 0.0f);

    second_src_guide->set_value(2.0f);

    XCTAssertEqual(dst_guide->value(), 1.0f);

    first_src_guide->set_value(-4.0f);

    XCTAssertEqual(dst_guide->value(), -1.0f);

    first_src_guide->set_value(2.0f);
    second_src_guide->set_value(0.0f);

    XCTAssertEqual(dst_guide->value(), 1.0f);
}

- (void)test_observe_many_dst {
    auto first_src_guide = layout_value_guide::make_shared(-1.0f);
    auto second_src_guide = layout_value_guide::make_shared(3.0f);
    auto dst_guide_0 = layout_value_guide::make_shared();
    auto dst_guide_1 = layout_value_guide::make_shared();
    auto dst_guide_2 = layout_value_guide::make_shared();
    std::array<std::shared_ptr<layout_value_guide>, 3> receivers{dst_guide_0, dst_guide_1, dst_guide_2};

    auto first_cache = std::make_shared<std::optional<float>>();
    auto second_cache = std::make_shared<std::optional<float>>();

    auto justified = [&receivers, first_cache, second_cache] {
        if (first_cache->has_value() && second_cache->has_value()) {
            auto justified = justify<2>(**first_cache, **second_cache);
            receivers.at(0)->set_value(justified.at(0));
            receivers.at(1)->set_value(justified.at(1));
            receivers.at(2)->set_value(justified.at(2));
        }
    };

    auto first_layout = first_src_guide
                            ->observe([justified, first_cache](float const &value) {
                                *first_cache = value;
                                justified();
                            })
                            .sync();

    auto second_layout = second_src_guide
                             ->observe([justified, second_cache](float const &value) {
                                 *second_cache = value;
                                 justified();
                             })
                             .sync();

    XCTAssertEqual(dst_guide_0->value(), -1.0f);
    XCTAssertEqual(dst_guide_1->value(), 1.0f);
    XCTAssertEqual(dst_guide_2->value(), 3.0f);
}

- (void)test_zero_ratio {
    auto first_src_guide = layout_value_guide::make_shared(0.0f);
    auto second_src_guide = layout_value_guide::make_shared(2.0f);
    auto dst_guide = layout_value_guide::make_shared();

    auto first_cache = std::make_shared<std::optional<float>>();
    auto second_cache = std::make_shared<std::optional<float>>();

    auto justified = [&dst_guide, first_cache, second_cache] {
        if (first_cache->has_value() && second_cache->has_value()) {
            auto justified = justify(**first_cache, **second_cache);
            dst_guide->set_value(justified.at(0));
        }
    };

    auto first_layout = first_src_guide
                            ->observe([justified, first_cache](float const &value) {
                                *first_cache = value;
                                justified();
                            })
                            .sync();

    auto second_layout = second_src_guide
                             ->observe([justified, second_cache](float const &value) {
                                 *second_cache = value;
                                 justified();
                             })
                             .sync();

    XCTAssertEqual(dst_guide->value(), 1.0f);
}

@end
