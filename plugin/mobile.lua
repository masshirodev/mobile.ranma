-- mobile: ranma's view for a phone or tablet in Termux, over SSH.
--
-- Needs ranma 0.3.0 or newer. ranma's default setup declares it, so it is
-- there unless you said otherwise.
--
-- While a phone drives the screen (RANMA_MOBILE=1 on it, sent by SetEnv in
-- Termux's ~/.ssh/config with AcceptEnv RANMA_* in the far sshd, or
-- `ranma attach --mobile`), the "mobile" profile is in use:
--   one pane at a time with the others as tabs (layout = "monocle");
--   a three-row bar without the title (the tabs carry it) or the clock (the
--   phone shows one);
--   the "touch" toolbar along the bottom, three rows high, a thumb's height:
--     ≡ menu    the pane menu (there is no right click on a touch screen)
--     + new     a new pane
--     ◀ prev    focus the previous pane
--     ▶ next    focus the next pane
--     ◆ leader  the leader; tapped again, out of WM mode
--     ⌨ keys    open the phone's keyboard, which a tap on a pane does not
--               while ranma takes the mouse (`send esc` before ranma has the
--               keyboard action)
--     ⊞ spaces  the workspace switcher
--     ✕ close   close the pane
--   Past what fits, the last button becomes ⋯ for the rest.
-- When the desk drives again, the profile goes, and only if it is still
-- "mobile": a profile something else chose meanwhile (zen's) is left alone.
--
-- mobile.follow (default on) is read each time the driver changes, so turning
-- it off in the settings panel stops the switching from then on. The toolbar
-- and the profile stay defined either way, for a bind of your own:
--   ranma.bind("P", "profile mobile")   -- and `profile none` to go back
--
-- Your own ranma.toolbar("touch", ...) or ranma.profile("mobile", ...) in
-- init.lua replaces this one's, since init.lua loads after plugins.
--
-- ranma's plugin API: https://github.com/masshirodev/ranma/blob/main/doc/CONFIG.md
-- ("A mobile view", "Profiles", "Toolbars").

ranma.option("mobile.follow", {
  type = "bool", default = true,
  name = "Follow the driver", desc = "Use the mobile profile while a phone or tablet drives the screen, "
    .. "and leave it when the desk does. Off, nothing switches by itself.",
})

-- Termux's extra-keys row already has Ctrl and Esc, so their slots are the
-- leader and the keyboard. Without that row, { "⌃", "latch ctrl", text =
-- "ctrl" } and { "⎋", "send esc", text = "esc" } are the two to add.
local keyboard = ranma.has and ranma.has("action.keyboard")
ranma.toolbar("touch", {
  position = "bottom",
  size = "large",
  buttons = {
    { "≡", "pane_menu", text = "menu" },
    { "+", "new_pane", text = "new" },
    { "◀", "focus prev", text = "prev" },
    { "▶", "focus next", text = "next" },
    { "◆", "leader", text = "leader" },
    keyboard and { "⌨", "keyboard", text = "keys" } or { "⎋", "send esc", text = "esc" },
    { "⊞", "workspace_switcher", text = "spaces" },
    { "✕", "close_pane", text = "close" },
  },
})

ranma.profile("mobile", {
  set = { layout = "monocle" },
  bar = { size = "large", center = {}, right = { "update" } },
  toolbars = { "touch" },
})

ranma.on("driver_change", function(c)
  if not ranma.get("mobile.follow") then return end
  local profile = ranma.state().profile
  if c.mobile then
    if profile ~= "mobile" then ranma.use_profile("mobile") end
  elseif profile == "mobile" then
    ranma.use_profile(nil)
  end
end)
