#!/bin/bash
# mobile.ranma end to end: a private, headless ranma server (its own runtime,
# state and config directories, in a tmux server of its own) loading this
# checkout, a desk and a phone attached to it. Never touches a real session.
#
#   tests/e2e.sh                          with the ranma on PATH
#   RANMA_BIN=~/projects/ranma/target/release/ranma tests/e2e.sh
set -uo pipefail
BIN=${RANMA_BIN:-$(command -v ranma)}
PLUG=$(cd "$(dirname "$0")/.." && pwd)
W=$(mktemp -d /tmp/mob.XXXX); RT=$W/rt; mkdir -p $RT $W/cfg $W/state $W/data $W/cache
SOCK=mob-$$
T() { tmux -L $SOCK "$@"; }
ENV="env -u SSH_CONNECTION -u SSH_TTY -u SSH_CLIENT -u RANMA -u RANMA_SOCKET -u RANMA_PANE -u TMUX -u RANMA_MOBILE XDG_RUNTIME_DIR=$RT XDG_CACHE_HOME=$W/cache XDG_STATE_HOME=$W/state XDG_DATA_HOME=$W/data RANMA_CONFIG_DIR=$W/cfg RANMA_NO_UPDATE_CHECK=1 SHELL=/bin/bash"
RL() { $ENV RANMA_SOCKET=$RT/ranma/1.sock $BIN lua "$1" 2>&1; }
cleanup() { T kill-server 2>/dev/null; $ENV $BIN kill 1 >/dev/null 2>&1; $ENV $BIN kill 2 >/dev/null 2>&1; rm -rf $W; }
trap cleanup EXIT
fail() { echo "FAIL: $*"; exit 1; }
cat > $W/cfg/init.lua <<LUA
ranma.set { plugin_manager = "none" }
assert(ranma.packadd("$PLUG"))
LUA
$ENV $BIN --check-config >/dev/null 2>&1 || { $ENV $BIN --check-config; fail "check-config"; }
echo "ok   loads (check-config)"
T new-session -d -s desk -x 120 -y 30 "bash --norc"
T new-session -d -s phone -x 52 -y 34 "bash --norc"
T send-keys -t desk "$ENV $BIN attach 1" Enter
for _ in $(seq 40); do [ "$(RL 'return true')" = true ] && break; sleep 0.25; done
P() { RL 'return tostring(ranma.state().profile)' | tr -d '"'; }
[ "$(P)" = nil ] || fail "desk starts with a profile: $(P)"
T send-keys -t phone "$ENV RANMA_MOBILE=1 $BIN attach 1" Enter; sleep 1.5
T send-keys -t phone 'echo phone' Enter; sleep 1
[ "$(P)" = mobile ] || fail "phone driving: profile is $(P)"
# The keyboard button where ranma has the action, Esc before it.
key=$( [ "$(RL 'return ranma.has ~= nil and ranma.has("action.keyboard")')" = true ] && echo '⌨' || echo '⎋')
# With the selector first, nine faces need 53 columns: at 52 the last two
# fold into ⋯.
want="≡.*$key.*✕"
[ "$(RL 'return ranma.has("action.toolbar_target")')" = true ] && want="⇅.*≡.*$key.*⋯"
T capture-pane -p -t phone | grep -q "$want" || fail "the touch toolbar, with $key, is not on the phone"
echo "ok   the phone takes the drive: mobile profile, touch toolbar with $key"
T send-keys -t desk 'echo desk' Enter; sleep 1
[ "$(P)" = nil ] || fail "desk driving: profile is $(P)"
echo "ok   the desk takes it back: profile gone"
# A profile chosen at the desk while the phone drove (zen's, say) is left
# alone when the desk takes the screen back.
cat >> $W/cfg/init.lua <<'LUA'
ranma.profile("other", { set = { layout = "master" } })
LUA
$ENV RANMA_SOCKET=$RT/ranma/1.sock $BIN action reload_config; sleep 1
T send-keys -t phone 'echo phone2' Enter; sleep 1
[ "$(P)" = mobile ] || fail "phone again: $(P)"
$ENV RANMA_SOCKET=$RT/ranma/1.sock $BIN action "profile other"; sleep 0.5
T send-keys -t desk 'echo desk2' Enter; sleep 1
[ "$(P)" = other ] || fail "a profile picked meanwhile was taken away: $(P)"
echo "ok   a profile picked meanwhile is left alone"
$ENV RANMA_SOCKET=$RT/ranma/1.sock $BIN action "profile none"; sleep 0.3
# The phone runs a ranma of its own (server 2) and attaches to this one from
# its pane: the outer has the toolbar, and this one only goes monocle.
T new-session -d -s nest -x 52 -y 34 "bash --norc"
T send-keys -t nest "$ENV RANMA_MOBILE=1 $BIN attach 2" Enter; sleep 2
T send-keys -t nest "$ENV RANMA_MOBILE=1 $BIN attach 1" Enter; sleep 2
T send-keys -t nest 'echo nested' Enter; sleep 1
[ "$(P)" = mobile_nested ] || fail "nested phone: profile is $(P)"
P2=$($ENV RANMA_SOCKET=$RT/ranma/2.sock $BIN lua 'return tostring(ranma.state().profile)' 2>&1 | tr -d '"')
[ "$P2" = mobile ] || fail "the phone's own ranma: profile is $P2"
n=$(T capture-pane -p -t nest | grep -c "≡")
[ "$n" = 1 ] || fail "the touch toolbar shows $n times nested"
echo "ok   nested: the outer has the toolbar, this one only goes monocle"
if [ "$(RL 'return ranma.has("action.toolbar_target")')" = true ]; then
  # Wide enough for the selector's text beside its symbol.
  T resize-window -t nest -x 110 -y 34; sleep 1.5
  screen=$(T capture-pane -p -t nest)
  echo "$screen" | grep -q "⇅ inner" || { echo "$screen"; fail "the selector does not say inner"; }
  RL2() { $ENV RANMA_SOCKET=$RT/ranma/2.sock $BIN lua "$1" 2>&1; }
  RL 'ranma.action("new_pane")' >/dev/null; sleep 0.5
  f1=$(RL 'return ranma.state().focused'); f2=$(RL2 'return ranma.state().focused')
  # A tap on ▶ (an SGR press and release where it is drawn), as Termux sends.
  tap() {
    local row col
    row=$(T capture-pane -p -t nest | grep -n "$1" | tail -1 | cut -d: -f1)
    col=$(T capture-pane -p -t nest | sed -n "${row}p" | awk -v s="$1" '{ print index($0, s) }')
    col=$(T capture-pane -p -t nest | sed -n "${row}p" | cut -c1-$((col - 1)) | wc -m)
    T send-keys -t nest -l $'\e[<0;'$((col + 1))';'$row'M'$'\e[<0;'$((col + 1))';'$row'm'; sleep 1
  }
  tap "▶"
  [ "$(RL 'return ranma.state().focused')" != "$f1" ] || fail "▶ did not move the inner's focus"
  [ "$(RL2 'return ranma.state().focused')" = "$f2" ] || fail "▶ moved the outer's focus"
  echo "ok   a button follows the focus into the desk's ranma"
  tap "⇅"
  T capture-pane -p -t nest | grep -q "⇅ here" || fail "the selector does not say here once tapped"
  f1=$(RL 'return ranma.state().focused')
  tap "▶"
  [ "$(RL 'return ranma.state().focused')" = "$f1" ] || fail "pinned here, ▶ still went inside"
  echo "ok   tapped, the selector keeps the buttons on the phone's ranma"
fi
T send-keys -t desk 'echo desk3' Enter; sleep 1
[ "$(P)" = nil ] || fail "desk after nested: profile is $(P)"
echo "ok   the desk takes it back from a nested phone"
echo 'ranma.set { mobile = { follow = false } }' >> $W/cfg/init.lua
$ENV RANMA_SOCKET=$RT/ranma/1.sock $BIN action reload_config; sleep 1
[ "$(RL 'return ranma.get("mobile.follow")')" = false ] || fail "the option did not take"
T send-keys -t phone 'echo phone3' Enter; sleep 1
[ "$(P)" = nil ] || fail "follow = false still switched: $(P)"
echo "ok   mobile.follow = false: nothing switches"
echo "mobile e2e: ok"
