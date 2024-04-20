//
//  yas_ui_multiple_touch_tests.mm
//

#import <XCTest/XCTest.h>

#include <ui/touch_tracker/yas_ui_multiple_touch.h>

using namespace std::chrono_literals;
using namespace yas;
using namespace yas::ui;

@interface yas_ui_multiple_touch_tests : XCTestCase

@end

@implementation yas_ui_multiple_touch_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_handled {
    auto time = std::chrono::system_clock::now();
    auto const provider = system_time_provider_stub::make_shared([&time] { return time; });
    auto const touch = ui::multiple_touch::make_shared(2, 0.3, provider);

    std::size_t called_count = 0;

    auto canceller = touch->observe([&called_count](auto const &) { ++called_count; }).end();

    {
        // 1回目

        touch->handle_event(ui::touch_tracker_phase::began, 1);
        touch->handle_event(ui::touch_tracker_phase::ended, 1);
        touch->handle_event(ui::touch_tracker_phase::began, 1);

        XCTAssertEqual(called_count, 0);

        time += 299ms;
        touch->handle_event(ui::touch_tracker_phase::ended, 1);

        XCTAssertEqual(called_count, 1);
    }

    {
        // 2回目

        touch->handle_event(ui::touch_tracker_phase::began, 1);
        touch->handle_event(ui::touch_tracker_phase::ended, 1);
        touch->handle_event(ui::touch_tracker_phase::began, 1);

        XCTAssertEqual(called_count, 1);

        touch->handle_event(ui::touch_tracker_phase::ended, 1);

        XCTAssertEqual(called_count, 2);
    }

    canceller->cancel();
}

- (void)test_timeout {
    auto time = std::chrono::system_clock::now();
    auto const provider = system_time_provider_stub::make_shared([&time] { return time; });
    auto const touch = ui::multiple_touch::make_shared(2, 0.3, provider);

    std::size_t called_count = 0;

    auto canceller = touch->observe([&called_count](auto const &) { ++called_count; }).end();

    touch->handle_event(ui::touch_tracker_phase::began, 1);
    touch->handle_event(ui::touch_tracker_phase::ended, 1);
    touch->handle_event(ui::touch_tracker_phase::began, 1);

    time += 300ms;
    touch->handle_event(ui::touch_tracker_phase::ended, 1);

    XCTAssertEqual(called_count, 0);

    canceller->cancel();
}

- (void)test_canceled {
    auto time = std::chrono::system_clock::now();
    auto const provider = system_time_provider_stub::make_shared([&time] { return time; });
    auto const touch = ui::multiple_touch::make_shared(2, 0.3, provider);

    std::size_t called_count = 0;

    auto canceller = touch->observe([&called_count](auto const &) { ++called_count; }).end();

    touch->handle_event(ui::touch_tracker_phase::began, 1);
    touch->handle_event(ui::touch_tracker_phase::ended, 1);
    touch->handle_event(ui::touch_tracker_phase::began, 1);
    touch->handle_event(ui::touch_tracker_phase::canceled, 1);
    touch->handle_event(ui::touch_tracker_phase::ended, 1);

    XCTAssertEqual(called_count, 0);

    canceller->cancel();
}

- (void)test_identifier_changed {
    auto time = std::chrono::system_clock::now();
    auto const provider = system_time_provider_stub::make_shared([&time] { return time; });
    auto const touch = ui::multiple_touch::make_shared(2, 0.3, provider);

    std::size_t called_count = 0;

    auto canceller = touch->observe([&called_count](auto const &) { ++called_count; }).end();

    touch->handle_event(ui::touch_tracker_phase::began, 1);
    touch->handle_event(ui::touch_tracker_phase::ended, 1);
    touch->handle_event(ui::touch_tracker_phase::began, 2);
    touch->handle_event(ui::touch_tracker_phase::ended, 2);
    touch->handle_event(ui::touch_tracker_phase::began, 1);
    touch->handle_event(ui::touch_tracker_phase::ended, 1);

    XCTAssertEqual(called_count, 0);

    touch->handle_event(ui::touch_tracker_phase::began, 1);
    touch->handle_event(ui::touch_tracker_phase::ended, 1);

    XCTAssertEqual(called_count, 1);

    canceller->cancel();
}

@end
