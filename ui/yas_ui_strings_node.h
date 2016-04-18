//
//  yas_ui_strings_node.h
//

#pragma once

namespace yas {
namespace ui {
    class font_atlas;
    class square_node;

    class strings_node : public base {
        using super_class = base;

       public:
        strings_node(font_atlas, std::size_t const max_word_count = 16);
        strings_node(std::nullptr_t);

        std::string const &text() const;
        ui::pivot pivot() const;
        float width() const;

        void set_text(std::string);
        void set_pivot(ui::pivot const);

        ui::square_node &square_node();

       private:
        class impl;
    };
}
}
