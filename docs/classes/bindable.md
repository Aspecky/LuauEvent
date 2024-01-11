---
outline: deep
---

# Bindable
```lua
type Event<T...> = {
	Signal: Signal<T...>,
	RBXScriptConnection: RBXScriptConnection?,

	Fire: (self: Event<T...>, T...) -> (),
	DisconnectAll: (self: Event<T...>) -> (),
	Destroy: (self: Event<T...>) -> (),
}
```

## Properties

### Signal

### RBXScriptConnection

## Methods

### Fire

### DisconnectAll

### Destroy