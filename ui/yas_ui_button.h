//
//  yas_ui_button.h
//

#pragma once

#include "yas_base.h"
#include "yas_flagset.h"
#include "yas_ui_types.h"

namespace yas {
template <typename T, typename K>
class subject;
template <typename T, typename K>
class observer;

namespace ui {
    class rect_plane;
    class layout_guide_rect;
    class touch_event;

    class button : public base {
       public:
        class impl;

        enum class method {
            began,
            entered,
            leaved,
            ended,
            canceled,
        };
        
        struct context {
            ui::button const &button;
            ui::touch_event const &touch;
        };

        using subject_t = subject<context, method>;
        using observer_t = observer<context, method>;

        button(ui::region const &region);
        button(ui::region const &region, std::size_t const state_count);
        button(std::nullptr_t);

        virtual ~button() final;

        std::size_t state_count() const;
        void set_state_index(std::size_t const);
        std::size_t state_index() const;

        subject_t &subject();

        ui::rect_plane &rect_plane();

        ui::layout_guide_rect &layout_guide_rect();
    };
}

std::size_t to_rect_index(std::size_t const state_idx, bool is_tracking);
std::string to_string(ui::button::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::button::method const &);
