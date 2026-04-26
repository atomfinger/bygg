#!/usr/bin/env python3
import json
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
CLI_DIR = REPO_ROOT / "packages" / "cli"
SCENARIOS_FILE = Path(__file__).parent / "integration_scenarios.json"
WORK_DIR = REPO_ROOT / "tmp" / "integration-test"
SERVER_STARTUP_WAIT = 3  # seconds to wait before assuming a server started ok
DOCKER_SERVICE_WAIT = (
    8  # seconds for external services (postgres, kafka) to become ready
)

GREEN = "\033[0;32m" if sys.stdout.isatty() else ""
YELLOW = "\033[0;33m" if sys.stdout.isatty() else ""
RED = "\033[0;31m" if sys.stdout.isatty() else ""
BOLD = "\033[1m" if sys.stdout.isatty() else ""
DIM = "\033[2m" if sys.stdout.isatty() else ""
RESET = "\033[0m" if sys.stdout.isatty() else ""


def run(cmd, cwd, log_path, extra_env=None):
    env = {**os.environ, **(extra_env or {})}
    with open(log_path, "w") as f:
        result = subprocess.run(
            cmd, cwd=cwd, stdout=f, stderr=subprocess.STDOUT, env=env
        )
    return result.returncode == 0


def kill_port(port: int | None) -> None:
    """Kill any process currently holding the given TCP port."""
    if port is None:
        return
    result = subprocess.run(
        ["lsof", "-ti", f":{port}"],
        capture_output=True,
        text=True,
    )
    for pid_str in result.stdout.strip().split("\n"):
        try:
            os.kill(int(pid_str), signal.SIGKILL)
        except (ProcessLookupError, ValueError, PermissionError):
            pass


def run_server(cmd, cwd, log_path, port: int, extra_env=None) -> bool:
    """Start a long-running server, wait to confirm startup, then kill it by port.
    Returns True if the process was still alive after SERVER_STARTUP_WAIT seconds."""
    kill_port(port)  # clear any leftover from a previous run

    env = {**os.environ, **(extra_env or {})}
    with open(log_path, "w") as f:
        proc = subprocess.Popen(
            cmd,
            cwd=cwd,
            stdout=f,
            stderr=subprocess.STDOUT,
            env=env,
        )

    time.sleep(SERVER_STARTUP_WAIT)

    exited = proc.poll() is not None
    proc.terminate()
    try:
        proc.wait(timeout=3)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()

    kill_port(port)  # kill any BEAM children that outlived the launcher

    return not exited


def load_env_example(out_dir: Path) -> dict:
    """Parse .env.example into a dict of key→value strings for subprocess env."""
    example = out_dir / ".env.example"
    if not example.exists():
        return {}
    env = {}
    for line in example.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            key, _, value = line.partition("=")
            env[key.strip()] = value.strip()
    return env


def external_docker_services(out_dir: Path) -> list[str]:
    """Return names of docker-compose services excluding the generated 'app' service.
    Returns an empty list if docker-compose.yml does not exist or docker is unavailable."""
    if not (out_dir / "docker-compose.yml").exists():
        return []
    result = subprocess.run(
        ["docker", "compose", "config", "--services"],
        cwd=out_dir,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    return [
        s.strip()
        for s in result.stdout.splitlines()
        if s.strip() and s.strip() != "app"
    ]


def compose_up(out_dir: Path, services: list[str], log_path: Path) -> bool:
    return run(["docker", "compose", "up", "-d"] + services, out_dir, log_path)


def compose_down(out_dir: Path, log_path: Path) -> None:
    run(["docker", "compose", "down", "-v"], out_dir, log_path)


def main():
    scenarios = json.loads(SCENARIOS_FILE.read_text())
    if WORK_DIR.exists():
        shutil.rmtree(WORK_DIR)
    WORK_DIR.mkdir(parents=True)

    passed, failed, skipped = [], [], []
    print(f"\n{BOLD}  bygg integration tests{RESET}\n")

    for s in scenarios:
        label = s["label"]
        proj = s["project"]
        deps = s["deps"]
        target = s.get("target", "erlang")
        skip = s.get("skip")
        run_mode = s.get("run")  # "exit", "server", or absent (skip run step)
        port = s.get("port")
        out_dir = WORK_DIR / proj

        print(f"  {label:<52}", end="", flush=True)

        if skip:
            print(f"{YELLOW}SKIP{RESET}")
            print(f"  {DIM}       {skip}{RESET}")
            skipped.append(label)
            continue

        dep_arg = ",".join(deps) if deps else None
        gen_cmd = [
            "gleam",
            "run",
            "-m",
            "bygg",
            "new",
            proj,
            f"--outdir={out_dir}",
            f"--target={target}",
        ]
        if dep_arg:
            gen_cmd.append(f"--dep={dep_arg}")

        steps = [
            ("generation", gen_cmd, CLI_DIR),
            ("deps", ["gleam", "deps", "download"], out_dir),
            ("check", ["gleam", "check"], out_dir),
        ]

        ok = True
        for step_name, cmd, cwd in steps:
            log = WORK_DIR / f"{proj}.{step_name}.log"
            if not run(cmd, cwd, log):
                print(f"{RED}FAIL{RESET} ({step_name})")
                print(log.read_text())
                ok = False
                break

        # Only spin up external services when there is actually a run step.
        services = external_docker_services(out_dir) if (ok and run_mode) else []
        if services:
            compose_log = WORK_DIR / f"{proj}.compose_up.log"
            if not compose_up(out_dir, services, compose_log):
                print(f"{RED}FAIL{RESET} (docker compose up)")
                print(compose_log.read_text())
                ok = False
            else:
                time.sleep(DOCKER_SERVICE_WAIT)

        try:
            if ok and run_mode == "exit":
                extra_env = load_env_example(out_dir)
                log = WORK_DIR / f"{proj}.run.log"
                if not run(["gleam", "run"], out_dir, log, extra_env):
                    print(f"{RED}FAIL{RESET} (run)")
                    print(log.read_text())
                    ok = False

            elif ok and run_mode == "server":
                extra_env = load_env_example(out_dir)
                log = WORK_DIR / f"{proj}.run.log"
                if not run_server(["gleam", "run"], out_dir, log, port, extra_env):
                    print(f"{RED}FAIL{RESET} (run — server crashed on startup)")
                    print(log.read_text())
                    ok = False
        finally:
            if services:
                compose_down(out_dir, WORK_DIR / f"{proj}.compose_down.log")

        if ok:
            print(f"{GREEN}PASS{RESET}")
            passed.append(label)
        else:
            failed.append(label)

    skip_str = f", {YELLOW}{len(skipped)} skipped{RESET}" if skipped else ""
    print(f"\n  {'─' * 54}")
    if not failed:
        print(f"  {GREEN}{BOLD}{len(passed)} passed{RESET}{skip_str}\n")
        sys.exit(0)
    else:
        print(
            f"  {BOLD}{len(passed)} passed, {RED}{len(failed)} failed{RESET}{skip_str}"
        )
        for s in failed:
            print(f"    ✗ {s}")
        print()
        sys.exit(1)


if __name__ == "__main__":
    main()
