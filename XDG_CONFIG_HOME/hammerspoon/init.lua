hs.autoLaunch(true)
hs.menuIcon(true)
hs.automaticallyCheckForUpdates(true)
hs.consoleOnTop(true)
hs.dockIcon(false)
hs.uploadCrashData(false)
configWatcher = hs.pathwatcher.new(hs.configdir, hs.reload):start()

function createBrowserSwitcher()
   switcher_browsers = hs.window.switcher.new(
      hs.window.filter.new{"Safari", "Google Chrome", "Firefox"},
      {
         backgroundColor                 = {0.03, 0.03, 0.03, 0.75},
         highlightColor                  = {0.6, 0.3, 0.0, 0.75},
         showThumbnails                  = false,
         showSelectedTitle               = false,
         showTitles                      = false
      }
   )
end

createBrowserSwitcher()
hs.hotkey.bind({"cmd"}, "I", function()
   switcher_browsers:next()
   if hs.application.get("Safari") == nil then
      hs.application.launchOrFocus("Safari")
      createBrowserSwitcher()
   end
end)

function createTerminalSwitcher()
   switcher_terminals = hs.window.switcher.new(hs.window.filter.new{"Terminal"}, {
      backgroundColor                 = {0.03, 0.03, 0.03, 0.75},
      highlightColor                  = {0.6, 0.3, 0.0, 0.75},
      showThumbnails                  = false,
      showSelectedTitle               = false,
      showTitles                      = false
   })
end

createTerminalSwitcher()
hs.hotkey.bind({"cmd", "shift"}, "Space", function()
   switcher_terminals:next()
   if hs.application.get("com.apple.Terminal") == nil then
      hs.application.launchOrFocus("Terminal")
      createTerminalSwitcher()
   end
end)