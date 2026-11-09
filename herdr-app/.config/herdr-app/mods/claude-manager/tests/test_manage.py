# python3 -I tests/test_manage.py : every kind off then on puts settings.json back byte for byte
import json, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
home = tempfile.mkdtemp()
cfg = os.path.join(home, ".claude")
for d in ("skills/demo", "agents", "commands"):
    os.makedirs(os.path.join(cfg, d))
open(os.path.join(cfg, "skills", "demo", "SKILL.md"), "w").write("---\nname: demo\ndescription: |\n  A demo\n  skill.\nother: x\n---\nbody")
open(os.path.join(cfg, "agents", "helper.md"), "w").write("---\nname: helper\ndescription: Helps.\n---\n")
open(os.path.join(cfg, "commands", "deep.md"), "w").write("# Go deep on one thing\n")
json.dump({"mcpServers": {"srv": {"command": "/usr/bin/srv", "env": {"TOKEN": "secret"}}}}, open(os.path.join(home, ".claude.json"), "w"))
HOOKS = {
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/block.sh"},
                                                {"type": "command", "command": "rtk hook claude"}]},
                   {"matcher": "Read", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/warn.sh"}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "node \"/x/graft-hooks.cjs\" stop"}]}],
}
orig = json.dumps({"permissions": {"allow": ["Read"], "deny": ["Bash(rm *)"]}, "hooks": HOOKS, "model": "opus",
                   "enabledPlugins": {"p@m": True, "q@m": False}}, indent=2) + "\n"
S = os.path.join(cfg, "settings.json")
open(S, "w").write(orig)
env = {**os.environ, "HOME": home, "CLAUDE_CONFIG_DIR": cfg}
run = lambda *a: subprocess.run([sys.executable, "-I", os.path.join(HERE, "manage.py"), *a], env=env, capture_output=True, text=True, check=True).stdout
L = lambda: json.loads(run("list"))
state = lambda: {k: {x["id"]: x["on"] for x in v} for k, v in L().items() if k != "settings"}

d = L()
assert d["skills"][0]["desc"] == "A demo skill.", d["skills"][0]
assert d["commands"] == [{"id": "deep", "name": "/deep", "desc": "Go deep on one thing", "on": True}], d["commands"]
assert "secret" not in json.dumps(d) and d["mcp"][0]["desc"] == "stdio · srv"
assert [p["on"] for p in d["plugins"]] == [True, False]
names = [f'{h["event"]} · {h["name"]}' if "event" in h else h["name"] for h in d["hooks"]]
assert names == ["All hooks", "PreToolUse · block", "PreToolUse · rtk hook", "PreToolUse · warn", "Stop · graft-hooks stop"], names
hid = dict(zip(names, (h["id"] for h in d["hooks"])))

for kind, name in [("skill", "demo"), ("command", "deep"), ("agent", "helper"), ("mcp", "srv"), ("plugin", "p@m"), ("hook", "*")]:
    run("set", kind, name, "off")
s = json.load(open(S))
assert s["skillOverrides"] == {"demo": "off", "deep": "off"} and "Agent(helper)" in s["permissions"]["deny"]
assert s["deniedMcpServers"] == [{"serverName": "srv"}] and s["enabledPlugins"]["p@m"] is False and s["disableAllHooks"] is True
run("set", "agent", "helper", "off")  # idempotent: no duplicate rule
assert json.load(open(S))["permissions"]["deny"].count("Agent(helper)") == 1
for kind, name in [("skill", "demo"), ("command", "deep"), ("agent", "helper"), ("mcp", "srv"), ("plugin", "p@m"), ("hook", "*")]:
    run("set", kind, name, "on")
assert open(S).read() == orig, open(S).read()

# hooks: off empties a group and a whole event; back on in another order lands where it was
order = ["PreToolUse · rtk hook", "Stop · graft-hooks stop", "PreToolUse · warn", "PreToolUse · block"]
for n in order:
    run("set", "hook", hid[n], "off")
s = json.load(open(S))
assert "hooks" not in s, s.get("hooks")
assert all(not on for i, on in state()["hooks"].items() if i != "*")
assert open(S + ".bak-claude-manager").read() != orig
for n in ["PreToolUse · block", "Stop · graft-hooks stop", "PreToolUse · rtk hook", "PreToolUse · warn"]:
    run("set", "hook", hid[n], "on")
assert json.load(open(S))["hooks"] == HOOKS, json.load(open(S))["hooks"]
assert json.load(open(os.path.join(cfg, "claude-manager", "hooks-off.json"))) == []
# one off, then back: byte for byte
run("set", "hook", hid["PreToolUse · rtk hook"], "off"); run("set", "hook", hid["PreToolUse · rtk hook"], "on")

bad = subprocess.run([sys.executable, "-I", os.path.join(HERE, "manage.py"), "set", "agent", "x)", "off"], env=env, capture_output=True)
assert bad.returncode != 0
assert subprocess.run([sys.executable, "-I", os.path.join(HERE, "manage.py"), "set", "hook", "nope", "off"], env=env, capture_output=True).returncode != 0
s = json.load(open(S)); s.pop("hooks"); o = json.loads(orig); o.pop("hooks")
assert s == o and json.load(open(S))["hooks"] == HOOKS
print("ok")

# delete: trash a skill (link + the folder it points to, all files) and an agent; switch cleaned
TRASH = os.path.join(home, "trashlog")
fake = os.path.join(home, "bin"); os.makedirs(fake)
# a fake /usr/bin/trash would need root; run delete() in-process with subprocess.run patched instead
sys.path.insert(0, HERE)
os.environ.update(env)
import importlib, manage
importlib.reload(manage)
real = os.path.join(home, ".agents", "skills", "linked"); os.makedirs(os.path.join(real, "refs"))
open(os.path.join(real, "SKILL.md"), "w").write("---\nname: linked\n---\n"); open(os.path.join(real, "refs", "a.md"), "w").write("x")
os.symlink(real, os.path.join(cfg, "skills", "linked"))
moved = []
def fake_run(cmd, **kw):
    for p in cmd[1:]:
        moved.append(p); (os.unlink if os.path.islink(p) or os.path.isfile(p) else shutil.rmtree)(p)
    return subprocess.CompletedProcess(cmd, 0, "", "")
import shutil
manage.subprocess.run = fake_run
manage.write_atomic(S, {**json.load(open(S)), "skillOverrides": {"linked": "off"}})
manage.delete("skill", "linked")
assert moved == [os.path.join(cfg, "skills", "linked"), os.path.realpath(real)] and not os.path.exists(real), moved
assert "skillOverrides" not in json.load(open(S))
manage.delete("agent", "helper")
assert not os.path.exists(os.path.join(cfg, "agents", "helper.md"))
for bad in [("skill", "nope"), ("agent", "nope")]:
    try: manage.delete(*bad); raise AssertionError(bad)
    except SystemExit: pass
print("delete ok")
