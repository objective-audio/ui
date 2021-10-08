//
//  yas_ui_dynamic_mesh_data.h
//

#pragma once

#include <ui/yas_ui_mesh_data.h>

namespace yas::ui {
template <typename T>
struct dynamic_mesh_data final : mesh_data<T> {
    [[nodiscard]] T const *raw_data() const override;
    [[nodiscard]] std::size_t max_count() const;
    [[nodiscard]] std::size_t count() const override;
    void set_count(std::size_t const);

    void write(std::function<void(std::vector<T> &)> const &);

    [[nodiscard]] std::size_t byte_offset() override;
    [[nodiscard]] id<MTLBuffer> mtlBuffer() override;

    [[nodiscard]] mesh_data_updates_t const &updates() override;
    void update_render_buffer() override;
    void clear_updates() override;

    [[nodiscard]] ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &) override;

    [[nodiscard]] static std::shared_ptr<dynamic_mesh_data> make_shared(std::size_t const);

   private:
    std::size_t _count;
    std::vector<T> _raw;
    std::size_t const _dynamic_buffer_count = 2;
    std::size_t _dynamic_buffer_index = 0;
    mesh_data_updates_t _updates;
    std::shared_ptr<ui::metal_buffer> _mtl_buffer = nullptr;
    std::shared_ptr<ui::metal_system> _metal_system = nullptr;

    dynamic_mesh_data(std::size_t const);
};
}  // namespace yas::ui
