//
//  yas_ui_button.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_flagset.h>
#include "yas_ui_types.h"

namespace yas::ui {
class rect_plane;
class layout_guide_rect;
class touch_event;
class texture;

struct button final : base, std::enable_shared_from_this<button> {
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
        std::shared_ptr<ui::button> const &button;
        ui::touch_event const &touch;
    };

    virtual ~button();

    void set_texture(ui::texture);
    ui::texture const &texture() const;

    std::size_t state_count() const;
    void set_state_index(std::size_t const);
    std::size_t state_index() const;

    void cancel_tracking();

    using chain_pair_t = std::pair<method, context>;
    [[nodiscard]] chaining::chain_unsync_t<chain_pair_t> chain() const;
    [[nodiscard]] chaining::chain_relayed_unsync_t<context, chain_pair_t> chain(method const) const;

    ui::rect_plane &rect_plane();

    ui::layout_guide_rect &layout_guide_rect();

   private:
    button(ui::region const &region, std::size_t const state_count);

    void _prepare();

   public:
    static std::shared_ptr<button> make_shared(ui::region const &);
    static std::shared_ptr<button> make_shared(ui::region const &, std::size_t const state_count);
};
}  // namespace yas::ui

namespace yas {
std::size_t to_rect_index(std::size_t const state_idx, bool is_tracking);
std::string to_string(ui::button::method const &);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::ui::button::method const &);
