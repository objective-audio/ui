//
//  yas_ui_effect.h
//

#pragma once

#include <Metal/Metal.h>
#include "yas_flagset.h"
#include "yas_protocol.h"

namespace yas::ui {
class texture;

enum class effect_update_reason : std::size_t {
    textures,
    handler,

    count,
};

using effect_updates_t = flagset<effect_update_reason>;

struct renderable_effect : protocol {
    struct impl : protocol::impl {
        virtual void set_textures(ui::texture &&src, ui::texture &&dst) = 0;
        virtual ui::effect_updates_t &updates() = 0;
        virtual void clear_updates() = 0;
    };

    explicit renderable_effect(std::shared_ptr<impl>);
    renderable_effect(std::nullptr_t);

    void set_textures(ui::texture src, ui::texture dst);
    ui::effect_updates_t const &updates();
    void clear_updates();
};

struct encodable_effect : protocol {
    struct impl : protocol::impl {
        virtual void encode(id<MTLCommandBuffer> const) = 0;
    };

    explicit encodable_effect(std::shared_ptr<impl>);
    encodable_effect(std::nullptr_t);

    void encode(id<MTLCommandBuffer> const);
};
}  // namespace yas::ui

namespace yas {
std::string to_string(ui::effect_update_reason const &);
std::string to_string(ui::effect_updates_t const &);
}  // namespace yas
