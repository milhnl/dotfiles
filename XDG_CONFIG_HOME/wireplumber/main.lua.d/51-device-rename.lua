rules = {
  { "Tiger Lake*Speaker ? Headphones", "Internal" },
  { "Tiger Lake*Controller Headphones", "Headphones" },
  { "Tiger Lake*Controller Speaker", "Speaker" },
  { "Tiger Lake*DisplayPort 1 Output", "HDMI 1" },
  { "Tiger Lake*DisplayPort 2 Output", "HDMI 2" },
  { "Tiger Lake*DisplayPort 3 Output", "HDMI 3" },
}
for _, rule in ipairs(rules) do
  table.insert(alsa_monitor.rules, {
    matches = { { { "node.description", "matches", rule[1] } } },
    apply_properties = { ["node.description"] = rule[2] },
  })
end
