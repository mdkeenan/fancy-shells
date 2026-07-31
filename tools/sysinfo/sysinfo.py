#!/usr/bin/env python
"""fssysinfo - quick snapshot of the machine's CPU, memory, disk, and network."""
import argparse
import platform
import shutil
import socket
import sys

try:
    import psutil
except ImportError:
    psutil = None


def get_ip():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except OSError:
        return "unavailable"


def bytes_to_gb(n):
    return n / (1024 ** 3)


def main():
    parser = argparse.ArgumentParser(prog="fssysinfo", description="Print a snapshot of system resources.")
    parser.parse_args()

    print(f"Host:       {platform.node()}")
    print(f"OS:         {platform.system()} {platform.release()}")
    print(f"Python:     {platform.python_version()}")
    print(f"Local IP:   {get_ip()}")

    if psutil is None:
        print("\nCPU/memory details require 'psutil'. Install it with: pip install psutil", file=sys.stderr)
    else:
        print(f"CPU cores:  {psutil.cpu_count(logical=True)} logical / {psutil.cpu_count(logical=False)} physical")
        print(f"CPU usage:  {psutil.cpu_percent(interval=0.5)}%")

        mem = psutil.virtual_memory()
        print(f"Memory:     {bytes_to_gb(mem.used):.1f} GB used / {bytes_to_gb(mem.total):.1f} GB total ({mem.percent}%)")

    total, used, free = shutil.disk_usage(".")
    print(f"Disk (cwd): {bytes_to_gb(used):.1f} GB used / {bytes_to_gb(total):.1f} GB total ({used / total * 100:.1f}%)")


if __name__ == "__main__":
    main()
