hs.autoLaunch(true)
hs.menuIcon(true)
hs.automaticallyCheckForUpdates(true)
hs.consoleOnTop(true)
hs.dockIcon(false)
hs.uploadCrashData(false)
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

bindSwitcher({"cmd"}, "I", "com.apple.Safari", function()
   return createSwitcher({"Safari", "Chromium", "Firefox"})
end)

bindSwitcher({"cmd", "shift"}, "Space", "com.apple.Terminal", function()
   return createSwitcher({"Terminal"})
end)

