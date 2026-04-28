from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class StandardsChecker:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.failures: list[str] = []

    def run(self) -> int:
        self._check_required_docs()
        self._check_agent_entrypoints()
        self._check_generated_artifacts()
        self._check_project_settings()
        self._check_node_runtime()
        self._check_architecture_boundaries()
        self._check_godot_validator()
        self._check_ci_workflow()

        if self.failures:
            print("Standards check failed:")
            for failure in self.failures:
                print(f"  - {failure}")
            return 1

        print("Standards check passed.")
        return 0

    def _path(self, relative: str) -> Path:
        return self.root / relative

    def _read_text(self, relative: str) -> str:
        path = self._path(relative)
        try:
            return path.read_text(encoding="utf-8")
        except FileNotFoundError:
            self.failures.append(f"Missing required file: {relative}")
            return ""

    def _load_json(self, relative: str) -> dict:
        text = self._read_text(relative)
        if not text:
            return {}
        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            self.failures.append(f"Invalid JSON in {relative}: {exc}")
            return {}

    def _require_file(self, relative: str) -> None:
        if not self._path(relative).is_file():
            self.failures.append(f"Missing required file: {relative}")

    def _require_contains(self, text: str, needle: str, source: str) -> None:
        if needle not in text:
            self.failures.append(f"{source} must contain `{needle}`")

    def _git_files(self, *args: str) -> list[str]:
        command = ["git", "ls-files", *args]
        result = subprocess.run(
            command,
            cwd=self.root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if result.returncode != 0:
            self.failures.append(f"`{' '.join(command)}` failed: {result.stderr.strip()}")
            return []
        return [line.strip() for line in result.stdout.splitlines() if line.strip()]

    def _check_required_docs(self) -> None:
        required_files = [
            "AGENTS.md",
            "CLAUDE.md",
            "docs/README.md",
            "docs/engineering/ARCHITECTURE.md",
            "docs/engineering/STANDARDS.md",
            "docs/engineering/VALIDATION.md",
            "docs/engineering/QUALITY.md",
            "docs/engineering/TECH_DEBT.md",
            "docs/engineering/MCP.md",
            "docs/engineering/exec-plans/README.md",
            "docs/engineering/exec-plans/active/README.md",
            "docs/engineering/exec-plans/completed/README.md",
            "docs/design/README.md",
            "docs/modding/README.md",
        ]
        for relative in required_files:
            self._require_file(relative)

        docs_index = self._read_text("docs/README.md")
        for link in [
            "engineering/ARCHITECTURE.md",
            "engineering/STANDARDS.md",
            "engineering/VALIDATION.md",
            "engineering/QUALITY.md",
            "engineering/TECH_DEBT.md",
            "engineering/MCP.md",
            "design/README.md",
            "modding/README.md",
        ]:
            self._require_contains(docs_index, link, "docs/README.md")

    def _check_agent_entrypoints(self) -> None:
        agents = self._read_text("AGENTS.md")
        claude = self._read_text("CLAUDE.md")

        if len(agents.splitlines()) > 120:
            self.failures.append("AGENTS.md must stay compact at 120 lines or fewer")

        stale_patterns = [
            "390 tests",
            "149+ tools",
            "game code blank",
            "Tooled Greenfield",
        ]
        for pattern in stale_patterns:
            if pattern in agents or pattern in claude:
                self.failures.append(f"Agent entrypoints contain stale phrase: {pattern}")

        for command in [
            "python tools/validate.py --standards",
            "python tools/validate.py --godot",
            "python tools/validate.py --mcp",
            "python tools/validate.py --all",
        ]:
            self._require_contains(agents, command, "AGENTS.md")

        if "AGENTS.md" not in claude or "docs/README.md" not in claude:
            self.failures.append("CLAUDE.md must delegate to AGENTS.md and docs/README.md")
        if len(claude.splitlines()) > 12:
            self.failures.append("CLAUDE.md must stay short to avoid duplicate guidance")

    def _check_generated_artifacts(self) -> None:
        candidates = [
            path
            for path in self._git_files() + self._git_files("--others", "--exclude-standard")
            if self._path(path).exists()
        ]
        generated = [
            path
            for path in candidates
            if self._is_generated_artifact(path)
        ]
        if generated:
            joined = ", ".join(sorted(generated))
            self.failures.append(f"Generated artifacts must not be tracked or unignored: {joined}")

    def _is_generated_artifact(self, path: str) -> bool:
        normalized = path.replace("\\", "/")
        with_slashes = f"/{normalized}"
        return (
            "__pycache__/" in normalized
            or normalized.endswith((".pyc", ".pyo", ".pyd"))
            or "/node_modules/" in with_slashes
            or normalized.startswith(".godot/")
            or normalized.startswith("tools/godot-mcp/build/")
        )

    def _check_project_settings(self) -> None:
        project = self._read_text("project.godot")
        if "[dotnet]" in project or "project/assembly_name" in project:
            self.failures.append("project.godot must not contain .NET settings without C# sources")

        if list(self.root.rglob("*.cs")):
            self.failures.append("C# sources exist; update standards before reintroducing .NET settings")

        for expected in [
            'run/main_scene="res://src/main.tscn"',
            'config/features=PackedStringArray("4.6", "Forward Plus")',
            'EventHooks="*res://src/scripting/event_hooks.gd"',
            'GDAIMCPRuntime="*uid://dcne7ryelpxmn"',
            'GameState="*res://src/autoloads/game_state.gd"',
            'ModLoader="*res://src/mod_system/mod_loader.gd"',
            'enabled=PackedStringArray("res://addons/gdai-mcp-plugin-godot/plugin.cfg")',
            '3d/physics_engine="Jolt Physics"',
        ]:
            self._require_contains(project, expected, "project.godot")

    def _check_node_runtime(self) -> None:
        package_json = self._load_json("tools/godot-mcp/package.json")
        package_lock = self._load_json("tools/godot-mcp/package-lock.json")

        expected = ">=24.0.0 <25"
        package_engine = package_json.get("engines", {}).get("node")
        if package_engine != expected:
            self.failures.append(
                f"tools/godot-mcp/package.json engines.node must be `{expected}`, got `{package_engine}`"
            )

        lock_engine = (
            package_lock.get("packages", {})
            .get("", {})
            .get("engines", {})
            .get("node")
        )
        if lock_engine != expected:
            self.failures.append(
                f"tools/godot-mcp/package-lock.json engines.node must be `{expected}`, got `{lock_engine}`"
            )

    def _check_architecture_boundaries(self) -> None:
        required_dirs = [
            "src/crafting/domain",
            "src/crafting/infrastructure",
            "src/crafting/adapters",
            "src/isometric/domain",
            "src/isometric/infrastructure",
            "src/isometric/adapters",
            "src/interaction/domain",
            "src/interaction/infrastructure",
            "src/interaction/adapters",
            "src/train/cars/workshop/domain",
            "src/train/cars/workshop/infrastructure",
            "src/train/cars/workshop/adapters",
        ]
        for relative in required_dirs:
            if not self._path(relative).is_dir():
                self.failures.append(f"Missing expected architecture directory: {relative}")

        forbidden_resource = re.compile(r'res://src/.*/(adapters|infrastructure|ui|scenes)/')
        for path in self.root.glob("src/**/domain/*.gd"):
            if path.name.startswith("test_"):
                continue
            text = path.read_text(encoding="utf-8")
            if forbidden_resource.search(text):
                self.failures.append(
                    f"Domain script must not preload adapter/infrastructure/ui/scene resources: {path.relative_to(self.root)}"
                )

    def _check_godot_validator(self) -> None:
        script = self._read_text("tools/godot/check_project.gd")
        self._require_contains(script, "extends SceneTree", "tools/godot/check_project.gd")
        self._require_contains(script, "quit(1)", "tools/godot/check_project.gd")
        self._require_contains(script, "quit(0)", "tools/godot/check_project.gd")

    def _check_ci_workflow(self) -> None:
        workflow = self._read_text(".github/workflows/ci.yml")
        for expected in [
            "permissions:",
            "contents: read",
            "timeout-minutes:",
            "node-version: 24",
            "GODOT_VERSION: 4.6.2-stable",
            "python tools/validate.py --standards",
            "python tools/validate.py --godot",
            "python tools/validate.py --mcp",
        ]:
            self._require_contains(workflow, expected, ".github/workflows/ci.yml")


def main() -> int:
    return StandardsChecker(ROOT).run()


if __name__ == "__main__":
    sys.exit(main())
