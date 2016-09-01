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

    class button : public base {
       public:
        class impl;

        enum class state : std::size_t {
            toggle,
            press,

            count,
        };

        using states_t = flagset<state>;
        using state_size_t = typename std::underlying_type<state>::type;

        static std::size_t const state_count = static_cast<state_size_t>(ui::button::state::count);

        enum class method {
            began,
            entered,
            leaved,
            ended,
            canceled,
        };

        using subject_t = subject<button, method>;
        using observer_t = observer<button, method>;

        button(ui::float_region const &region);
        button(std::nullptr_t);

        virtual ~button() final;

        subject_t &subject();

        ui::rect_plane &rect_plane();

        ui::layout_guide_rect &layout_guide_rect();
    };
}

std::size_t to_index(ui::button::states_t const &);
std::string to_string(ui::button::state const &);
std::string to_string(ui::button::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::button::state const &);
std::ostream &operator<<(std::ostream &, yas::ui::button::method const &);
