local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Dependencies = script:WaitForChild("Dependencies")
local ConnectionCreator = require(Dependencies.Connection)

local NetSignal = {}
NetSignal.__index = NetSignal

local NetSignalEvent = {}

local NetSignalFunction = {}

function NetSignal.new(type: string, event)
  assert(type == "Event" or type == "Function", "You must provide a valid NetSignalType.")
  local self = setmetatable({}, NetSignal)
  self.Event = event
  self.Connections = {}
  if type == "Event" then
    event[string.format("On%sEvent", RunService:IsServer() and "Server" or "Client")]:Connect(function(player, ...)
      self:HandleInboundRequest(player, ...)
    end)
  elseif type == "Function" then
    event[string.format("On%sInvoke", RunService:IsServer() and "Server" or "Client")] = function(player, ...)
      return self:HandleInboundRequest(player, ...)
    end
  end
  self.MiddlewareCoroutine = coroutine.create(function()
    while true do
      if self.Middleware and self.Middleware.RequestsPerMinute then
        self.RequestsLeft = self.Middleware.RequestsPerMinute
      end
      task.wait(60)
    end
  end)
  coroutine.resume(self.MiddlewareCoroutine)
  for property, value in type == "Event" and NetSignalEvent or NetSignalFunction do
    if typeof(value) == "function" then
      self[property] = value
    end
  end
  return self
end

function NetSignalEvent:Wait()
  local WaitingCoroutine = coroutine.running()
  local Connection
  Connection = self:Connect(function()
    Connection:Disconnect()
    task.spawn(WaitingCoroutine)
  end)
  return coroutine.yield()
end

function NetSignalEvent:Fire(...)
  self:HandleOutboundRequest(...)
  if RunService:IsServer() then
    self.Event:FireClient(...)
  else
    self.Event:FireServer(...)
  end
end

function NetSignalEvent:FireAllClients(...)
  assert(RunService:IsServer(), "FireAllClients can only be called on the server.")
  self:HandleOutboundRequest(Players:GetPlayers(), ...)
  self.Event:FireAllClients(Players:GetPlayers(), ...)
end

function NetSignalEvent:FireToGroup(group, ...)
  assert(RunService:IsServer(), "FireToGroup can only be called on the server.")
  for _, player in group do
    assert(player:IsA("Player"), "Each player in the group must be a player.")
  end
  for _, player in group do
    self.Event:FireClient(player, ...)
  end
  self:HandleOutboundRequest(group, ...)
end


function NetSignalFunction:Wait()
  local WaitingCoroutine = coroutine.running()
  local Connection
  Connection = self:Connect(function()
    Connection:Disconnect()
    task.spawn(WaitingCoroutine)
  end)
  return coroutine.yield()
end

function NetSignalFunction:Fire(...)
  self:HandleOutboundRequest(...)
  if RunService:IsServer() then
    return self.Event:InvokeClient(...)
  else
    return self.Event:InvokeServer(...)
  end
end

function NetSignal:HandleInboundRequest(player, ...)
  if self.Middleware and self.Middleware.RequestsPerMinute then
    if not self.RequestsLeft then
      self.RequestsLeft = self.Middleware.RequestsPerMinute
    end
    if self.RequestsLeft > 0 then
      self.RequestsLeft -= 1
    else
      error("Rate Limit Reached.")
    end
  end
  if self.Middleware and self.Middleware.Inbound then
    for _, func in self.Middleware.Inbound do
      task.spawn(func, player, self.Event, {...})
    end
  end
  RunService.Stepped:Wait()
  for _, connection in self.Connections do
    if connection.Function then
      return connection.Function(player, ...)
    else
      table.remove(self.Connections, table.find(self.Connections, connection))
    end
  end
end

function NetSignal:HandleOutboundRequest(...)
  if self.Middleware and self.Middleware.Outbound then
    for _, func in self.Middleware.Outbound do
      task.spawn(func, self.Event, {...})
    end
  end
end

function NetSignal:Connect(...)
  local Connection = ConnectionCreator.new(...)
  table.insert(self.Connections, Connection)
  return Connection
end

function NetSignal:Destroy()
  coroutine.close(self.MiddlewareCoroutine)
  setmetatable(self, nil)
  for property, _ in self do
    self[property] = nil
  end
  self = nil
end

return NetSignal