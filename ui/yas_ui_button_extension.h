//
//  yas_ui_button_extension.h
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

    class button_extension : public base {
       public:
        class impl;

        enum class state : std::size_t {
            toggle,
            press,

            count,
        };

        using states_t = flagset<state>;
        using state_size_t = typename std::underlying_type<state>::type;

        static std::size_t const state_count = static_cast<state_size_t>(ui::button_extension::state::count);

        enum class method {
            began,
            entered,
            leaved,
            ended,
            canceled,
        };

        using subject_t = subject<button_extension, method>;
        using observer_t = observer<button_extension, method>;

        button_extension(ui::float_region const &region);
        button_extension(std::nullptr_t);

        virtual ~button_extension() final;

        subject_t &subject();

        ui::rect_plane &rect_plane();
    };
}

std::size_t to_index(ui::button_extension::states_t const &);
std::string to_string(ui::button_extension::state const &);
std::string to_string(ui::button_extension::method const &);
}

std::ostream &operator<<(std::ostream &, yas::ui::button_extension::state const &);
std::ostream &operator<<(std::ostream &, yas::ui::button_extension::method const &);
