#!/usr/bin/env python3
"""Offline structural check for Sharetribe process dirs (no flex-cli needed).

Checks: format :v3; transition names unique; each non-initial :from state is
reached by some transition; timed (:at) transitions have no :actor; manual ones
have one; notifications reference existing transitions, a customer/provider
recipient, and a template dir with -html.html and -subject.txt files.
This is not a substitute for `flex-cli process --path <dir>`, which is the real validator.
Usage: scripts/check_process.py sharetribe/simple-request sharetribe/simple-request-v2
"""
import re, sys, pathlib

def blocks(src, key):
    """Return the top-level {...} maps inside the vector that follows `key`."""
    i = src.index(key) + len(key)
    i = src.index("[", i)
    depth, start, out = 0, None, []
    for j in range(i + 1, len(src)):
        c = src[j]
        if c == "{":
            if depth == 0: start = j
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0: out.append(src[start:j + 1])
        elif c == "]" and depth == 0:
            return out
    raise ValueError(f"unterminated vector after {key}")

def kw(block, key):
    m = re.search(re.escape(key) + r"\s+:([\w./-]+)", block)
    return m.group(1) if m else None

def check(d):
    d = pathlib.Path(d); errs = []
    src = "\n".join(l for l in (d / "process.edn").read_text().splitlines() if not l.lstrip().startswith(";"))
    if ":format :v3" not in src: errs.append("missing :format :v3")
    ts = blocks(src, ":transitions"); ns = blocks(src, ":notifications")
    names = [kw(t, ":name") for t in ts]
    if len(names) != len(set(names)): errs.append(f"duplicate transition names: {names}")
    reached = {kw(t, ":to") for t in ts}
    for t in ts:
        n, frm, actor, timed = kw(t, ":name"), kw(t, ":from"), kw(t, ":actor"), ":at" in t
        if frm and frm not in reached: errs.append(f"{n}: :from {frm} is never reached")
        if timed and actor: errs.append(f"{n}: timed transition must not have :actor")
        if not timed and not actor: errs.append(f"{n}: manual transition needs :actor")
        if ":actions" not in t: errs.append(f"{n}: missing :actions")
    if not any(kw(t, ":from") is None for t in ts): errs.append("no initial transition")
    for n in ns:
        nm, on, to, tpl = kw(n, ":name"), kw(n, ":on"), kw(n, ":to"), kw(n, ":template")
        if on not in names: errs.append(f"{nm}: :on {on} is not a transition")
        if to not in ("actor.role/customer", "actor.role/provider"): errs.append(f"{nm}: bad :to {to}")
        for suffix in ("-html.html", "-subject.txt"):
            if not (d / "templates" / tpl / f"{tpl}{suffix}").is_file():
                errs.append(f"{nm}: missing templates/{tpl}/{tpl}{suffix}")
    used = {kw(n, ":template") for n in ns}
    for t in (d / "templates").iterdir():
        if t.name not in used: errs.append(f"unused template dir: {t.name}")
    states = sorted(reached | {kw(t, ':from') for t in ts if kw(t, ':from')})
    print(f"{d}: {len(ts)} transitions, {len(ns)} notifications, states {states}")
    for e in errs: print("  ERROR", e)
    return not errs

ok = all([check(p) for p in sys.argv[1:]])
print("process check:", "PASS" if ok else "FAIL"); sys.exit(0 if ok else 1)
