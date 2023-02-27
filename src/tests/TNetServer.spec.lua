return function ()
    local Server = require(script.Parent.Parent.Server)

    describe("Server", function()
        local TNet = Server.new()

        it("should be a table", function()
            expect(typeof(TNet) == "table").to.be.ok()
        end)

        it("should have middleware as an empty table", function()
            expect(#TNet.Middleware == 0).to.be.ok()
        end)

        local RemoteHandler

        it("should handle a new event", function()
            local Event = Instance.new("RemoteEvent")

            local success = pcall(function()
                RemoteHandler = TNet:HandleRemoteEvent(Event)
            end)

            expect(success).to.be.ok()
        end)

        it("should error on no client", function()
            local success = pcall(function()
                RemoteHandler:Fire()
            end)

            expect(not success).to.be.ok()
        end)
    end)
end