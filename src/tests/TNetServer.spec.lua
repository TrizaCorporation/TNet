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
    end)
end