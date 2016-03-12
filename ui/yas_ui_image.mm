//
//  yas_ui_image.mm
//

#include <CoreGraphics/CoreGraphics.h>
#include "yas_ui_image.h"

using namespace yas;

struct ui::image::impl : public base::impl {
    impl(uint_size const point_size, Float64 const scale_factor)
        : point_size(point_size),
          scale_factor(scale_factor),
          actual_size(uint_size{static_cast<UInt32>(point_size.width * scale_factor),
                                static_cast<UInt32>(point_size.height * scale_factor)}) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = static_cast<CGBitmapInfo>(kCGImageAlphaPremultipliedLast);
        bitmap_context = CGBitmapContextCreate(NULL, actual_size.width, actual_size.height, 8, actual_size.width * 4,
                                               colorSpace, bitmapInfo);
        CGColorSpaceRelease(colorSpace);
    }

    ~impl() {
        CGContextRelease(bitmap_context);
    }

    void clear() {
        CGContextClearRect(bitmap_context, CGRectMake(0, 0, actual_size.width, actual_size.height));
    }

    void draw(std::function<void(CGContextRef const)> const &function) {
        CGContextSaveGState(bitmap_context);

        CGContextTranslateCTM(bitmap_context, 0.0, actual_size.height);
        CGContextScaleCTM(bitmap_context, (CGFloat)actual_size.width / (CGFloat)point_size.width,
                          -(CGFloat)actual_size.height / (CGFloat)point_size.height);
        function(bitmap_context);

        CGContextRestoreGState(bitmap_context);
    }

    uint_size point_size;
    Float64 scale_factor;
    uint_size actual_size;
    CGContextRef bitmap_context;
};

ui::image::image(uint_size const point_size, Float64 const scale_factor)
    : super_class(std::make_shared<impl>(point_size, scale_factor)) {
}

ui::image::image(std::nullptr_t) : super_class(nullptr) {
}

ui::uint_size ui::image::point_size() const {
    return impl_ptr<impl>()->point_size;
}

ui::uint_size ui::image::actual_size() const {
    return impl_ptr<impl>()->actual_size;
}

Float64 ui::image::scale_factor() const {
    return impl_ptr<impl>()->scale_factor;
}

const void *ui::image::data() const {
    return CGBitmapContextGetData(impl_ptr<impl>()->bitmap_context);
}

void *ui::image::data() {
    return CGBitmapContextGetData(impl_ptr<impl>()->bitmap_context);
}

void ui::image::clear() {
    impl_ptr<impl>()->clear();
}

void ui::image::draw(std::function<void(CGContextRef const)> const &function) {
    impl_ptr<impl>()->draw(function);
}

template <>
ui::image yas::cast<ui::image>(base const &base) {
    ui::image obj{nullptr};
    obj.set_impl_ptr(std::dynamic_pointer_cast<ui::image::impl>(base.impl_ptr()));
    return obj;
}
