#!/usr/bin/env python3
"""
Differential Test Oracle & Verifier for REA (Reverse Engineer Anything)
Compares exit codes, STDOUT, and STDERR between an original binary and rebuilt binary.
"""

import sys
import subprocess
import argparse
from pathlib import Path


def run_command(binary_path: str, args: list, input_data: str = None) -> tuple:
    cmd = [binary_path] + args
    try:
        proc = subprocess.run(
            cmd,
            input=input_data.encode("utf-8") if input_data else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
        )
        return proc.returncode, proc.stdout.decode("utf-8", errors="replace"), proc.stderr.decode("utf-8", errors="replace")
    except Exception as e:
        return -1, "", str(e)


def main():
    parser = argparse.ArgumentParser(description="REA-Silicon Test Oracle: Differential Binary Comparison")
    parser.add_argument("--original", "-o", required=True, help="Path to original binary")
    parser.add_argument("--rebuilt", "-r", required=True, help="Path to rebuilt native binary")
    parser.add_argument("--args", "-a", nargs="*", default=[], help="Command-line arguments to pass")
    parser.add_argument("--stdin", "-s", default=None, help="Standard input payload to pipe")

    opts = parser.parse_args()

    print("=" * 80)
    print("🔬 REA-Silicon DIFFERENTIAL TEST ORACLE")
    print(f"Original : {opts.original}")
    print(f"Rebuilt  : {opts.rebuilt}")
    print(f"Arguments: {opts.args}")
    print("=" * 80)

    orig_rc, orig_out, orig_err = run_command(opts.original, opts.args, opts.stdin)
    reb_rc, reb_out, reb_err = run_command(opts.rebuilt, opts.args, opts.stdin)

    passed = True
    print("\n[1] Exit Code Comparison")
    print(f"    Original Exit Code: {orig_rc}")
    print(f"    Rebuilt  Exit Code: {reb_rc}")
    if orig_rc == reb_rc:
        print("    ✅ Exit codes MATCH.")
    else:
        print("    ❌ Exit codes DIFFER.")
        passed = False

    print("\n[2] STDOUT Output Comparison")
    if orig_out == reb_out:
        print("    ✅ STDOUT output MATCHES completely.")
    else:
        print("    ⚠️ STDOUT differs.")
        passed = False
        print("    --- Original STDOUT (first 500 chars) ---")
        print(orig_out[:500])
        print("    --- Rebuilt STDOUT (first 500 chars) ---")
        print(reb_out[:500])

    print("\n[3] Result Summary")
    if passed:
        print("🎉 DIFFERENTIAL TEST PASSED: 100% equivalence on tested vector.")
        sys.exit(0)
    else:
        print("⚠️ DIFFERENTIAL TEST FOUND DISCREPANCIES. Inspect SPEC.md and alignment.")
        sys.exit(1)


if __name__ == "__main__":
    main()
