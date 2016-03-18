//
//  yas_ui_metal_view_tests.mm
//

#import <XCTest/XCTest.h>
#import <iostream>
#import "yas_ui_metal_view.h"

@interface YASMetalViewTestDelegate : NSObject <YASMetalViewDelegate>

@property (nonatomic) BOOL drawableSizeWillChangeCalled;
@property (nonatomic) CGSize drawableSize;
@property (nonatomic) BOOL drawInMetalViewCalled;

@end

@implementation YASMetalViewTestDelegate

- (void)reset {
    self.drawableSizeWillChangeCalled = NO;
    self.drawableSize = CGSizeZero;
    self.drawInMetalViewCalled = NO;
}

- (void)metalView:(YASMetalView *)view drawableSizeWillChange:(CGSize)size {
    self.drawableSizeWillChangeCalled = YES;
    self.drawableSize = size;
}

- (void)drawInMetalView:(YASMetalView *)view {
    self.drawInMetalViewCalled = YES;
}

@end

@interface yas_ui_metal_view_mac_tests : XCTestCase

@end

@implementation yas_ui_metal_view_mac_tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_create {
    auto device = MTLCreateSystemDefaultDevice();
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    YASMetalView *view = [[YASMetalView alloc] initWithFrame:CGRectMake(0, 0, 512, 256)];

    XCTAssertNil(view.delegate);
    XCTAssertNotNil(view.device);
    XCTAssertEqualObjects(view.device, device);
    XCTAssertNotNil(view.currentDrawable);
    XCTAssertNil(view.renderPassDescriptor);
    XCTAssertEqual(view.sampleCount, 1);
    XCTAssertFalse(view.paused);

    yas_release(view);
    yas_release(device);
}

- (void)test_delegate {
    auto device = MTLCreateSystemDefaultDevice();
    if (!device) {
        std::cout << "skip : " << __PRETTY_FUNCTION__ << std::endl;
        return;
    }

    YASMetalView *view = [[YASMetalView alloc] initWithFrame:CGRectMake(0, 0, 512, 256)];
    YASMetalViewTestDelegate *delegate = [[YASMetalViewTestDelegate alloc] init];
    view.delegate = delegate;
    yas_release(delegate);

    [delegate reset];

    [view draw];

    XCTAssertTrue(delegate.drawableSizeWillChangeCalled);
    XCTAssertTrue(CGSizeEqualToSize(delegate.drawableSize, CGSizeMake(512, 256)));
    XCTAssertTrue(delegate.drawInMetalViewCalled);

    [delegate reset];
    [view draw];

    XCTAssertFalse(delegate.drawableSizeWillChangeCalled);
    XCTAssertTrue(delegate.drawInMetalViewCalled);

    yas_release(view);
    yas_release(device);
}

@end
