//
//  yas_ui_static_mesh_data.h
//

#pragma once

#include <ui/yas_ui_mesh_data.h>

namespace yas::ui {
template <typename T>
struct static_mesh_data final : mesh_data<T> {
    [[nodiscard]] T const *raw_data() const override;
    [[nodiscard]] std::size_t count() const override;

    void write_once(std::function<void(std::vector<T> &)> const &);

    [[nodiscard]] std::size_t byte_offset() override;
    [[nodiscard]] id<MTLBuffer> mtlBuffer() override;

    [[nodiscard]] mesh_data_updates_t const &updates() override;
    void update_render_buffer() override;
    void clear_updates() override;

    [[nodiscard]] ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    [[nodiscard]] static std::shared_ptr<static_mesh_data> make_shared(std::size_t const);

   private:
    std::vector<T> _raw;
    mesh_data_updates_t _updates;
    std::shared_ptr<ui::metal_buffer> _mtl_buffer = nullptr;
    std::shared_ptr<ui::metal_system> _metal_system = nullptr;

    static_mesh_data(std::size_t const);
};
}  // namespace yas::ui
