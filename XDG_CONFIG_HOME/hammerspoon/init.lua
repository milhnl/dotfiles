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

function runOrRaise(bundleID, names)
    local windows = hs.window.filter.new(names):getWindows()
    if windows == nil or next(windows) == nil then
        hs.application.launchOrFocusByBundleID(bundleID)
    else
        windows[1]:focus()
    end
end

-- Cmd + I
hs.hotkey.bind({"cmd"}, "I", function()
    hs.application.launchOrFocusByBundleID("com.apple.Safari")
end)
