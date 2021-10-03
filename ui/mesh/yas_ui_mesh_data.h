//
//  yas_ui_vertex_data.h
//

#pragma once

#import <Metal/Metal.h>
#include <ui/yas_ui_metal_setup_types.h>
#include <ui/yas_ui_renderer_dependency.h>

namespace yas::ui {
template <typename T>
struct mesh_data {
    virtual ~mesh_data() = default;

    [[nodiscard]] T const *raw_data() const;
    [[nodiscard]] std::size_t count() const;

    [[nodiscard]] bool data_exists() const;

    virtual void write(std::function<void(std::vector<T> &)> const &);

    [[nodiscard]] virtual std::size_t byte_offset();
    [[nodiscard]] id<MTLBuffer> mtlBuffer();

    [[nodiscard]] mesh_data_updates_t const &updates();
    void update_render_buffer();
    void clear_updates();

    [[nodiscard]] ui::setup_metal_result metal_setup(std::shared_ptr<ui::metal_system> const &);

    [[nodiscard]] static std::shared_ptr<mesh_data> make_shared(std::size_t const);

   protected:
    std::size_t _count;
    std::vector<T> _raw;
    std::size_t _dynamic_buffer_index = 0;
    mesh_data_updates_t _updates;

    mesh_data(std::size_t const);

    virtual std::size_t dynamic_buffer_count();

   private:
    std::shared_ptr<ui::metal_system> _metal_system = nullptr;

    std::shared_ptr<ui::metal_buffer> _mtl_buffer;
};

template <typename T>
struct dynamic_mesh_data final : mesh_data<T> {
    [[nodiscard]] std::size_t max_count() const;

    void set_count(std::size_t const);

    void write(std::function<void(std::vector<T> &)> const &) override;

    [[nodiscard]] std::size_t byte_offset() override;

    [[nodiscard]] std::size_t dynamic_buffer_count() override;

    [[nodiscard]] static std::shared_ptr<dynamic_mesh_data> make_shared(std::size_t const);

   private:
    dynamic_mesh_data(std::size_t const);
};
}  // namespace yas::ui
