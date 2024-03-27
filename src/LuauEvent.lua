--!optimize 2
--!native

export type Connection<U...> = {
	Connected: boolean,
	Disconnect: (self: Connection<U...>) -> (),
	Reconnect: (self: Connection<U...>) -> (),
}

export type Signal<T...> = {
	Connect: <U...>(self: Signal<T...>, fn: (...any) -> (), U...) -> Connection<U...>,
	Once: <U...>(self: Signal<T...>, fn: (...any) -> (), U...) -> Connection<U...>,
	Wait: (self: Signal<T...>) -> T...,
}

export type Event<T...> = {
	Event: Signal<T...>,
	RBXScriptConnection: RBXScriptConnection?,

	Fire: (self: Event<T...>, T...) -> (),
	DisconnectAll: (self: Event<T...>) -> (),
	Destroy: (self: Event<T...>) -> (),
}

local Connection = {}
Connection.__index = Connection

local function Disconnect(self)
	if not self.Connected then
		return
	end
	self.Connected = false

	local next = self._next
	local prev = self._prev

	if next then
		next._prev = prev
	end
	if prev then
		prev._next = next
	end

	local event = self._event
	if event._head == self then
		event._head = next
	end
end
Connection.Disconnect = Disconnect

local function Reconnect(self)
	if self.Connected then
		return
	end
	self.Connected = true

	local event = self._event
	local head = event._head
	if head then
		head._prev = self
	end
	event._head = self

	self._next = head
	self._prev = false
end
Connection.Reconnect = Reconnect

--\\ Signal //--
local Signal = {}
Signal.__index = Signal

local function Connect(self, fn, ...)
	local event = self._event
	local head = event._head
	local cn = setmetatable({
		Connected = true,
		_event = event,
		_fn = fn,
		_varargs = if not ... then false else { ... },
		_next = head,
		_prev = false,
	}, Connection)

	if head then
		head._prev = cn
	end
	event._head = cn

	return cn
end
Signal.Connect = Connect

local function Once(self, fn, ...)
	local cn
	cn = Connect(self, function(...)
		Disconnect(cn)
		fn(...)
	end, ...)
	return cn
end
Signal.Once = Once

local function Wait(self)
	local thread = coroutine.running()
	local cn
	cn = Connect(self, function(...)
		Disconnect(cn)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end
Signal.Wait = Wait

--\\ Event //--
local Event = {}
Event.__index = Event

-- stylua: ignore
local rbxConnect, rbxDisconnect do
	local event = Instance.new("BindableEvent").Event
	local cn = event:Connect(function() end)
	rbxConnect = event.Connect
	rbxDisconnect = cn.Disconnect
end

local freeThreads: { thread } = {}

local function runCallback(callback, thread, ...)
	callback(...)
	table.insert(freeThreads, thread)
end

local function yielder()
	while true do
		runCallback(coroutine.yield())
	end
end

local function Fire(self, ...)
	local cn = self._head
	while cn do
		local thread
		if #freeThreads > 0 then
			thread = freeThreads[#freeThreads]
			freeThreads[#freeThreads] = nil
		else
			thread = coroutine.create(yielder)
			coroutine.resume(thread)
		end

		if not cn._varargs then
			task.spawn(thread, cn._fn, thread, ...)
		else
			local args = cn._varargs
			local len = #args
			local count = len
			for _, value in { ... } do
				count += 1
				args[count] = value
			end

			task.spawn(thread, cn._fn, thread, table.unpack(args))

			for i = count, len + 1, -1 do
				args[i] = nil
			end
		end

		cn = cn._next
	end
end
Event.Fire = Fire

local function DisconnectAll(self)
	local cn = self._head
	while cn do
		Disconnect(cn)
		cn = cn._next
	end
end
Event.DisconnectAll = DisconnectAll

local function Destroy(self)
	DisconnectAll(self)
	local cn = self.RBXScriptConnection
	if cn then
		rbxDisconnect(cn)
		self.RBXScriptConnection = nil
	end
end
Event.Destroy = Destroy

function Event.new<T...>(): Event<T...>
	local self = setmetatable({ _head = false }, Event)
	self.Event = setmetatable({ _event = self }, Signal)
	return self
end

function Event.wrap<T...>(signal: RBXScriptSignal): Event<T...>
	local self = setmetatable({ _head = false }, Event)
	self.Event = setmetatable({ _event = self }, Signal)

	self.RBXScriptConnection = rbxConnect(signal, function(...)
		Fire(self, ...)
	end)

	return self
end

return { new = Event.new, wrap = Event.wrap }
