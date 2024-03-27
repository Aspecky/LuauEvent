local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LuauEvent = require(ReplicatedStorage.LuauEvent)

return function()
	local bindable = Instance.new("BindableEvent")
	local event = LuauEvent.wrap(bindable.Event)

	event.Event:Connect(function(...)
		print(...) --> 1 2 3
	end, 1)

	bindable:Fire(2, 3)

	return function()
		bindable:Destroy()
		event:Destroy()
	end
end
