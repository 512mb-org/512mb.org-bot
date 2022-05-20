return function(sec)
    local hours = math.floor(sec/3600)
    local minutes = math.floor((sec - hours*3600)/60)
    local seconds = sec - (hours*3600) - (minutes*60)
    hours = ((hours < 10) and ("0"..hours)) or hours
    minutes = ((minutes < 10) and ("0"..minutes)) or minutes
    seconds = ((seconds < 10) and ("0"..seconds)) or seconds
    return ((tonumber(hours) > 0 and hours..":") or "")..minutes..":"..seconds
end
