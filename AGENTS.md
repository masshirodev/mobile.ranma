# AGENTS.md

mobile.ranma is a ranma plugin in Lua: `plugin/mobile.lua` is all of it, and
its header comment is the reference that `README.md` repeats. ranma's API is
https://github.com/masshirodev/ranma/blob/main/doc/CONFIG.md (`ranma --dump-types` prints it as LuaLS annotations).

- Push to `main`.
- ranma's default setup declares this plugin (`src/hako.rs`, `DEFAULT_SETUP`),
  so a change here reaches every install that has not turned it off. Keep it
  to what a phone needs; anything else is another plugin.
- A change to what it does changes the header comment and `README.md` in the
  same commit, and an option goes in the README's table.
- Use only what the latest ranma release has: CI loads the plugin into it. A
  newer feature goes behind `ranma.has(...)` with a fallback, as the keyboard
  button does (`action.keyboard`, else `send esc`).
- Before a commit: `tests/e2e.sh` (or `RANMA_BIN=<a build> tests/e2e.sh`), which
  plays the cases below on a private server with a desk and a phone attached.
- Check it loads: `ranma --check-config` lists every plugin and why one failed;
  `ranma lua` runs code in the live server.
- Test behaviour on a private server, never the one your terminal runs in:
  unset `RANMA_SOCKET RANMA RANMA_PANE TMUX`, point `RANMA_CONFIG_DIR` and
  the `XDG_*` directories at a temp dir, and drive ranma in a private tmux
  (`tmux -L <name>`), as ranma's `scripts/smoke.sh` does. Attach a second
  client with `ranma attach --mobile` to play the phone. Cases worth
  repeating: the phone takes the drive (profile on), the desk takes it back
  (profile off), zen on at the desk when the phone leaves (left alone),
  `mobile.follow = false` (nothing switches), and a reload while the phone
  drives.
- `AGENTS.local.md` (gitignored) carries what is true of one checkout on one
  machine. Never commit it.
