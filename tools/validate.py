from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_GODOT_VERSION = "4.6.2"
IGNORED_GODOT_ERROR_PREFIXES = (
    "ERROR: Capture not registered: 'gdaimcp'.",
)


def run_streamed(command: list[str], cwd: Path) -> None:
    print(f"$ {' '.join(command)}")
    result = subprocess.run(command, cwd=cwd, check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)


def executable(name: str) -> str:
    resolved = shutil.which(name)
    if resolved:
        return resolved
    if os.name == "nt":
        for suffix in (".cmd", ".exe", ".bat"):
            resolved = shutil.which(f"{name}{suffix}")
            if resolved:
                return resolved
    return name


def run_captured(command: list[str], cwd: Path) -> str:
    print(f"$ {' '.join(command)}")
    result = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    if result.returncode != 0:
        raise SystemExit(result.returncode)
    return result.stdout


def validate_standards() -> None:
    run_streamed([sys.executable, "tools/standards/check.py"], ROOT)


def godot_version(path: str) -> str | None:
    try:
        result = subprocess.run(
            [path, "--version"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
    except FileNotFoundError:
        return None
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def resolve_godot_path() -> str:
    candidates: list[tuple[str, str]] = []
    env_path = os.environ.get("GODOT_PATH")
    if env_path:
        candidates.append(("GODOT_PATH", env_path))

    mcp_config = ROOT / ".mcp.json"
    if mcp_config.is_file():
        data = json.loads(mcp_config.read_text(encoding="utf-8"))
        configured = (
            data.get("mcpServers", {})
            .get("godot-mcp", {})
            .get("env", {})
            .get("GODOT_PATH")
        )
        if configured:
            candidates.append((".mcp.json", configured))

    candidates.append(("PATH", "godot"))

    checked: list[str] = []
    for source, candidate in candidates:
        version = godot_version(candidate)
        if version is None:
            checked.append(f"{source}: {candidate} (not executable)")
            continue
        checked.append(f"{source}: {candidate} ({version})")
        if version.startswith(f"{EXPECTED_GODOT_VERSION}.") and ".mono." not in version:
            return candidate

    print("Could not find a compatible Godot executable.")
    print(f"Expected non-Mono Godot {EXPECTED_GODOT_VERSION}. Checked:")
    for line in checked:
        print(f"  - {line}")
    raise SystemExit(1)


def validate_godot() -> None:
    godot = resolve_godot_path()
    command = [
        godot,
        "--headless",
        "--path",
        str(ROOT),
        "--script",
        "res://tools/godot/check_project.gd",
    ]
    output = run_captured(command, ROOT)
    error_lines = [
        line
        for line in output.splitlines()
        if line.startswith(("ERROR:", "SCRIPT ERROR:"))
        and not line.startswith(IGNORED_GODOT_ERROR_PREFIXES)
    ]
    if error_lines:
        print("Godot emitted error output:")
        for line in error_lines:
            print(f"  {line}")
        raise SystemExit(1)


def validate_mcp() -> None:
    mcp_root = ROOT / "tools" / "godot-mcp"
    npm = executable("npm")
    run_streamed([npm, "ci", "--ignore-scripts"], mcp_root)
    run_streamed([npm, "audit", "--audit-level=moderate"], mcp_root)
    run_streamed([npm, "test"], mcp_root)
    run_streamed([npm, "run", "build"], mcp_root)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run Off The Rails repository validation.")
    parser.add_argument("--standards", action="store_true", help="Run repository standards checks.")
    parser.add_argument("--godot", action="store_true", help="Run headless Godot project checks.")
    parser.add_argument("--mcp", action="store_true", help="Run godot-mcp dependency, test, and build checks.")
    parser.add_argument("--all", action="store_true", help="Run all checks.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not any([args.standards, args.godot, args.mcp, args.all]):
        args.all = True

    if args.all or args.standards:
        validate_standards()
    if args.all or args.godot:
        validate_godot()
    if args.all or args.mcp:
        validate_mcp()

    print("Validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
