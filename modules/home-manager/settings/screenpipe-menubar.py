#!/usr/bin/env python3
"""Screenpipe menu bar app — shows status and toggles audio mode."""

import json
import subprocess
import time
import urllib.request
import urllib.error

import rumps

HEALTH_URL = "http://localhost:3030/health"
PLIST_PATH = "/Users/askielboe/Library/LaunchAgents/com.screenpipe.daemon.plist"
POLL_INTERVAL = 5

DURATION_OPTIONS = [30, 60, 90, 120, 180]  # minutes
DEFAULT_DURATION = 60  # minutes

# Menu bar icons — compact single-character status
ICON_HEALTHY = "◉"  # filled circle — all good
ICON_NO_AUDIO = "◎"  # double circle — running but audio off
ICON_DOWN = "◌"  # dashed circle — not running
ICON_RESTARTING = "⟳"  # rotating — transitioning


class ScreenpipeMenuBar(rumps.App):
    def __init__(self):
        super().__init__("SP", quit_button=None)

        self._audio_timeout = DEFAULT_DURATION * 60  # seconds
        self._audio_on_since = None

        # Audio mode section
        self.audio_off = rumps.MenuItem(
            "Disabled", callback=self.toggle_audio_off
        )
        self.audio_auto = rumps.MenuItem(
            "Auto", callback=self.toggle_audio_auto
        )
        self.audio_danish = rumps.MenuItem(
            "Danish", callback=self.toggle_audio_danish
        )
        self.audio_english = rumps.MenuItem(
            "English", callback=self.toggle_audio_english
        )
        self.audio_german = rumps.MenuItem(
            "German", callback=self.toggle_audio_german
        )

        # Duration submenu
        self.duration_menu = rumps.MenuItem("Timer")
        self._duration_items = {}
        for mins in DURATION_OPTIONS:
            if mins < 60:
                label = f"{mins}m"
            else:
                h = mins // 60
                m = mins % 60
                label = f"{h}h{m:02d}" if m else f"{h}h"
            item = rumps.MenuItem(label, callback=self._make_duration_callback(mins))
            self._duration_items[mins] = item
            self.duration_menu.add(item)
        self._update_duration_checkmarks()

        self.menu = [
            self.audio_auto,
            self.audio_danish,
            self.audio_english,
            self.audio_german,
            None,
            self.audio_off,
            None,
            self.duration_menu,
            None,
            rumps.MenuItem("Quit", callback=rumps.quit_application),
        ]

        self._update_status()

    def _make_duration_callback(self, mins):
        def callback(_):
            self._audio_timeout = mins * 60
            # Reset timer to use new duration from now
            if self._audio_on_since is not None:
                self._audio_on_since = time.monotonic()
            self._update_duration_checkmarks()
        return callback

    def _update_duration_checkmarks(self):
        current = self._audio_timeout // 60
        for mins, item in self._duration_items.items():
            item.state = mins == current

    @rumps.timer(POLL_INTERVAL)
    def poll_health(self, _):
        self._update_status()

    def _update_status(self):
        try:
            req = urllib.request.urlopen(HEALTH_URL, timeout=3)
            data = json.loads(req.read())
        except (urllib.error.URLError, OSError, json.JSONDecodeError, ValueError):
            self.title = f"{ICON_DOWN} SP"
            self._audio_on_since = None
            self._set_checkmarks(None)
            return

        audio = data.get("audio_status", "unknown")
        status = data.get("status", "unknown")

        if status != "healthy":
            self.title = f"{ICON_DOWN} SP"
            self._audio_on_since = None
            self._set_checkmarks(None)
            return

        if audio == "disabled":
            self.title = f"{ICON_NO_AUDIO} SP"
            self._audio_on_since = None
            self._set_checkmarks("off")
        elif audio == "ok":
            mode = self._detect_audio_mode()
            label = {
                "danish": "DA",
                "english": "EN",
                "german": "DE",
                "auto": "AUTO",
            }.get(mode, mode)

            # Start timer if audio just came on
            if self._audio_on_since is None:
                self._audio_on_since = time.monotonic()

            elapsed = time.monotonic() - self._audio_on_since
            remaining = self._audio_timeout - elapsed

            if remaining <= 0:
                # Time's up — auto-disable audio
                self._audio_on_since = None
                self._run_command("sp-mic-off")
                rumps.notification(
                    "Screenpipe",
                    "Audio auto-disabled",
                    f"Timer expired. Audio recording turned off.",
                )
                return

            mins_left = int(remaining // 60)
            self.title = f"{ICON_HEALTHY} {label} {mins_left}m"
            self._set_checkmarks(mode)
        else:
            self.title = f"{ICON_NO_AUDIO} SP"
            self._audio_on_since = None
            self._set_checkmarks(None)

    def _detect_audio_mode(self):
        """Check plist for --language flag to determine audio mode."""
        try:
            with open(PLIST_PATH) as f:
                content = f.read()
            for lang in ("danish", "english", "german"):
                if f"--language {lang}" in content:
                    return lang
        except OSError:
            pass
        return "auto"

    def _set_checkmarks(self, active):
        self.audio_off.state = active == "off"
        self.audio_auto.state = active == "auto"
        self.audio_danish.state = active == "danish"
        self.audio_english.state = active == "english"
        self.audio_german.state = active == "german"

    def toggle_audio_off(self, _):
        self._run_command("sp-mic-off")

    def toggle_audio_auto(self, _):
        self._run_command("sp-mic-on")

    def toggle_audio_danish(self, _):
        self._run_command("sp-mic-on-da")

    def toggle_audio_english(self, _):
        self._run_command("sp-mic-on-en")

    def toggle_audio_german(self, _):
        self._run_command("sp-mic-on-de")

    def _run_command(self, cmd):
        """Run a toggle command in the background, then refresh status."""
        self.title = f"{ICON_RESTARTING} SP"
        try:
            subprocess.Popen(
                [cmd],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            rumps.notification("Screenpipe", "", f"Command not found: {cmd}")


if __name__ == "__main__":
    ScreenpipeMenuBar().run()
