//
//  yas_ui_layout_guide.h
//

#pragma once

#include "yas_base.h"
#include "yas_observing.h"
#include "yas_ui_types.h"

namespace yas {
namespace ui {
    class layout_guide : public base {
        class impl;

       public:
        struct change_context {
            float const &old_value;
            float const &new_value;
            layout_guide const &layout_guide;
        };

        enum class method {
            value_changed,
        };

        using subject_t = subject<change_context, method>;
        using observer_t = observer<change_context, method>;

        layout_guide();
        layout_guide(float const);
        layout_guide(std::nullptr_t);

        virtual ~layout_guide() final;

        void set_value(float const);
        float const &value() const;

        subject_t &subject();
    };
}
}