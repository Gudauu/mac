#!/usr/bin/env python3
"""Keep Ghostty's window title in sync with the focused Herdr space.

Herdr owns the outer terminal title: it never forwards a pane's own OSC title
outward, so without this the title stays whatever the launching command set it
to ("herdr") for the life of the session.

This subscribes to Herdr's event stream over the API socket and pushes a new
title through client.window_title.set whenever the focused space, tab, pane, or
working directory changes. The socket serves one request per connection, so
requests open a short connection each; the event stream is the only long-lived
one. Focus events fire several times a second even when nothing changed, so the
computed title is deduplicated and only a real change costs any requests.

Format tokens:
  {space}  space label, e.g. "dev"
  {path}   focused pane's cwd, $HOME collapsed to ~
  {dir}    basename of that cwd
  {tab}    focused tab label

To change the format, write one line into the plugin's config directory:
  echo '{space} · {dir}' > ~/.config/herdr/plugins/config/window-title/format
"""

import fcntl
import json
import os
import queue
import socket
import sys
import threading
import time

DEFAULT_SOCKET = os.path.expanduser("~/.config/herdr/herdr.sock")
DEFAULT_FORMAT = "{space} · {path}"


def resolve_socket():
    # Herdr sets HERDR_SOCKET_PATH for plugin processes, which is what points a
    # named session at its own server rather than the default one.
    return os.environ.get("HERDR_SOCKET_PATH") or os.environ.get("HERDR_SOCKET") or DEFAULT_SOCKET


def resolve_format():
    from_env = os.environ.get("HERDR_TITLE_FORMAT")
    if from_env:
        return from_env
    config_dir = os.environ.get("HERDR_PLUGIN_CONFIG_DIR")
    if config_dir:
        try:
            with open(os.path.join(config_dir, "format")) as handle:
                line = handle.readline().strip()
            if line:
                return line
        except OSError:
            pass
    return DEFAULT_FORMAT


SOCKET_PATH = resolve_socket()
TITLE_FORMAT = resolve_format()

SUBSCRIPTIONS = [
    "workspace.focused",
    "workspace.renamed",
    "workspace.created",
    "workspace.closed",
    "tab.focused",
    "tab.renamed",
    "pane.focused",
    "pane.updated",
]

# Coalesce the burst of events a single space switch produces.
DEBOUNCE_SECONDS = 0.12
RECONNECT_SECONDS = 2.0


def log(message):
    print(f"[herdr-window-title] {message}", file=sys.stderr, flush=True)


def request(method, params=None):
    """Send one request on its own connection and return the response body."""
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(5)
    try:
        sock.connect(SOCKET_PATH)
        payload = json.dumps({"id": "window-title", "method": method, "params": params or {}})
        sock.sendall((payload + "\n").encode())
        stream = sock.makefile("rb")
        line = stream.readline()
    finally:
        sock.close()
    if not line:
        raise ConnectionError(f"no response to {method}")
    return json.loads(line).get("result")


def shorten(path):
    home = os.path.expanduser("~")
    if path == home:
        return "~"
    if path.startswith(home + os.sep):
        return "~" + path[len(home):]
    return path


def build_title():
    """Read current focus straight from Herdr and render the title."""
    panes = (request("pane.list") or {}).get("panes", [])
    focused = next((pane for pane in panes if pane.get("focused")), None)
    if focused is None:
        return None

    workspaces = (request("workspace.list") or {}).get("workspaces", [])
    space = next((ws for ws in workspaces if ws.get("focused")), None)
    space_label = (space or {}).get("label", "")

    cwd = focused.get("foreground_cwd") or focused.get("cwd") or ""

    tab_label = ""
    if "{tab}" in TITLE_FORMAT and space:
        tabs = (request("tab.list", {"workspace_id": space["workspace_id"]}) or {}).get("tabs", [])
        active_id = space.get("active_tab_id")
        tab = next((t for t in tabs if t.get("tab_id") == active_id), None)
        tab_label = (tab or {}).get("label", "")

    title = TITLE_FORMAT.format(
        space=space_label,
        path=shorten(cwd),
        dir=os.path.basename(cwd) or cwd,
        tab=tab_label,
    )
    return title.strip(" ·-")


def set_title(title):
    request("client.window_title.set", {"title": title})


def signature_from(event):
    """Cheap identity of what the title depends on, read off the event itself.

    Returning None means "cannot tell from this event, go ask", which is what
    focus and rename events do.
    """
    data = event.get("data") or {}
    kind = data.get("type")
    if kind == "pane_updated":
        pane = data.get("pane") or {}
        if not pane.get("focused"):
            return "unchanged"
        return ("pane_cwd", pane.get("pane_id"), pane.get("foreground_cwd") or pane.get("cwd"))
    if kind == "workspace_focused":
        return ("workspace", data.get("workspace_id"))
    if kind == "tab_focused":
        return ("tab", data.get("tab_id"))
    if kind == "pane_focused":
        return ("pane", data.get("pane_id"))
    return None


def read_events(stream, sink):
    """Feed change signals into sink until the stream ends.

    Runs on its own thread so the socket can stay blocking: a read timeout on a
    buffered readline can strand a half-read message and desynchronize the
    stream.
    """
    last_signature = None
    try:
        while True:
            line = stream.readline()
            if not line:
                break
            signature = signature_from(json.loads(line))
            if signature == "unchanged":
                continue
            if signature is not None and signature == last_signature:
                continue
            last_signature = signature
            sink.put(True)
    except (OSError, json.JSONDecodeError) as error:
        log(f"event stream error: {error}")
    finally:
        sink.put(None)


def run_once():
    """Subscribe and pump events until the connection drops."""
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(SOCKET_PATH)
    stream = sock.makefile("rwb")
    subscribe = {
        "id": "window-title-subscribe",
        "method": "events.subscribe",
        "params": {"subscriptions": [{"type": name} for name in SUBSCRIPTIONS]},
    }
    stream.write((json.dumps(subscribe) + "\n").encode())
    stream.flush()
    ack = json.loads(stream.readline())
    if "error" in ack:
        raise ConnectionError(f"subscribe rejected: {ack['error']}")
    log(f"subscribed, format {TITLE_FORMAT!r}")

    signals = queue.Queue()
    reader = threading.Thread(target=read_events, args=(stream, signals), daemon=True)
    reader.start()

    last_title = None

    def flush():
        nonlocal last_title
        title = build_title()
        if title and title != last_title:
            set_title(title)
            last_title = title

    flush()

    while True:
        if signals.get() is None:
            raise ConnectionError("event stream closed")
        # Coalesce the burst of events one space switch produces.
        deadline = time.monotonic() + DEBOUNCE_SECONDS
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            try:
                if signals.get(timeout=remaining) is None:
                    raise ConnectionError("event stream closed")
            except queue.Empty:
                break
        flush()


def claim_single_instance():
    """Hold a per-session lock, so a hand-started copy and the plugin's own
    startup copy cannot both drive the title."""
    key = SOCKET_PATH.replace(os.sep, "_").strip("_")
    lock_path = os.path.join("/tmp", f"herdr-window-title-{key}.lock")
    handle = open(lock_path, "w")
    try:
        fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        log("another instance already owns this session, exiting")
        return None
    return handle


def main():
    lock = claim_single_instance()
    if lock is None:
        return
    while True:
        try:
            run_once()
        except (ConnectionError, OSError, json.JSONDecodeError) as error:
            log(f"{error}; retrying in {RECONNECT_SECONDS}s")
        time.sleep(RECONNECT_SECONDS)


if __name__ == "__main__":
    main()
