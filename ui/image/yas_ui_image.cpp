//
//  yas_ui_image.cpp
//

#include "yas_ui_image.h"

using namespace yas;

ui::image::image(ui::image::args const &args)
    : _point_size(args.point_size),
      _scale_factor(args.scale_factor),
      _actual_size(uint_size{static_cast<uint32_t>(args.point_size.width * args.scale_factor),
                             static_cast<uint32_t>(args.point_size.height * args.scale_factor)}) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = static_cast<CGBitmapInfo>(kCGImageAlphaPremultipliedLast);
    this->_bitmap_context = CGBitmapContextCreate(NULL, this->_actual_size.width, this->_actual_size.height, 8,
                                                  this->_actual_size.width * 4, colorSpace, bitmapInfo);
    CGColorSpaceRelease(colorSpace);
}

ui::image::~image() {
    CGContextRelease(this->_bitmap_context);
}

ui::uint_size ui::image::point_size() const {
    return this->_point_size;
}

ui::uint_size ui::image::actual_size() const {
    return this->_actual_size;
}

double ui::image::scale_factor() const {
    return this->_scale_factor;
}

const void *ui::image::data() const {
    return CGBitmapContextGetData(this->_bitmap_context);
}

void *ui::image::data() {
    return CGBitmapContextGetData(this->_bitmap_context);
}

void ui::image::clear() {
    CGContextClearRect(this->_bitmap_context, CGRectMake(0, 0, this->_actual_size.width, this->_actual_size.height));
}

void ui::image::draw(ui::draw_handler_f const &function) {
    CGContextSaveGState(this->_bitmap_context);

    CGContextTranslateCTM(this->_bitmap_context, 0.0, this->_actual_size.height);
    CGContextScaleCTM(this->_bitmap_context, (CGFloat)this->_actual_size.width / (CGFloat)this->_point_size.width,
                      -(CGFloat)this->_actual_size.height / (CGFloat)this->_point_size.height);
    function(this->_bitmap_context);

    CGContextRestoreGState(this->_bitmap_context);
}

ui::image_ptr ui::image::make_shared(args const &args) {
    return std::shared_ptr<image>(new image{std::move(args)});
}
