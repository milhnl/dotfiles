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
