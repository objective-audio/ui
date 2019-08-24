//
//  yas_ui_event.cpp
//

#include "yas_ui_event.h"
#include <unordered_map>
#include "yas_ui_types.h"

using namespace yas;

#pragma mark - event::impl

struct ui::event::impl_base : manageable_event::impl {
    virtual std::type_info const &type() const = 0;
    virtual bool is_equal(std::shared_ptr<impl_base> const &rhs) const = 0;

    void set_phase(event_phase &&st) override {
        this->phase = std::move(st);
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

    bool is_equal(std::shared_ptr<impl_base> const &rhs) const override {
        if (auto casted_rhs = std::dynamic_pointer_cast<impl>(rhs)) {
            auto &type_info = this->type();
            if (type_info == casted_rhs->type()) {
                return this->value == casted_rhs->value;
            }
        }

        return false;
    }

    std::type_info const &type() const override {
        return typeid(T);
    }
};

#pragma mark - event

ui::event::event(cursor const &) : _impl(std::make_shared<impl<ui::cursor>>()) {
}

ui::event::event(touch const &) : _impl(std::make_shared<impl<ui::touch>>()) {
}

ui::event::event(key const &) : _impl(std::make_shared<impl<ui::key>>()) {
}

ui::event::event(modifier const &) : _impl(std::make_shared<impl<ui::modifier>>()) {
}

ui::event::~event() = default;

ui::event_phase ui::event::phase() const {
    return this->_impl->phase;
}

std::type_info const &ui::event::type_info() const {
    return this->_impl->type();
}

template <typename T>
typename T::type const &ui::event::get() const {
    if (auto ip = std::dynamic_pointer_cast<impl<T>>(this->_impl)) {
        return ip->value;
    }

    static const typename T::type _default{};
    return _default;
}

template ui::cursor::type const &ui::event::get<ui::cursor>() const;
template ui::touch::type const &ui::event::get<ui::touch>() const;
template ui::key::type const &ui::event::get<ui::key>() const;
template ui::modifier::type const &ui::event::get<ui::modifier>() const;

uintptr_t ui::event::identifier() const {
    return reinterpret_cast<uintptr_t>(this);
}

ui::manageable_event &ui::event::manageable() {
    if (!this->_manageable) {
        this->_manageable = ui::manageable_event{this->_impl};
    }
    return this->_manageable;
}

bool ui::event::operator==(event const &rhs) const {
    return rhs._impl != nullptr && this->_impl->is_equal(rhs._impl);
}

bool ui::event::operator!=(event const &rhs) const {
    return !(*this == rhs);
}

ui::event_ptr ui::event::make_shared(cursor const &cursor) {
    return std::shared_ptr<event>(new event{cursor});
}

ui::event_ptr ui::event::make_shared(touch const &touch) {
    return std::shared_ptr<event>(new event{touch});
}

ui::event_ptr ui::event::make_shared(key const &key) {
    return std::shared_ptr<event>(new event{key});
}

ui::event_ptr ui::event::make_shared(modifier const &modifier) {
    return std::shared_ptr<event>(new event{modifier});
}

#pragma mark - event_manager::impl

struct ui::event_manager::impl : event_inputtable::impl {
    void input_cursor_event(cursor_event &&value) override {
        ui::event_phase phase;

        if (value.contains_in_window()) {
            if (this->_cursor_event) {
                phase = event_phase::changed;
            } else {
                phase = event_phase::began;
                this->_cursor_event = ui::event::make_shared(cursor_tag);
            }
        } else {
            phase = event_phase::ended;
        }

        if (this->_cursor_event) {
            auto manageable_event = this->_cursor_event->manageable();
            manageable_event.set_phase(phase);
            manageable_event.set<cursor>(std::move(value));

            this->_notifier->notify({.method = event_manager::method::cursor_changed, .event = this->_cursor_event});

            if (phase == event_phase::ended) {
                this->_cursor_event = nullptr;
            }
        }
    }

    void input_touch_event(event_phase const phase, touch_event &&value) override {
        auto const identifer = value.identifier();

        if (phase == event_phase::began) {
            if (this->_touch_events.count(identifer) > 0) {
                return;
            }
            ui::event_ptr event = ui::event::make_shared(touch_tag);
            this->_touch_events.emplace(std::make_pair(identifer, std::move(event)));
        }

        if (this->_touch_events.count(identifer) > 0) {
            auto &event = this->_touch_events.at(identifer);
            auto manageable_event = event->manageable();
            manageable_event.set_phase(phase);
            manageable_event.set<touch>(std::move(value));

            this->_notifier->notify({.method = event_manager::method::touch_changed, .event = event});

            if (phase == event_phase::ended || phase == event_phase::canceled) {
                this->_touch_events.erase(identifer);
            }
        }
    }

    void input_key_event(event_phase const phase, key_event &&value) override {
        auto const key_code = value.key_code();

        if (phase == event_phase::began) {
            if (this->_key_events.count(key_code) > 0) {
                return;
            }
            ui::event_ptr event = ui::event::make_shared(key_tag);
            this->_key_events.emplace(std::make_pair(key_code, std::move(event)));
        }

        if (this->_key_events.count(key_code) > 0) {
            auto const &event = this->_key_events.at(key_code);
            event->manageable().set_phase(phase);
            event->manageable().set<key>(value);

            this->_notifier->notify({.method = event_manager::method::key_changed, .event = event});

            if (phase == event_phase::ended || phase == event_phase::canceled) {
                this->_key_events.erase(key_code);
            }
        }
    }

    void input_modifier_event(modifier_flags &&flags, double const timestamp) override {
        static auto all_flags = {modifier_flags::alpha_shift, modifier_flags::shift,   modifier_flags::control,
                                 modifier_flags::alternate,   modifier_flags::command, modifier_flags::numeric_pad,
                                 modifier_flags::help,        modifier_flags::function};

        for (auto const &flag : all_flags) {
            if (flags & flag) {
                if (this->_modifier_events.count(flag) == 0) {
                    ui::event_ptr event = ui::event::make_shared(modifier_tag);
                    event->manageable().set<modifier>(ui::modifier_event{flag, timestamp});
                    event->manageable().set_phase(ui::event_phase::began);
                    this->_modifier_events.emplace(std::make_pair(flag, std::move(event)));

                    this->_notifier->notify(
                        {.method = event_manager::method::modifier_changed, .event = this->_modifier_events.at(flag)});
                }
            } else {
                if (this->_modifier_events.count(flag) > 0) {
                    auto const &event = this->_modifier_events.at(flag);
                    event->manageable().set_phase(ui::event_phase::ended);

                    this->_notifier->notify({.method = event_manager::method::modifier_changed, .event = event});

                    this->_modifier_events.erase(flag);
                }
            }
        }
    }

    chaining::chain_relayed_unsync_t<event_ptr, context> chain(method const &method) {
        return this->_notifier->chain()
            .guard([method](context const &context) { return context.method == method; })
            .to([](ui::event_manager::context const &context) { return context.event; });
    }

    chaining::chain_unsync_t<context> chain() {
        return this->_notifier->chain();
    }

    event_ptr _cursor_event{nullptr};
    std::unordered_map<uintptr_t, event_ptr> _touch_events;
    std::unordered_map<uint16_t, event_ptr> _key_events;
    std::unordered_map<uint32_t, event_ptr> _modifier_events;

    chaining::notifier_ptr<context> _notifier = chaining::notifier<context>::make_shared();
};

#pragma mark - manageable_event

ui::manageable_event::manageable_event(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::manageable_event::manageable_event(std::nullptr_t) : protocol(nullptr) {
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

ui::event_manager::event_manager() : _impl(std::make_shared<impl>()) {
}

ui::event_manager::~event_manager() = default;

chaining::chain_relayed_unsync_t<ui::event_ptr, ui::event_manager::context> ui::event_manager::chain(
    method const &method) const {
    return this->_impl->chain(method);
}

chaining::chain_unsync_t<ui::event_manager::context> ui::event_manager::chain() const {
    return this->_impl->chain();
}

ui::event_inputtable &ui::event_manager::inputtable() {
    if (!this->_inputtable) {
        this->_inputtable = ui::event_inputtable{this->_impl};
    }
    return this->_inputtable;
}

ui::event_manager_ptr ui::event_manager::make_shared() {
    return std::shared_ptr<event_manager>(new event_manager{});
}

#pragma mark -

std::string yas::to_string(ui::event const &event) {
    std::string type = "unknown";
    std::string values;

    if (event.type_info() == typeid(ui::cursor)) {
        type = "cursor";
        values = to_string(event.get<ui::cursor>());
    } else if (event.type_info() == typeid(ui::touch)) {
        type = "touch";
        values = to_string(event.get<ui::touch>());
    } else if (event.type_info() == typeid(ui::key)) {
        type = "key";
        values = to_string(event.get<ui::key>());
    } else if (event.type_info() == typeid(ui::modifier)) {
        type = "modifier";
        values = to_string(event.get<ui::modifier>());
    }

    return "{phase:" + to_string(event.phase()) + ", type:" + type + ", values:" + values + "}";
}

std::string yas::to_string(ui::event_manager::method const &method) {
    switch (method) {
        case ui::event_manager::method::cursor_changed:
            return "cursor_changed";
        case ui::event_manager::method::touch_changed:
            return "touch_changed";
        case ui::event_manager::method::key_changed:
            return "key_changed";
        case ui::event_manager::method::modifier_changed:
            return "modifier_changed";
    }
}

std::ostream &operator<<(std::ostream &os, yas::ui::event const &event) {
    os << to_string(event);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::ui::event_manager::method const &method) {
    os << to_string(method);
    return os;
}
