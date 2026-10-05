import json
import os
from pathlib import Path
import re
import shutil
import tempfile
import tomllib


def read_json(path):
    return json.loads(path.read_text()) if path.exists() else {}


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as output:
            json.dump(value, output, indent=2)
            output.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    home = Path.home()
    agent = home / ".pi/agent"
    agent.mkdir(parents=True, exist_ok=True)
    codex = home / ".codex"
    config_path = codex / "config.toml"
    config = tomllib.loads(config_path.read_text()) if config_path.exists() else {}
    settings_path = agent / "settings.json"
    settings = read_json(settings_path)
    settings.update(defaultProvider="openai-codex", defaultModel="gpt-6.1-sol")
    settings.setdefault("defaultThinkingLevel", "medium")
    write_json(settings_path, settings)

    # Import only once so subsequent activations preserve edits made inside Pi.
    report_path = agent / "migration.json"
    if report_path.exists():
        return

    report = {"skills": [], "servers": [], "hosted_plugins": []}
    disabled = {
        Path(s["path"]).expanduser().resolve()
        for s in config.get("skills", {}).get("config", [])
        if s.get("enabled") is False
    }
    skill_roots = [codex / "skills", codex / "skills/.system", home / ".claude/skills"]
    servers = config.get("mcp_servers", {}).copy()
    # These remote packages are enabled in the app, outside config.toml's plugin table.
    remote_plugins = {
        "google-drive", "notion", "pages", "plugin-management", "sites",
        "work-pets", "write-like-me", "gmail", "github", "google-calendar",
        "granola", "slack",
    }
    cache = codex / "plugins/cache"
    for marketplace in sorted(cache.iterdir()) if cache.exists() else []:
        for plugin in sorted(marketplace.iterdir()):
            key = f"{plugin.name}@{marketplace.name}"
            enabled = config.get("plugins", {}).get(key, {}).get("enabled")
            if enabled is False or not (enabled or (
                marketplace.name == "openai-curated-remote" and plugin.name in remote_plugins
            )):
                continue
            versions = [p for p in plugin.iterdir() if p.is_dir() and p.name != "latest"]
            if not versions:
                continue
            root = plugin / "latest" if (plugin / "latest").is_dir() else max(
                versions, key=lambda p: p.stat().st_mtime
            )
            skill_roots.append(root / "skills")
            if (root / ".app.json").exists():
                report["hosted_plugins"].append(plugin.name)
            for name, server in read_json(root / ".mcp.json").get("mcpServers", {}).items():
                server = server.copy()
                for field in ("command", "cwd"):
                    if server.get(field, "").startswith("."):
                        server[field] = str((root / server[field]).resolve())
                servers.setdefault(name, server)

    seen = set()
    for root in skill_roots:
        for source in sorted(root.glob("*/SKILL.md")):
            if source.resolve() in disabled:
                continue
            content = source.read_text()
            match = re.search(r"^name:\s*[\"']?([^\n\"']+)[\"']?\s*$", content, re.M)
            name = re.sub(r"[^a-z0-9-]+", "-", match[1].strip().lower() if match else source.parent.name).strip("-")
            if name in seen:
                continue
            seen.add(name)
            destination = agent / "skills" / name
            if not destination.exists():
                shutil.copytree(source.parent, destination, ignore=shutil.ignore_patterns("__pycache__", ".DS_Store"))
                for path in [destination, *destination.rglob("*")]:
                    path.chmod(path.stat().st_mode | 0o200)
                if match:
                    migrated = content[:match.start()] + f"name: {name}" + content[match.end():]
                    (destination / "SKILL.md").write_text(migrated)
            report["skills"].append({"name": name, "source": str(source)})

    mcp_path = agent / "mcp.json"
    mcp = read_json(mcp_path)
    target_servers = mcp.setdefault("mcpServers", {})
    for name, source in servers.items():
        if source.get("enabled") is False:
            continue
        converted = {k: v for k, v in source.items() if k in (
            "command", "args", "cwd", "env", "url", "description"
        )}
        headers = source.get("http_headers", source.get("headers", {})).copy()
        for key, variable in source.get("env_http_headers", {}).items():
            headers[key] = "${" + variable + "}"
        if source.get("bearer_token_env_var"):
            headers["Authorization"] = "Bearer ${" + source["bearer_token_env_var"] + "}"
        if headers:
            converted["headers"] = headers
        converted["timeout"] = source.get("tool_timeout_sec", 120)
        if source.get("enabled_tools") or source.get("disabled_tools"):
            exposure = {tool: "hidden" for tool in source.get("disabled_tools", [])}
            for tool in source.get("enabled_tools", []):
                exposure.setdefault(tool, "codemode")
            if source.get("enabled_tools"):
                exposure["*"] = "hidden"
            converted["toolExposure"] = exposure
        target_servers.setdefault(name, converted)
        report["servers"].append(name)
    write_json(mcp_path, mcp)
    report["hosted_plugins"] = sorted(set(report["hosted_plugins"]))
    write_json(report_path, report)
    print(f"Pi: imported {len(report['skills'])} skills and {len(report['servers'])} MCP definitions")
    if report["hosted_plugins"]:
        print("Pi: hosted app connections need independent integrations: " + ", ".join(report["hosted_plugins"]))


if __name__ == "__main__":
    main()
