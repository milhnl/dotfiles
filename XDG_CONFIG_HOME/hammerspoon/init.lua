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

-- Set to variable to avoid GC
cmdTerminal = hs.eventtap
  .new({ hs.eventtap.event.types.keyDown }, function(e)
    if e:getFlags():containExactly({ 'cmd' }) then
      if
        e:getKeyCode() == hs.keycodes.map.p
        and hs.application.frontmostApplication():bundleID()
          == 'com.apple.Terminal'
      then
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.p, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.p, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.p, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
        return true
      elseif
        e:getKeyCode() == hs.keycodes.map.f
        and hs.application.frontmostApplication():bundleID()
          == 'com.apple.Terminal'
      then
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.f, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.f, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.f, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
        return true
      end
    end
  end)
  :start()

-- Cmd + D
hs.hotkey.bind({ 'cmd' }, 'D', function()
  hs.application.launchOrFocusByBundleID('com.microsoft.vscode')
end)
