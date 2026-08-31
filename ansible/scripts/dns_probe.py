#!/usr/bin/env python3
"""Issue one minimal UDP A query to a specific DNS server."""

from __future__ import annotations

import random
import socket
import struct
import sys


def encode_name(name: str) -> bytes:
    return b"".join(bytes([len(label)]) + label.encode("ascii") for label in name.split(".")) + b"\0"


def skip_name(packet: bytes, offset: int) -> int:
    while True:
        length = packet[offset]
        if length & 0xC0 == 0xC0:
            return offset + 2
        offset += 1
        if length == 0:
            return offset
        offset += length


def query(server: str, name: str) -> list[str]:
    query_id = random.SystemRandom().randrange(0, 65536)
    header = struct.pack("!HHHHHH", query_id, 0x0100, 1, 0, 0, 0)
    payload = header + encode_name(name) + struct.pack("!HH", 1, 1)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(5)
        sock.sendto(payload, (server, 53))
        packet, _ = sock.recvfrom(4096)
    response_id, flags, questions, answers, _, _ = struct.unpack("!HHHHHH", packet[:12])
    if response_id != query_id or flags & 0x000F:
        raise RuntimeError("DNS server returned an invalid response")
    offset = 12
    for _ in range(questions):
        offset = skip_name(packet, offset) + 4
    addresses: list[str] = []
    for _ in range(answers):
        offset = skip_name(packet, offset)
        record_type, record_class, _, length = struct.unpack("!HHIH", packet[offset : offset + 10])
        offset += 10
        value = packet[offset : offset + length]
        offset += length
        if record_type == 1 and record_class == 1 and length == 4:
            addresses.append(socket.inet_ntoa(value))
    return addresses


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: dns_probe.py SERVER NAME EXPECTED_IPV4")
    results = query(sys.argv[1], sys.argv[2])
    if sys.argv[3] not in results:
        raise SystemExit(f"unexpected DNS response: {results}")
    print(f"{sys.argv[2]} resolved to {sys.argv[3]} via {sys.argv[1]}")
