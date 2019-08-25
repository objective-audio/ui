//
//  yas_ui_effect.h
//

#pragma once

#include <Metal/Metal.h>
#include <cpp_utils/yas_flagset.h>
#include <cpp_utils/yas_protocol.h>
#include "yas_ui_ptr.h"

namespace yas::ui {
enum class effect_update_reason : std::size_t {
    textures,
    handler,

    count,
};

using effect_updates_t = flagset<effect_update_reason>;

struct renderable_effect {
    virtual ~renderable_effect() = default;

    virtual void set_textures(ui::texture_ptr const &src, ui::texture_ptr const &dst) = 0;
    virtual ui::effect_updates_t &updates() = 0;
    virtual void clear_updates() = 0;
};

using renderable_effect_ptr = std::shared_ptr<renderable_effect>;

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
