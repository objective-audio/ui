//
//  yas_ui_button.h
//

#pragma once

#include "yas_base.h"
#include "yas_flagset.h"
#include "yas_flow.h"
#include "yas_ui_types.h"

namespace yas::ui {
class rect_plane;
class layout_guide_rect;
class touch_event;
class texture;

class button : public base {
   public:
    class impl;

    enum class method {
        began,
        entered,
        moved,
        leaved,
        ended,
        canceled,
    };

    struct context {
        ui::button const &button;
        ui::touch_event const &touch;
    };

    button(ui::region const &region);
    button(ui::region const &region, std::size_t const state_count);
    button(std::nullptr_t);

    virtual ~button() final;

    void set_texture(ui::texture);
    ui::texture const &texture() const;

    std::size_t state_count() const;
    void set_state_index(std::size_t const);
    std::size_t state_index() const;

    void cancel_tracking();

    using flow_pair_t = std::pair<method, context>;
    flow::node_t<flow_pair_t, false> begin_flow() const;

    ui::rect_plane &rect_plane();

    ui::layout_guide_rect &layout_guide_rect();
};
}  // namespace yas::ui

namespace yas {
std::size_t to_rect_index(std::size_t const state_idx, bool is_tracking);
std::string to_string(ui::button::method const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::button::method const &);
