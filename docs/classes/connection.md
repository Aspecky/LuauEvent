---
outline: deep
---

# Connection

```lua
type Connection<U...> = {
	Connected: boolean,
	Disconnect: (self: Connection<U...>) -> (),
	Reconnect: (self: Connection<U...>) -> (),
}
```

## Properties

### Connected

## Methods

### Disconnect

### Reconnect