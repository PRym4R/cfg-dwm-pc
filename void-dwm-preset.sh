#!/usr/bin/env bash
# =====================================================================
#  Void Linux + dwm  |  full preset & install script
#  Machine: voidlinux  |  user: hackerman  |  mouse: AJAZZ AJ159 Pro
#  GPU: RTX 4060 (nvidia 595, dkms) + AMD Raphael iGPU (display on DP-0)
#  Monitor: MSI MAG 255XF @ 300 Hz
#
#  This is BOTH documentation and a re-runnable installer.
#  Run as your normal user (root steps go through sudo/doas).
# =====================================================================

SUDO="sudo"        # change to "doas" if you prefer

# ---------------------------------------------------------------------
# 1. PACKAGES
# ---------------------------------------------------------------------
#  base-devel        - build tools for dwm/st
#  dkms              - dynamic kernel module support (for nvidia-dkms)
#  xorg-server/xinit - X + startx
#  xauth/xrdb/setxkbmap/xrandr - X utilities
#  rofi              - app launcher (Win)
#  xcape             - bare Super tap -> rofi
#  parcellite        - clipboard manager (PRIMARY <-> CLIPBOARD)
#  xclip/xsel        - clipboard CLI tools
#  xinput            - change mouse accel/speed
#  dejavu-fonts-ttf  - fonts
#  X devel headers   - to compile dwm/st (Xft, Xinerama, fontconfig)
#  pipewire/wireplumber - sound server (pulse+alsa compat live inside pipewire)
#  elogind           - session management; creates /run/user/UID
#  rtkit             - realtime scheduling for audio
$SUDO xbps-install -Suy
$SUDO xbps-install -y \
    base-devel dkms \
    xorg-server xinit xauth xrdb setxkbmap xrandr \
    rofi xdotool xclip xsel parcellite xcape xinput \
    libX11-devel libXinerama-devel libXft-devel \
    fontconfig-devel libXrender-devel freetype-devel \
    dejavu-fonts-ttf \
    pipewire wireplumber elogind rtkit

# enable runit services
for s in dbus elogind rtkit; do
    $SUDO ln -sf /etc/sv/$s /var/service/$s
done

# ---------------------------------------------------------------------
# 2. STEAM  (multilib + 32-bit libraries)
# ---------------------------------------------------------------------
$SUDO xbps-install -y void-repo-multilib void-repo-multilib-nonfree
$SUDO xbps-install -Sy
$SUDO xbps-install -y steam \
    glibc-32bit libgcc-32bit libstdc++-32bit libdrm-32bit \
    libglvnd-32bit libva-32bit mesa-dri-32bit nvidia-libs-32bit
#  (nvidia-libs-32bit matches nvidia 595; adjust if nvidia version changes)

# ---------------------------------------------------------------------
# 3. BUILD dwm  (custom config.h + focuslast patch)
# ---------------------------------------------------------------------
mkdir -p ~/.local/src/suckless
cd ~/.local/src/suckless
[ -d dwm ] || git clone https://git.suckless.org/dwm
cd dwm

cat > config.h <<'EOF'
/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "monospace:size=10" };
static const char dmenufont[]       = "monospace:size=10";
static const char col_gray1[]       = "#222222";
static const char col_gray2[]       = "#444444";
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#eeeeee";
static const char col_cyan[]        = "#005577";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
static const int refreshrate = 300;  /* refresh rate (per second) for client move/resize */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod1Mask          /* Alt is the main modifier */
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                        KEY,      view,      {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,            KEY,      toggleview,{.ui = 1 << TAG} }, \
	{ Mod4Mask|ShiftMask,            KEY,      tag,       {.ui = 1 << TAG} }, \
	{ Mod4Mask|ControlMask|ShiftMask,KEY,      toggletag, {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "rofi", "-show", "drun", NULL };
static const char *roficmd[]  = { "rofi", "-show", "drun", NULL };
static const char *termcmd[]  = { "st", NULL };

static const Key keys[] = {
	/* modifier                     key            function        argument */
	{ Mod4Mask,                     XK_d,          spawn,          {.v = roficmd } },
	{ MODKEY,                       XK_Return,     spawn,          {.v = termcmd } },
	{ MODKEY|ShiftMask,             XK_Return,     zoom,           {0} },
	{ MODKEY,                       XK_BackSpace,  killclient,     {0} },
	{ MODKEY,                       XK_Tab,        focuslast,      {0} },
	{ MODKEY,                       XK_b,          togglebar,      {0} },
	{ MODKEY,                       XK_j,          focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,          focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,          incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,          incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,          setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,          setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_t,          setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,          setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,          setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,      setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,      togglefloating, {0} },
	{ MODKEY,                       XK_0,          view,           {.ui = ~0 } },
	{ Mod4Mask|ShiftMask,           XK_0,          tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,      focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period,     focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,      tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,     tagmon,         {.i = +1 } },
	TAGKEYS(                        XK_1,                          0)
	TAGKEYS(                        XK_2,                          1)
	TAGKEYS(                        XK_3,                          2)
	TAGKEYS(                        XK_4,                          3)
	TAGKEYS(                        XK_5,                          4)
	TAGKEYS(                        XK_6,                          5)
	TAGKEYS(                        XK_7,                          6)
	TAGKEYS(                        XK_8,                          7)
	TAGKEYS(                        XK_9,                          8)
	{ MODKEY|ShiftMask,             XK_q,          quit,           {0} },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
EOF

# patch dwm.c: add focuslast() (Alt+Tab = previous window)
python3 - <<'PY'
p = 'dwm.c'
s = open(p).read()
if 'focuslast' in s:
    print('dwm.c already patched')
else:
    s = s.replace(
        'static void focusmon(const Arg *arg);\nstatic void focusstack(const Arg *arg);',
        'static void focuslast(const Arg *arg);\nstatic void focusmon(const Arg *arg);\nstatic void focusstack(const Arg *arg);')
    anchor = ('\tif (c) {\n\t\tfocus(c);\n\t\trestack(selmon);\n\t}\n}\n\n'
              'Atom\ngetatomprop(Client *c, Atom prop)')
    repl = ('\tif (c) {\n\t\tfocus(c);\n\t\trestack(selmon);\n\t}\n}\n\n'
            'void\nfocuslast(const Arg *arg)\n{\n\tClient *c;\n\n'
            '\tif (!selmon->sel)\n\t\treturn;\n'
            '\tfor (c = selmon->sel->snext; c && !ISVISIBLE(c); c = c->snext);\n'
            '\tif (!c)\n\t\tfor (c = selmon->stack; c && !ISVISIBLE(c); c = c->snext);\n'
            '\tif (c && c != selmon->sel) {\n\t\tfocus(c);\n\t\trestack(selmon);\n\t}\n}\n\n'
            'Atom\ngetatomprop(Client *c, Atom prop)')
    assert anchor in s, 'anchor not found - dwm.c changed upstream, patch manually'
    s = s.replace(anchor, repl)
    open(p, 'w').write(s)
    print('dwm.c patched: focuslast() added')
PY

make clean >/dev/null 2>&1
make
$SUDO make install PREFIX=/usr/local

# ---------------------------------------------------------------------
# 4. BUILD st (terminal) + scrollback patches
#    - base:        Shift+PageUp/PageDown scroll history
#    - mouse:       mouse wheel scrolls history
#    - altscreen:   in less/vim the wheel scrolls the app instead
# ---------------------------------------------------------------------
cd ~/.local/src/suckless
[ -d st ] || git clone https://git.suckless.org/st
cd st
curl -fsSL -o /tmp/st-scrollback.diff       https://st.suckless.org/patches/scrollback/st-scrollback-0.9.2.diff
curl -fsSL -o /tmp/st-scrollback-mouse.diff https://st.suckless.org/patches/scrollback/st-scrollback-mouse-0.9.2.diff
curl -fsSL -o /tmp/st-scrollback-alt.diff   https://st.suckless.org/patches/scrollback/st-scrollback-mouse-altscreen-20220127-2c5edf2.diff
if ! grep -q kscrollup st.c; then
	# apply with fuzz; upstream may have moved hunks around
	patch -p1 --fuzz=3 < /tmp/st-scrollback.diff
	patch -p1 --fuzz=3 < /tmp/st-scrollback-mouse.diff
	patch -p1 --fuzz=3 < /tmp/st-scrollback-alt.diff
	cp config.def.h config.h
fi
make clean >/dev/null 2>&1
make
$SUDO make install PREFIX=/usr/local

# ---------------------------------------------------------------------
# 5. DOTFILES
# ---------------------------------------------------------------------
cat > ~/.xinitrc <<'EOF'
#!/bin/sh

# keyboard layouts: toggle with Alt+Shift (no ScrollLock LED)
setxkbmap -layout us,ru -option grp:alt_shift_toggle

# bare Super tap launches rofi (emits Super+d, bound in dwm)
xcape -e 'Super_L=Super_L|d' &

# force 300 Hz on first connected output
OUT=$(xrandr | awk '/ connected/{print $1; exit}')
[ -n "$OUT" ] && xrandr --output "$OUT" --mode 1920x1080 --rate 300

[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

# clipboard manager (syncs PRIMARY <-> CLIPBOARD)
parcellite &

# runtime dir (elogind sets it at login; fallback just in case)
if [ -z "$XDG_RUNTIME_DIR" ]; then
	export XDG_RUNTIME_DIR="$HOME/.run"
	mkdir -p -m 700 "$XDG_RUNTIME_DIR"
fi

# session D-Bus (PipeWire / WirePlumber need it)
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
	eval "$(dbus-launch --sh-syntax --exit-with-session)"
fi

# PipeWire sound server
pipewire &
sleep 0.5
wireplumber &
pipewire-pulse &

# default output = onboard analog (headphones), never HDMI/monitor
(
	for _ in $(seq 1 30); do
		sleep 0.5
		sink=$(wpctl status -n 2>/dev/null | awk '
			/Sinks:/{s=1;next}
			/Sources:|Filters:|Streams:/{s=0}
			s && tolower($0) ~ /analog/ && match($0,/[0-9]+\./) {print substr($0,RSTART,RLENGTH-1); exit}')
		if [ -n "$sink" ]; then wpctl set-default "$sink"; break; fi
	done
) &

exec dwm
EOF

cat > ~/.bash_profile <<'EOF'
# .bash_profile

# Get the aliases and functions
[ -f $HOME/.bashrc ] && . $HOME/.bashrc

# start X automatically on tty1 (autologin)
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
	exec startx
fi
EOF

mkdir -p ~/.config/opencode
cat > ~/.config/opencode/tui.json <<'EOF'
{
  "$schema": "https://opencode.ai/tui.json",
  "mouse": false
}
EOF

# ---------------------------------------------------------------------
# 6. AUTOLOGIN on tty1
# ---------------------------------------------------------------------
$SUDO tee /etc/sv/agetty-tty1/conf >/dev/null <<'EOF'
if [ -x /sbin/agetty -o -x /bin/agetty ]; then
	# util-linux specific settings
	if [ "${tty}" = "tty1" ]; then
		GETTY_ARGS="--noclear --autologin hackerman"
	fi
fi

BAUD_RATE=38400
TERM_NAME=linux
EOF

# ---------------------------------------------------------------------
# 7. MOUSE  (no acceleration, slightly slower)
# ---------------------------------------------------------------------
$SUDO mkdir -p /etc/X11/xorg.conf.d
$SUDO tee /etc/X11/xorg.conf.d/30-mouse-accel.conf >/dev/null <<'EOF'
Section "InputClass"
    Identifier "libinput pointer no-accel"
    MatchIsPointer "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "AccelProfile" "flat"
    Option "AccelSpeed" "-0.3"
EndSection
EOF

# apply live (device name may differ; match AJAZZ receiver)
if command -v xinput >/dev/null && [ -n "$DISPLAY" ]; then
    for id in $(xinput list --id-only 2>/dev/null); do
        if xinput list-props "$id" 2>/dev/null | grep -q "libinput Accel"; then
            xinput set-prop "$id" "libinput Accel Profile Enabled" 0 1 0 2>/dev/null || true
            xinput set-prop "$id" "libinput Accel Speed" -0.3 2>/dev/null || true
        fi
    done
fi

# ---------------------------------------------------------------------
# 8. KEYBINDINGS SUMMARY  (MODKEY = Alt)
# ---------------------------------------------------------------------
#  Win (tap)      rofi launcher
#  Win+d          rofi launcher
#  Alt+1..9       switch workspace (tag)
#  Alt+Win+1..9   move window to workspace   (Super+Shift+num)
#  Alt+Tab        focus previous window
#  Alt+Enter      new st terminal
#  Alt+Backspace  close window
#  Alt+Shift+Enter zoom (swap master)
#  Alt+Shift+space floating
#  Alt+space      cycle layout
#  Alt+Shift+q    quit dwm
#  Alt+Shift (in apps) toggle layout us/ru

echo
echo "==============================================="
echo " Done. Reboot to activate autologin + 300 Hz + mouse."
echo "==============================================="
