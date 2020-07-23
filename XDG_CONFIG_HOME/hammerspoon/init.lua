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

-- Bind switchers. I want them to be blindingly fast, so maximize caching
function createSwitcher(filter)
   return hs.window.switcher.new(
      hs.window.filter.new(filter),
      {
         backgroundColor = {0.03, 0.03, 0.03, 0.75},
         highlightColor = {0.6, 0.3, 0.0, 0.75},
         showThumbnails = false,
         showSelectedTitle = false,
         showTitles = false
      }
   )
end

function bindSwitcher(mods, key, launchBundleID, createFunc)
   local switcher = createFunc()
   hs.hotkey.bind(mods, key, function()
      switcher:next()
      if hs.application.get(launchBundleID) == nil then
         hs.application.launchOrFocusByBundleID(launchBundleID)
         createFunc()
      end
   end)
end

bindSwitcher({"cmd", "shift"}, "Space", "com.apple.Terminal", function()
   return createSwitcher({"Terminal"})
end)

bindSwitcher({"cmd"}, "m", "com.apple.Music", function()
   return createSwitcher({"Music", "Spotify"})
end)

bindSwitcher({"cmd"}, "d", "com.microsoft.VSCode", function()
   return createSwitcher({"Code", "Remote Desktop"})
end)

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
