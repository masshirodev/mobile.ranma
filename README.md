# mobile.ranma

A plugin for [ranma](https://github.com/masshirodev/ranma), the terminal tiling window manager: its view for a phone or a tablet that attaches over SSH (Termux, say). One pane at a time, a large bar, and a row of buttons big enough for a thumb, used by itself while the phone drives the screen.

## Install

**ranma brings it along.** Its default setup declares it for [hako](https://github.com/masshirodev/hako.ranma) with `install = true`, so a first start installs it without asking. That covers an `init.lua` that never calls `require("hako").setup` itself.

An `init.lua` that does call `setup` declares its own plugins, so add it there, or in `~/.config/ranma/lua/plugins/mobile.lua`:

```lua
return { "masshirodev/mobile.ranma", install = true }
```

Or by hand, as ranma loads any package under `pack/*/start/`:

```sh
git clone https://github.com/masshirodev/mobile.ranma ~/.config/ranma/pack/plugins/start/mobile.ranma
```

Needs ranma 0.3.0 or newer. The keyboard button needs the `keyboard` action (`ranma.has("action.keyboard")`); before it, that slot sends Esc.

### Not wanted

Turn it off in `~/.config/ranma/lua/plugins/mobile.lua`:

```lua
return { "masshirodev/mobile.ranma", enabled = false }
```

hako merges that over the default, so it is neither installed nor loaded, and `clean` deletes a copy already there. To keep it installed and only stop the switching, turn `mobile.follow` off instead (below).

## The phone's side

Tell ranma the terminal is a phone. In Termux's `~/.ssh/config`:

```sshconfig
Host desk
  SetEnv RANMA_MOBILE=1
```

and on the far end, `AcceptEnv RANMA_*` in `sshd_config`. Or attach with `ranma attach --mobile`.

## What it does

```text
While a phone drives the screen (RANMA_MOBILE=1 on it, sent by SetEnv in
Termux's ~/.ssh/config with AcceptEnv RANMA_* in the far sshd, or
`ranma attach --mobile`), the "mobile" profile is in use:
  one pane at a time with the others as tabs (layout = "monocle");
  a three-row bar without the title (the tabs carry it) or the clock (the
  phone shows one);
  the "touch" toolbar along the bottom, three rows high, a thumb's height:
    ≡ menu    the pane menu (there is no right click on a touch screen)
    + new     a new pane
    ◀ prev    focus the previous pane
    ▶ next    focus the next pane
    ◆ leader  the leader; tapped again, out of WM mode
    ⌨ keys    open the phone's keyboard, which a tap on a pane does not
              while ranma takes the mouse (`send esc` before ranma has the
              keyboard action)
    ⊞ spaces  the workspace switcher
    ✕ close   close the pane
  Past what fits, the last button becomes ⋯ for the rest.
When the desk drives again, the profile goes, and only if it is still
"mobile": a profile something else chose meanwhile (zen's) is left alone.
```

What gives way as the phone's keyboard takes half the screen (the tab strip, then the bar's size, the border, the toolbar's size, the toolbar) is ranma's, not this plugin's: see ranma's `doc/CONFIG.md`, "A mobile view".

## Options

In ranma's settings panel under `mobile`, or with hako's `opts` (`{ "masshirodev/mobile.ranma", opts = { follow = false } }`), or `ranma.set { mobile = { ... } }`.

| Option | Default | |
| --- | --- | --- |
| `mobile.follow` | `true` | Use the mobile profile while a phone or tablet drives the screen, and leave it when the desk does. Off, nothing switches by itself. Read each time the driver changes, so a change applies at once. |

With `follow` off, the toolbar and the profile are still defined, for a bind of your own:

```lua
ranma.bind("P", "profile mobile")   -- `profile none` goes back
```

## Making it yours

`init.lua` loads after plugins, and a second `ranma.toolbar("touch", ...)` or `ranma.profile("mobile", ...)` replaces the first. So the buttons are yours to change by defining the toolbar again, whole:

```lua
ranma.toolbar("touch", {
  position = "bottom", size = "large",
  buttons = {
    { "≡", "pane_menu", text = "menu" },
    { "⌃", "latch ctrl", text = "ctrl" },   -- a terminal without Termux's extra-keys row
    { "⎋", "send esc", text = "esc" },
    { "⊞", "workspace_switcher", text = "spaces" },
  },
})
```

A button is `{ label, action }`, with `text` shown beside the label where there is room; the action may be a Lua function, as in a bind. `position` is `top`, `bottom` or `beside` (the bar's rows, when it fits there), `size` is `normal` or `large`.

## How it works

Everything here is configuration ranma already takes: a `ranma.toolbar`, a `ranma.profile` and a `driver_change` hook. Laying the buttons out, answering taps, and what gives way on a short screen stay in ranma, which never runs Lua while it draws. It was ranma's default `init.lua` until 2026-10-15, when it moved here so a phone switches by itself without five lines pasted into every config, and so it can be turned off whole (ranma's `doc/DESIGN.md`, "The mobile view becomes a plugin ranma carries").

## License

MIT or Apache-2.0, as ranma.
