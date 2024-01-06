require('hs.ipc')

hs.autoLaunch(true)
hs.menuIcon(false)
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
hs.hotkey.bind({ 'cmd' }, 'I', function()
  hs.application.launchOrFocusByBundleID('com.apple.Safari')
end)

-- Cmd + D
hs.hotkey.bind({ 'cmd' }, 'D', function()
  hs.application.launchOrFocusByBundleID('com.microsoft.vscode')
end)
