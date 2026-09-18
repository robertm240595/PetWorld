local Service = {}

local Plots = {}

function Service:Register(plot)
    table.insert(Plots, plot)
end

function Service:GetAvailable()
    for _, plot in ipairs(Plots) do
        if not plot:GetAttribute("OwnerUserId") or plot:GetAttribute("OwnerUserId") == 0 then
            return plot
        end
    end
end

function Service:Claim(player, plotNumber)
    for _, plot in ipairs(Plots) do
        local owner = plot:GetAttribute("OwnerUserId")

        if owner == player.UserId then
            return plot
        end
    end

    local selected

    if plotNumber then
        for _, plot in ipairs(Plots) do
            if plot:GetAttribute("PlotNumber") == plotNumber then
                if not plot:GetAttribute("OwnerUserId") or plot:GetAttribute("OwnerUserId") == 0 then
                    selected = plot
                end
            end
        end
    end

    if not selected then
        selected = self:GetAvailable()
    end

    if selected then
        selected:SetAttribute("OwnerUserId", player.UserId)
        return selected
    end
end

function Service:GetPlayerPlot(player)
    for _, plot in ipairs(Plots) do
        if plot:GetAttribute("OwnerUserId") == player.UserId then
            return plot
        end
    end
end

function Service:Release(player)
    local plot = self:GetPlayerPlot(player)

    if plot then
        plot:SetAttribute("OwnerUserId", 0)
    end
end

return Service
