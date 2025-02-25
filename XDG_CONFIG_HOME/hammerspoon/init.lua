hs = hs
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
ConfigWatcher = hs.pathwatcher.new(hs.configdir, hs.reload):start()

-- Browser and Terminal.app hotkeys
hs.hotkey.bind({ 'cmd' }, 'I', function()
  hs.application.launchOrFocusByBundleID('com.apple.Safari')
end)

hs.hotkey.bind({ 'cmd' }, 'D', function()
  hs.application.launchOrFocusByBundleID('com.mitchellh.ghostty')
end)

-- Set to variable to avoid GC
CmdTerminal = hs.eventtap
  .new({ hs.eventtap.event.types.keyDown }, function(e)
    if e:getFlags():containExactly({ 'cmd' }) then
      if
        e:getKeyCode() == hs.keycodes.map.p
        and (
          hs.application.frontmostApplication():bundleID()
            == 'com.apple.Terminal'
          or hs.application.frontmostApplication():bundleID()
            == 'com.mitchellh.ghostty'
        )
      then
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.p, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.p, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.p, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
        return true
      elseif
        e:getKeyCode() == hs.keycodes.map.r
        and (
          hs.application.frontmostApplication():bundleID()
            == 'com.apple.Terminal'
          or hs.application.frontmostApplication():bundleID()
            == 'com.mitchellh.ghostty'
        )
      then
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.r, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.r, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.r, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
        return true
      elseif
        e:getKeyCode() == hs.keycodes.map.f
        and (
          hs.application.frontmostApplication():bundleID()
            == 'com.apple.Terminal'
          or hs.application.frontmostApplication():bundleID()
            == 'com.mitchellh.ghostty'
        )
      then
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.f, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.f, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.f, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
        return true
      elseif
        e:getKeyCode() == hs.keycodes.map['`']
        and hs.application.frontmostApplication():bundleID()
          == 'com.mitchellh.ghostty'
      then
        local all = hs.window.focusedWindow():application():allWindows()
        all[#all]:focus()
        return true
      end
    end
  end)
  :start()
