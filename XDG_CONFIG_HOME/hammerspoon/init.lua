hs.autoLaunch(true)
hs.menuIcon(true)
hs.automaticallyCheckForUpdates(true)
hs.consoleOnTop(true)
hs.dockIcon(false)
hs.uploadCrashData(false)
hs.window.filter.ignoreAlways['Music Networking'] = true
hs.window.filter.ignoreAlways['Electron Helper'] = true
hs.window.filter.ignoreAlways['Electron Helper (Renderer)'] = true
hs.window.filter.ignoreAlways['Mail Networking'] = true
configWatcher = hs.pathwatcher.new(hs.configdir, hs.reload):start()

-- Cmd + I
function runOrRaise(bundleID, names)
    local windows = hs.window.filter.new(names):getWindows()
    if windows == nil then
        hs.application.launchOrFocusByBundleID(bundleID)
    else
        windows[1]:focus()
    end
end

hs.hotkey.bind({"cmd"}, "I", function()
    runOrRaise("com.apple.Safari", {"Safari"})
end)

-- Cmd + Space
function retry_nil(n, func)
    local rval = nil
    repeat
        rval = func()
        n = n - 1
    until rval ~= nil or n <= 0
    return rval
end

function retry_p(n, func)
    local rval = nil
    repeat
        n = n - 1
    until pcall(function() rval = func() end) or n <= 0
    return rval
end

function windowById(id)
    return hs.fnutils.find(
        allWindows(),
        function(x)
            return x:id() == id
        end
    )
end

function allWindows()
    return hs.fnutils.concat(
        retry_p(9, function() return hs.window.filter.new() end):getWindows(),
        retry_p(0, function()
            return hs.application.get("com.microsoft.VSCode"):allWindows()
        end) or {}
    )
end

chooser = hs.chooser.new(function(x)
    if x ~= nil and x.id ~= nil then
        local window = retry_nil(0, function() return windowById(x.id) end)
        if window ~= nil then
            window:focus()
        else
            print("wtf")
        end
    end
end):searchSubText(true):choices(function()
    return hs.fnutils.imap(
        allWindows(),
        function(x)
            local subText = x:application():name()
            if subText == "Safari" then subText = "Browser" end
            return {
                ["text"] = x:title(),
                ["subText"] = subText,
                ["id"] = x:id()
            }
        end
    )
end)

hs.hotkey.bind({"cmd"}, "Space", function() chooser:query(""):refreshChoicesCallback():show() end)
