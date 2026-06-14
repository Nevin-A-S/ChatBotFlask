#!/usr/bin/env python3
"""
Create a root docker-compose.yml for the Oxford chatbot application.

Run from either Windows or Linux:
    python ChatBotFlask/create_docker_compose.py

The script writes docker-compose.yml in the repository root, one directory
above this ChatBotFlask folder.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
import textwrap


COMPOSE_FILE_NAME = "docker-compose.yml"
BACKEND_DIR = "ChatBotFlask"
FRONTEND_DIR = "ChatBotFlaskFrontEnd"
REQUIRED_ENV_KEYS = ("GEMINI_API_KEY", "GROQ_API_KEY")
LEGACY_ENV_KEYS = {
    "GEMINI_API": "GEMINI_API_KEY",
    "GROQ_API": "GROQ_API_KEY",
}


def find_project_root() -> Path:
    script_dir = Path(__file__).resolve().parent
    if script_dir.name == BACKEND_DIR:
        return script_dir.parent
    return Path.cwd().resolve()


def read_env_keys(env_file: Path) -> set[str]:
    if not env_file.exists():
        return set()

    keys: set[str] = set()
    for raw_line in env_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key = line.split("=", 1)[0].strip()
        if key:
            keys.add(key)
    return keys


def build_compose_yaml() -> str:
    return textwrap.dedent(
        """\
        services:
          backend:
            build:
              context: ./ChatBotFlask
              dockerfile: Dockerfile
            container_name: oxford-chatbot-backend
            env_file:
              - ./.env
            environment:
              FLASK_ENV: production
              FLASK_DEBUG: "0"
              GEMINI_API_KEY: ${GEMINI_API_KEY:-${GEMINI_API:-}}
              GROQ_API_KEY: ${GROQ_API_KEY:-${GROQ_API:-}}
            ports:
              - "5000:5000"
            restart: unless-stopped

          frontend:
            build:
              context: ./ChatBotFlaskFrontEnd
              dockerfile: Dockerfile
            container_name: oxford-chatbot-frontend
            depends_on:
              - backend
            ports:
              - "3000:80"
            restart: unless-stopped
        """
    )


def validate_project(root: Path) -> list[str]:
    errors: list[str] = []
    required_paths = (
        root / BACKEND_DIR / "Dockerfile",
        root / FRONTEND_DIR / "Dockerfile",
        root / FRONTEND_DIR / "nginx.conf",
    )

    for path in required_paths:
        if not path.exists():
            errors.append(f"Missing required file: {path}")

    return errors


def env_warnings(root: Path) -> list[str]:
    env_file = root / ".env"
    keys = read_env_keys(env_file)
    warnings: list[str] = []

    if not env_file.exists():
        warnings.append(
            "Root .env was not found. Create one beside docker-compose.yml with "
            "GEMINI_API_KEY=... and GROQ_API_KEY=..."
        )
        return warnings

    for legacy_key, required_key in LEGACY_ENV_KEYS.items():
        if legacy_key in keys and required_key not in keys:
            warnings.append(
                f".env has {legacy_key}, but the backend expects {required_key}. "
                f"Rename {legacy_key} to {required_key}."
            )

    missing_keys = [key for key in REQUIRED_ENV_KEYS if key not in keys]
    if missing_keys:
        warnings.append(
            "Missing backend env keys in root .env: " + ", ".join(missing_keys)
        )

    return warnings


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate docker-compose.yml in the repository root."
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite an existing docker-compose.yml.",
    )
    parser.add_argument(
        "--print",
        action="store_true",
        dest="print_only",
        help="Print the compose content without writing the file.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = find_project_root()
    compose_path = root / COMPOSE_FILE_NAME

    errors = validate_project(root)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    compose_yaml = build_compose_yaml()

    if args.print_only:
        print(compose_yaml)
    else:
        if compose_path.exists() and not args.force:
            print(
                f"ERROR: {compose_path} already exists. "
                "Use --force to overwrite it.",
                file=sys.stderr,
            )
            return 1

        compose_path.write_text(compose_yaml, encoding="utf-8", newline="\n")
        print(f"Created {compose_path}")

    warnings = env_warnings(root)
    if warnings:
        print()
        print("Environment warnings:")
        for warning in warnings:
            print(f"- {warning}")

    print()
    print("Next commands:")
    print("  docker compose up --build")
    print("  Open http://localhost:3000")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
