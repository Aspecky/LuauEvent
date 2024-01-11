---
outline: deep
---

# Signal
```lua
type Signal<T...> = {
	Connect: <U...>(self: Signal<T...>, fn: (...unknown) -> (), U...) -> Connection<U...>,
	Once: <U...>(self: Signal<T...>, fn: (...unknown) -> (), U...) -> Connection<U...>,
	Wait: (self: Signal<T...>) -> T...,
}
```

## Methods

### Connect

### Once

### Wait