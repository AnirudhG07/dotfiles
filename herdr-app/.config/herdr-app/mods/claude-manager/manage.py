#!/usr/bin/env python3
"""Claude Code skills, commands, agents, MCP servers, hooks and plugins, on or off.

  manage.py list                         -> JSON {skills, commands, agents, mcp, hooks, plugins}: [{id, name, desc, on}]
  manage.py set KIND ID on|off           KIND: skill command agent mcp hook plugin
  manage.py delete skill|agent ID        moves its files to the Trash (macOS `trash`: Put Back works)

Off is written to ~/.claude/settings.json the native way wherever Claude Code has one
(checked against Claude Code 2.1.319: a fresh `claude -p` no longer lists the component):
  skill, command -> "skillOverrides": {ID: "off"}           (on = key removed)
  agent          -> "permissions.deny": ["Agent(ID)"]        (on = rule removed; "Task(ID)" too)
  mcp            -> "deniedMcpServers": [{"serverName": ID}] (on = entry removed; every scope)
  plugin         -> "enabledPlugins": {ID: false}            (on = true)
  hook "*"       -> "disableAllHooks": true                   (every hook and the status line)
Claude Code has no switch for one hook, so a hook turned off is taken out of settings.json and
kept, with where it was, in ~/.claude/claude-manager/hooks-off.json; on puts it back in place.
Nothing is deleted. Each write is atomic (temp file + rename) after a copy to *.bak-claude-manager.
"""
import glob, hashlib, json, os, re, shutil, subprocess, sys, tempfile

HOME = os.path.expanduser("~")
CLAUDE = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(HOME, ".claude")
SETTINGS = os.path.join(CLAUDE, "settings.json")
STATE = os.path.join(HOME, ".claude.json")  # user-scope MCP servers live here
STASH = os.path.join(CLAUDE, "claude-manager", "hooks-off.json")
PLUGINS = os.path.join(CLAUDE, "plugins", "installed_plugins.json")


def load(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return default


def front(path):
    """name + one-line description from a SKILL.md / agent / command .md frontmatter."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read(8000)
    except OSError:
        return {}
    m = re.match(r"---\s*\n(.*?)\n---", text, re.S)
    if not m:
        first = next((l.strip("# ").strip() for l in text.split("\n") if l.strip()), "")
        return {"description": first[:240]}
    out, lines = {}, m.group(1).split("\n")
    for i, line in enumerate(lines):
        k = re.match(r"(name|description):\s*(.*)$", line)
        if not k or k.group(1) in out:
            continue
        v = k.group(2).strip()
        if v in ("|", ">", "|-", ">-"):  # block scalar marker
            v = ""
        for l in lines[i + 1:]:  # block or multi-line plain scalar: the indented lines under it
            if l.strip() and not l.startswith((" ", "\t")):
                break
            v += " " + l.strip()
        out[k.group(1)] = " ".join(v.split()).strip("\"'")[:240]
    return out


def deny_names(s):
    out = set()
    for r in s.get("permissions", {}).get("deny", []):
        m = re.fullmatch(r"(?:Agent|Task)\((.+)\)", r)
        if m:
            out.add(m.group(1))
    return out


def mcp_where(cfg):
    if cfg.get("url"):
        return f"{cfg.get('type', 'http')} · {re.sub(r'^[a-z]+://([^/]+).*$', r'\1', cfg['url'])}"
    cmd = cfg.get("command", "")
    return f"stdio · {os.path.basename(cmd)}" if cmd else cfg.get("type", "")
    # ponytail: never env / headers / args: they hold tokens


# ---- hooks ---------------------------------------------------------------------------------

def gkey(g):
    return {k: v for k, v in g.items() if k != "hooks"}


def hook_id(event, g, h):
    raw = json.dumps([event, gkey(g), h], sort_keys=True)
    return hashlib.sha1(raw.encode()).hexdigest()[:12]


def hook_label(h):
    c = h.get("command") or h.get("prompt") or h.get("url") or h.get("type", "hook")
    p = re.search(r"([\w.~/${}-]*/)?([\w-]+)\.(?:sh|py|cjs|mjs|js|ts)\b\S*\s*([a-z][\w-]*)?", c)
    if p:
        owner = re.search(r"/\.(?!claude/)(\w+)/", p.group(0))  # ~/.orca/agent-hooks/claude-hook.sh -> orca
        arg = p.group(3) if p.group(3) and not p.group(3).startswith(("then", "else", "fi")) else ""
        return " ".join(x for x in (owner and owner.group(1), p.group(2), arg) if x)
    words = [w.strip("'\"") for w in re.findall(r"'[^']*'|\"[^\"]*\"|\S+", c)]  # a quoted path is one word
    words = words[:1] + [w for w in words[1:2] if not w.startswith("-")]  # "tuios agent-hook", not "x --flag"
    return " ".join(os.path.basename(w) for w in words) if words else "hook"


def hook_rows(s):
    for ev, groups in s.get("hooks", {}).items():
        for g in groups:
            for h in g.get("hooks", []):
                yield ev, g, h


def hook_item(ev, g, h, on):
    cmd = " ".join((h.get("command") or h.get("prompt") or h.get("url") or "").split()).replace(HOME, "~")
    if re.match(r"(if|case|for|while|\{)\b", cmd) or cmd.count(";") > 2:
        cmd = "inline shell script"  # a wall of shell says nothing at a glance
    m = g.get("matcher")
    return {"id": hook_id(ev, g, h), "name": hook_label(h), "event": ev, "on": on,
            "desc": f"{m} · {cmd[:160]}" if m and m != "*" else cmd[:160]}


def hook_off(s, stash, hid):
    hooks = s.get("hooks", {})
    for ev_pos, (ev, groups) in enumerate(hooks.items()):
        for g_pos, g in enumerate(groups):
            for h_pos, h in enumerate(g.get("hooks", [])):
                if hook_id(ev, g, h) != hid:
                    continue
                rec = {"id": hid, "event": ev, "ev_pos": ev_pos, "g_pos": g_pos, "h_pos": h_pos,
                       "group": gkey(g), "hook": h}
                g["hooks"].pop(h_pos)
                if not g["hooks"]:
                    groups.pop(g_pos)
                if not groups:
                    del hooks[ev]
                if not hooks:
                    del s["hooks"]
                stash.append(rec)
                return
    raise SystemExit(f"no hook {hid}")


def hook_on(s, stash, hid):
    rec = next((r for r in stash if r["id"] == hid), None)
    if rec is None:
        raise SystemExit(f"no hook {hid} turned off")
    stash.remove(rec)
    if any(hook_id(ev, g, h) == hid for ev, g, h in hook_rows(s)):
        return  # already back (put in by hand): just forget the copy
    hooks = s.setdefault("hooks", {})  # ponytail: a re-created "hooks" key lands last in the file
    ev = rec["event"]
    if ev not in hooks:
        items = list(hooks.items())
        items.insert(min(rec["ev_pos"], len(items)), (ev, []))
        hooks.clear()
        hooks.update(items)
    groups = hooks[ev]
    pos = min(rec["g_pos"], len(groups))
    same = [i for i, g in enumerate(groups) if gkey(g) == rec["group"]]
    if same:  # the group it came from (closest to where it was)
        g = groups[min(same, key=lambda i: abs(i - rec["g_pos"]))]
        g["hooks"].insert(min(rec["h_pos"], len(g["hooks"])), rec["hook"])
    else:
        groups.insert(pos, {**rec["group"], "hooks": [rec["hook"]]})


# ---- listing -------------------------------------------------------------------------------

def plugin_desc(info):
    path = (info or [{}])[0].get("installPath", "")
    meta = load(os.path.join(path, ".claude-plugin", "plugin.json"), {}) if path else {}
    return " ".join(str(meta.get("description", "")).split())[:240]


def listing():
    s = load(SETTINGS, {})
    over = s.get("skillOverrides", {})
    denied = deny_names(s)
    denied_mcp = {e.get("serverName") for e in s.get("deniedMcpServers", []) if isinstance(e, dict)}
    item = lambda id, desc, on, **kw: {"id": id, "name": kw.pop("name", id), "desc": desc, "on": on, **kw}
    skills = [item(os.path.basename(os.path.dirname(p)), front(p).get("description", ""),
                   over.get(os.path.basename(os.path.dirname(p)), "on") != "off",
                   mode=over.get(os.path.basename(os.path.dirname(p))))
              for p in glob.glob(os.path.join(CLAUDE, "skills", "*", "SKILL.md"))]
    commands = [item(os.path.basename(p)[:-3], front(p).get("description", ""), over.get(os.path.basename(p)[:-3], "on") != "off",
                     name="/" + os.path.basename(p)[:-3])
                for p in glob.glob(os.path.join(CLAUDE, "commands", "*.md"))]
    agents = []
    for p in glob.glob(os.path.join(CLAUDE, "agents", "**", "*.md"), recursive=True):
        fm = front(p)
        n = fm.get("name") or os.path.basename(p)[:-3]
        agents.append(item(n, fm.get("description", ""), n not in denied))
    mcp = [item(n, mcp_where(c if isinstance(c, dict) else {}), n not in denied_mcp)
           for n, c in load(STATE, {}).get("mcpServers", {}).items()]
    installed = load(PLUGINS, {}).get("plugins", {})
    plugins = [item(k, plugin_desc(installed.get(k)) or k.split("@")[-1], bool(v), name=k.split("@")[0])
               for k, v in s.get("enabledPlugins", {}).items()]
    live = [hook_item(ev, g, h, True) for ev, g, h in hook_rows(s)]
    ids = {x["id"] for x in live}
    off = [hook_item(r["event"], {**r["group"]}, r["hook"], False) for r in load(STASH, []) if r["id"] not in ids]
    key = lambda x: x["name"].lower()
    hooks = [item("*", "Every hook below, and the status line", not s.get("disableAllHooks"), name="All hooks")] \
        + sorted(live + off, key=lambda x: (x["event"].lower(), x["name"].lower()))
    return {"skills": sorted(skills, key=key), "commands": sorted(commands, key=key), "agents": sorted(agents, key=key),
            "mcp": sorted(mcp, key=key), "hooks": hooks, "plugins": sorted(plugins, key=key), "settings": SETTINGS}


# ---- writing -------------------------------------------------------------------------------

def apply(s, stash, kind, name, on):
    if kind in ("skill", "command"):
        over = s.setdefault("skillOverrides", {})
        if on:
            over.pop(name, None)
        else:
            over[name] = "off"
        if not over:
            del s["skillOverrides"]
    elif kind == "agent":
        perms = s.setdefault("permissions", {})
        deny = [r for r in perms.get("deny", []) if r not in (f"Agent({name})", f"Task({name})")]
        if not on:
            deny.append(f"Agent({name})")
        if deny:
            perms["deny"] = deny
        else:
            perms.pop("deny", None)
        if not perms:
            del s["permissions"]
    elif kind == "mcp":
        lst = [e for e in s.get("deniedMcpServers", []) if e != {"serverName": name}]
        if not on:
            lst.append({"serverName": name})
        if lst:
            s["deniedMcpServers"] = lst
        else:
            s.pop("deniedMcpServers", None)
    elif kind == "plugin":
        if name not in s.get("enabledPlugins", {}):
            raise SystemExit(f"no plugin {name}")
        s["enabledPlugins"][name] = on
    elif kind == "hook" and name == "*":
        if on:
            s.pop("disableAllHooks", None)
        else:
            s["disableAllHooks"] = True
    elif kind == "hook":
        (hook_on if on else hook_off)(s, stash, name)
    else:
        raise ValueError(f"unknown kind {kind!r}")
    return s


def write_atomic(path, data):
    path = os.path.realpath(path)  # a symlinked settings.json keeps its link
    if os.path.exists(path):
        shutil.copy2(path, path + ".bak-claude-manager")
    d = os.path.dirname(path)
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".cm.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
            f.flush()
            os.fsync(f.fileno())
        if os.path.exists(path):
            os.chmod(tmp, os.stat(path).st_mode & 0o777)
        os.replace(tmp, path)
    except BaseException:
        os.unlink(tmp)
        raise


KINDS = ("skill", "command", "agent", "mcp", "hook", "plugin")


def files_of(kind, name):
    """What deleting removes: a skill's whole folder (and the folder its link points to), an agent's file."""
    if kind == "skill":
        link = os.path.join(CLAUDE, "skills", name)
        if not os.path.isfile(os.path.join(link, "SKILL.md")):
            raise SystemExit(f"no skill {name}")
        real = os.path.realpath(link)
        home = os.path.realpath(HOME)
        if real == home or os.path.basename(real) != name or not real.startswith(home + os.sep):
            raise SystemExit(f"refusing to trash {real}")  # a link to somewhere unexpected
        return [link, real] if os.path.islink(link) else [link]
    for p in glob.glob(os.path.join(CLAUDE, "agents", "**", "*.md"), recursive=True):
        if (front(p).get("name") or os.path.basename(p)[:-3]) == name:
            return [p]
    raise SystemExit(f"no agent {name}")


def delete(kind, name):
    paths = files_of(kind, name)
    r = subprocess.run(["/usr/bin/trash", *paths], capture_output=True, text=True)
    if r.returncode != 0 or any(os.path.lexists(p) for p in paths):
        raise SystemExit(f"trash failed: {(r.stderr or r.stdout).strip() or 'still there'}")
    s = load(SETTINGS, {})  # its switch goes too, or a later file of that name would start off
    if (kind == "skill" and name in s.get("skillOverrides", {})) or (kind == "agent" and name in deny_names(s)):
        write_atomic(SETTINGS, apply(s, [], kind, name, True))
    print(json.dumps(paths))


def main(argv):
    if argv[:1] == ["list"]:
        print(json.dumps(listing()))
    elif len(argv) == 4 and argv[0] == "set" and argv[1] in KINDS and argv[3] in ("on", "off"):
        _, kind, name, state = argv
        if not name or len(name) > 200 or any(c in name for c in "()\n"):
            sys.exit(f"bad name {name!r}")
        s = load(SETTINGS, {})  # read right before writing: Claude Code writes this file too
        stash = load(STASH, [])
        before = json.dumps(stash)
        apply(s, stash, kind, name, state == "on")
        if kind == "hook" and state == "off" and json.dumps(stash) != before:
            write_atomic(STASH, stash)  # the copy first: a hook is never only in neither file
        write_atomic(SETTINGS, s)
        if kind == "hook" and state == "on" and json.dumps(stash) != before:
            write_atomic(STASH, stash)
    elif len(argv) == 3 and argv[0] == "delete" and argv[1] in ("skill", "agent"):
        if not argv[2] or "/" in argv[2] or argv[2] in (".", ".."):
            sys.exit(f"bad name {argv[2]!r}")
        delete(argv[1], argv[2])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
