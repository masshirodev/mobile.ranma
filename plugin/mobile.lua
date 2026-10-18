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
--     ⇅ inner   where the buttons act: in the ranma inside the focused pane
--               (the desk's, over SSH, when the phone runs its own) while
--               that pane is focused, or "here" when tapped to stay on this
--               one; tapped again, back to following (needs a ranma with
--               `toolbar_target` on both; without it the button is not there)
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
-- Inside another ranma (the phone runs one of its own, and this one is in
-- its pane over SSH), the "mobile_nested" profile instead: monocle only. The
-- outer ranma already draws the touch toolbar and this one's bar, so a
-- second toolbar would only stack under the first.
-- When the desk drives again, the profile goes, and only if it is still one
-- of these two: a profile something else chose meanwhile (zen's) is left alone.
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
local target = ranma.has and ranma.has("action.toolbar_target")
local buttons = {
  { "≡", "pane_menu", text = "menu" },
  { "+", "new_pane", text = "new" },
  { "◀", "focus prev", text = "prev" },
  { "▶", "focus next", text = "next" },
  { "◆", "leader", text = "leader" },
  keyboard and { "⌨", "keyboard", text = "keys" } or { "⎋", "send esc", text = "esc" },
  { "⊞", "workspace_switcher", text = "spaces" },
  { "✕", "close_pane", text = "close" },
}
-- Its text is ranma's: "inner" or "here", for where the buttons act now.
if target then table.insert(buttons, 1, { "⇅", "toolbar_target" }) end
ranma.toolbar("touch", {
  position = "bottom",
  size = "large",
  buttons = buttons,
})

ranma.profile("mobile", {
  set = { layout = "monocle" },
  bar = { size = "large", center = {}, right = { "update" } },
  toolbars = { "touch" },
})

-- Nested, the outer ranma's toolbar and bar are the phone's.
ranma.profile("mobile_nested", {
  set = { layout = "monocle" },
})

ranma.on("driver_change", function(c)
  if not ranma.get("mobile.follow") then return end
  local profile = ranma.state().profile
  local want = c.outer and "mobile_nested" or "mobile"
  if c.mobile then
    if profile ~= want then ranma.use_profile(want) end
  elseif profile == "mobile" or profile == "mobile_nested" then
    ranma.use_profile(nil)
  end
end)
