--[[
	Queue data structure implemented in lua
]]

local queue = {};

function queue.new()
  local _queue = {};
  local first = 0;
  local last = -1;
  local count = 0;

  function _queue.Enqueue(value)
    local index = last + 1
    last = index
    _queue[index] = value
    count = count + 1;
  end

  function _queue.Dequeue()
    local first = queue.first
    if first > queue.last then error("queue is empty") end
    local value = queue[first]
    queue[first] = nil        -- to allow garbage collection
    queue.first = first + 1
    count = count - 1;
    return value
  end

	return _queue;
end

return queue.new();