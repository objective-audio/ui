//
//  yas_ui_image.cpp
//

#include "yas_ui_image.h"

using namespace yas;

struct ui::image::impl : base::impl {
    impl(uint_size const point_size, double const scale_factor)
        : _point_size(point_size),
          _scale_factor(scale_factor),
          _actual_size(uint_size{static_cast<uint32_t>(point_size.width * scale_factor),
                                 static_cast<uint32_t>(point_size.height * scale_factor)}) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = static_cast<CGBitmapInfo>(kCGImageAlphaPremultipliedLast);
        _bitmap_context = CGBitmapContextCreate(NULL, _actual_size.width, _actual_size.height, 8,
                                                _actual_size.width * 4, colorSpace, bitmapInfo);
        CGColorSpaceRelease(colorSpace);
    }

    ~impl() {
        CGContextRelease(_bitmap_context);
    }

    void clear() {
        CGContextClearRect(_bitmap_context, CGRectMake(0, 0, _actual_size.width, _actual_size.height));
    }

    void draw(std::function<void(CGContextRef const)> const &function) {
        CGContextSaveGState(_bitmap_context);

        CGContextTranslateCTM(_bitmap_context, 0.0, _actual_size.height);
        CGContextScaleCTM(_bitmap_context, (CGFloat)_actual_size.width / (CGFloat)_point_size.width,
                          -(CGFloat)_actual_size.height / (CGFloat)_point_size.height);
        function(_bitmap_context);

        CGContextRestoreGState(_bitmap_context);
    }

    uint_size _point_size;
    double _scale_factor;
    uint_size _actual_size;
    CGContextRef _bitmap_context;
};

ui::image::image(ui::image::args args) : base(std::make_shared<impl>(args.point_size, args.scale_factor)) {
}

ui::image::image(std::nullptr_t) : base(nullptr) {
}

ui::image::~image() = default;

ui::uint_size ui::image::point_size() const {
    return impl_ptr<impl>()->_point_size;
}

ui::uint_size ui::image::actual_size() const {
    return impl_ptr<impl>()->_actual_size;
}

double ui::image::scale_factor() const {
    return impl_ptr<impl>()->_scale_factor;
}

const void *ui::image::data() const {
    return CGBitmapContextGetData(impl_ptr<impl>()->_bitmap_context);
}

void *ui::image::data() {
    return CGBitmapContextGetData(impl_ptr<impl>()->_bitmap_context);
}

void ui::image::clear() {
    impl_ptr<impl>()->clear();
}

void ui::image::draw(std::function<void(CGContextRef const)> const &function) {
    impl_ptr<impl>()->draw(function);
}
