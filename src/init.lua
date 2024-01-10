--!optimize 2
--!native

export type Connection<U...> = {
	Connected: boolean,
	Disconnect: (self: Connection<U...>) -> (),
	Reconnect: (self: Connection<U...>) -> (),
}

export type Signal<T...> = {
	Connect: <U...>(self: Signal<T...>, fn: (...unknown) -> (), U...) -> Connection<U...>,
	Once: <U...>(self: Signal<T...>, fn: (...unknown) -> (), U...) -> Connection<U...>,
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

local function disconnect(self)
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

local function reconnect(self)
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

Connection.Disconnect = disconnect
Connection.Reconnect = reconnect

--\\ Signal //--
local Signal = {}
Signal.__index = Signal

local function connect(self, fn, ...)
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

local function once(self, fn, ...)
	-- Implement :Once() in terms of a connection which disconnects
	-- itself before running the handler.
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		fn(...)
	end, ...)
	return cn
end

local function wait(self)
	local thread = coroutine.running()
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

Signal.Connect = connect
Signal.Once = once
Signal.Wait = wait

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

local function executeCallback(signal, fn, ...)
	local acquiredRunnerThread = signal._callerThread
	signal._callerThread = false
	fn(...)
	signal._callerThread = acquiredRunnerThread
end

local function callbackQueuer(signal, ...)
	executeCallback(signal, ...)
	while true do
		executeCallback(coroutine.yield())
	end
end

local function fire(self, ...)
	local cn = self._head
	while cn do
		local callerThread = self._callerThread
		if not callerThread then
			self._callerThread = coroutine.create(callbackQueuer)
			callerThread = self._callerThread
		end

		if not cn._varargs then
			task.spawn(callerThread, self, cn._fn, ...)
		else
			local args = cn._varargs
			local len = #args
			local count = len
			for _, value in { ... } do
				count += 1
				args[count] = value
			end

			task.spawn(callerThread, self, cn._fn, table.unpack(args))

			for i = count, len + 1, -1 do
				args[i] = nil
			end
		end

		cn = cn._next
	end
end

local function disconnectAll(self)
	local cn = self._head
	while cn do
		disconnect(cn)
		cn = cn._next
	end
end

local function destroy(self)
	disconnectAll(self)
	local cn = self.RBXScriptConnection
	if cn then
		rbxDisconnect(cn)
		self.RBXScriptConnection = nil
	end
end

--\\ Constructors
function Event.new<T...>(): Event<T...>
	local self = setmetatable({ _head = false, _callerThread = false }, Event)
	self.Event = setmetatable({ _event = self }, Signal)
	return self
end

function Event.wrap<T...>(signal: RBXScriptSignal): Event<T...>
	local self = setmetatable({ _head = false, _callerThread = false }, Event)
	self.Event = setmetatable({ _event = self }, Signal)

	self.RBXScriptConnection = rbxConnect(signal, function(...)
		fire(self, ...)
	end)

	return self
end

--\\ Methods
Event.Fire = fire
Event.DisconnectAll = disconnectAll
Event.Destroy = destroy

return { new = Event.new, wrap = Event.wrap }
