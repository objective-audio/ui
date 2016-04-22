//
//  yas_ui_event.mm
//

#include <unordered_map>
#include "yas_ui_event.h"
#include "yas_ui_types.h"

using namespace yas;

#pragma mark - event::impl

struct ui::event::impl_base : base::impl, manageable_event::impl {
    virtual std::type_info const &type() const = 0;

    void set_phase(event_phase &&st) override {
        phase = std::move(st);
    }

    event_phase phase = ui::event_phase::none;
};

template <typename T>
struct ui::event::impl : impl_base {
    typename T::type value;

    impl() {
    }

    impl(impl const &) = delete;
    impl(impl &&) = delete;
    impl &operator=(impl const &) = delete;
    impl &operator=(impl &&) = delete;

    ~impl() = default;

    virtual bool is_equal(std::shared_ptr<base::impl> const &rhs) const override {
        if (auto casted_rhs = std::dynamic_pointer_cast<impl>(rhs)) {
            auto &type_info = type();
            if (type_info == casted_rhs->type()) {
                return value == casted_rhs->value;
            }
        }

        return false;
    }

    std::type_info const &type() const override {
        return typeid(T);
    }
};

#pragma mark - event

ui::event::event(cursor const &) : super_class(std::make_shared<impl<ui::cursor>>()) {
}

ui::event::event(touch const &) : super_class(std::make_shared<impl<ui::touch>>()) {
}

ui::event::event(key const &) : super_class(std::make_shared<impl<ui::key>>()) {
}

ui::event::event(modifier const &) : super_class(std::make_shared<impl<ui::modifier>>()) {
}

ui::event::event(std::nullptr_t) : super_class(nullptr) {
}

ui::event_phase ui::event::phase() const {
    return impl_ptr<impl_base>()->phase;
}

std::type_info const &ui::event::type_info() const {
    return impl_ptr<impl_base>()->type();
}

template <typename T>
typename T::type const &ui::event::get() const {
    if (auto ip = std::dynamic_pointer_cast<impl<T>>(impl_ptr())) {
        return ip->value;
    }

    static const typename T::type _default{};
    return _default;
}

template ui::cursor::type const &ui::event::get<ui::cursor>() const;
template ui::touch::type const &ui::event::get<ui::touch>() const;
template ui::key::type const &ui::event::get<ui::key>() const;
template ui::modifier::type const &ui::event::get<ui::modifier>() const;

ui::manageable_event ui::event::manageable() {
    return ui::manageable_event{impl_ptr<ui::manageable_event::impl>()};
}

#pragma mark - event_manager::impl

struct ui::event_manager::impl : base::impl, event_inputtable::impl {
    void input_cursor_event(cursor_event &&value) override {
        ui::event_phase phase;

        if (value.contains_in_window()) {
            if (cursor_event) {
                phase = event_phase::changed;
            } else {
                phase = event_phase::began;
                cursor_event = ui::event{cursor_tag};
            }
        } else {
            phase = event_phase::ended;
        }

        if (cursor_event) {
            auto manageable_event = cursor_event.manageable();
            manageable_event.set_phase(phase);
            manageable_event.set<cursor>(std::move(value));

            if (subject.has_observer()) {
                subject.notify(event_method::cursor_changed, cursor_event);
            }

            if (phase == event_phase::ended) {
                cursor_event = nullptr;
            }
        }
    }

    void input_touch_event(event_phase const phase, touch_event &&value) override {
        auto const identifer = value.identifier();

        if (phase == event_phase::began) {
            if (touch_events.count(identifer) > 0) {
                return;
            }
            ui::event event{touch_tag};
            touch_events.emplace(std::make_pair(identifer, std::move(event)));
        }

        if (touch_events.count(identifer) > 0) {
            auto &event = touch_events.at(identifer);
            auto manageable_event = event.manageable();
            manageable_event.set_phase(phase);
            manageable_event.set<touch>(std::move(value));

            if (subject.has_observer()) {
                subject.notify(event_method::touch_changed, event);
            }

            if (phase == event_phase::ended || phase == event_phase::canceled) {
                touch_events.erase(identifer);
            }
        }
    }

    void input_key_event(event_phase const phase, key_event &&value) override {
        auto const key_code = value.key_code();

        if (phase == event_phase::began) {
            if (key_events.count(key_code) > 0) {
                return;
            }
            ui::event event{key_tag};
            key_events.emplace(std::make_pair(key_code, std::move(event)));
        }

        if (key_events.count(key_code) > 0) {
            auto &event = key_events.at(key_code);
            event.manageable().set_phase(phase);
            event.manageable().set<key>(value);

            if (subject.has_observer()) {
                subject.notify(event_method::key_changed, event);
            }

            if (phase == event_phase::ended || phase == event_phase::canceled) {
                key_events.erase(key_code);
            }
        }
    }

    void input_modifier_event(modifier_flags &&flags) override {
        static auto all_flags = {modifier_flags::alpha_shift, modifier_flags::shift,   modifier_flags::control,
                                 modifier_flags::alternate,   modifier_flags::command, modifier_flags::numeric_pad,
                                 modifier_flags::help,        modifier_flags::function};

        for (auto const &flag : all_flags) {
            if (flags & flag) {
                if (modifier_events.count(flag) == 0) {
                    ui::event event{modifier_tag};
                    event.manageable().set<modifier>(ui::modifier_event{flag});
                    event.manageable().set_phase(ui::event_phase::began);
                    modifier_events.emplace(std::make_pair(flag, std::move(event)));

                    if (subject.has_observer()) {
                        subject.notify(event_method::modifier_changed, modifier_events.at(flag));
                    }
                }
            } else {
                if (modifier_events.count(flag) > 0) {
                    auto &event = modifier_events.at(flag);
                    event.manageable().set_phase(ui::event_phase::ended);

                    if (subject.has_observer()) {
                        subject.notify(event_method::modifier_changed, event);
                    }

                    modifier_events.erase(flag);
                }
            }
        }
    }

    event cursor_event{nullptr};
    std::unordered_map<uintptr_t, event> touch_events;
    std::unordered_map<uint16_t, event> key_events;
    std::unordered_map<uint32_t, event> modifier_events;
    yas::subject<ui::event, ui::event_method> subject;
};

#pragma mark - manageable_event

ui::manageable_event::manageable_event(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

template <typename T>
void ui::manageable_event::set(typename T::type value) {
    if (auto ip = std::dynamic_pointer_cast<event::impl<T>>(impl_ptr<impl>())) {
        ip->value = std::move(value);
    } else {
        throw "dynamic_pointer_cast failed";
    }
}

template void ui::manageable_event::set<ui::cursor>(ui::cursor::type);
template void ui::manageable_event::set<ui::touch>(ui::touch::type);
template void ui::manageable_event::set<ui::key>(ui::key::type);
template void ui::manageable_event::set<ui::modifier>(ui::modifier::type);

void ui::manageable_event::set_phase(event_phase phase) {
    impl_ptr<impl>()->set_phase(std::move(phase));
}

#pragma mark - event_manager

ui::event_manager::event_manager() : super_class(std::make_shared<impl>()) {
}

ui::event_manager::event_manager(std::nullptr_t) : super_class(nullptr) {
}

subject<ui::event, ui::event_method> &ui::event_manager::subject() {
    return impl_ptr<impl>()->subject;
}

ui::event_inputtable ui::event_manager::inputtable() {
    return ui::event_inputtable{impl_ptr<ui::event_inputtable::impl>()};
}
