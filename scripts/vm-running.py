#!/usr/bin/env python3
import sys
from pathlib import Path

disk = sys.argv[1]

for process in Path("/proc").iterdir():
    if not process.name.isdigit():
        continue
    try:
        args = (process / "cmdline").read_bytes().split(bytes([0]))
        if not args or "qemu-system-x86_64" not in Path(
            args[0].decode()
        ).name:
            continue
        if any(
            arg.decode(errors="replace").startswith(
                "file=" + disk + ","
            )
            for arg in args
        ):
            sys.exit(0)
    except (OSError, PermissionError):
        continue

sys.exit(1)
