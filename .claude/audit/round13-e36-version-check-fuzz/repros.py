#!/usr/bin/env python3
"""Hand-minimised repros for each divergence class, run against real impl + refs + python port."""
import sys; sys.argv = sys.argv[:1]
import fuzz, refs
CASES = [
    # (label, actual, pattern)
    ('big-int precision: real equal, digits greater', '3.99999999999999999999.0', '3.99999999999999999998^.1'),
    ('big-int precision: real equal, digits less', '3.9007199254740992.0', '3.9007199254740993^.0'),
    ('nan place passes a floor', '3.nan.0', '3.2^.0^'),
    ('inf place passes a floor', '3.inf.0', '3.2^.0^'),
    ('hex place', '3.0x10.0', '3.16^.0'),
    ('exponent place', '3.1e2.0', '3.99^.0'),
    ('leading space', '3. 3.0', '3.3^.0'),
    ('trailing dot number', '3.3..0', '3.3^.0'),
    ('negative N in prerelease tail', '3.0.0-rc.-1', '3.0.0-rc.-2^'),
    ('Arabic-Indic digit (python int accepts)', '3.٣.0', '3.3^.0'),
    ('underscore (python int accepts)', '3.3_0.0', '3.29^.0'),
    ('bare ^ place vs itself', '3.^.0', '3.^.0'),
    ('non-numeric N^ vs same string', '3.x^.0', '3.x^.0'),
    ('roblox/01 literal: * in last core place + tail', '3.0.0-rc.1', '3.0.*-rc.1'),
    ('roblox/01 literal: floor crosses into tail (source-header example)', '3.4.0-rc.0', '3.3^.0^-rc.1^'),
    ('docs example 3.3^.4^ accepts 3.4.0', '3.4.0', '3.3^.4^'),
    ('docs example 3.2^.0^|4.0^.0^ accepts 4.1.0', '4.1.0', '3.2^.0^|4.0^.0^'),
    ('docs example 3.3.0|3.3.0-rc.1^ accepts 3.3.0-rc.2', '3.3.0-rc.2', '3.3.0|3.3.0-rc.1^'),
    ('docs: tailless 3.*.* rejects rc', '3.3.0-rc.1', '3.*.*'),
    ('docs: CHANGELOG migration 3.*.*|3.*.*-rc.* accepts beta.1?', '3.3.0-beta.1', '3.*.*|3.*.*-rc.*'),
    ('docs: CHANGELOG migration accepts rc.1', '3.3.0-rc.1', '3.*.*|3.*.*-rc.*'),
    ('build ignored both sides', '3.2.0+b.1', '3.2^.0^+zzz'),
    ('build with dash is not a tail', '3.0.0+build-7', '3.0.0'),
    ('empty tail', '3.0.0-', '3.0.0-*'),
    ('empty tail vs tailless', '3.0.0-', '3.0.0'),
    ('empty pattern', '3.2.0', ''),
    ('empty alternative', '3.2.0', '3.2.0|'),
    ('leading zero exact', '03.2.0', '3.2.0'),
    ('leading zero floor', '03.2.0', '3^.2.0'),
    ('bump floor 3.2^.0^ rejects 3.1.9', '3.1.9', '3.2^.0^'),
    ('bump floor 3.2^.0^ rejects 4.0.0', '4.0.0', '3.2^.0^'),
]
res = fuzz.run_luau([(a, p) for _, a, p in CASES])
print('%-66s %-18s %-22s real ext01 rbx01 py' % ('case', 'actual', 'pattern'))
for (lbl, a, p), r in zip(CASES, res):
    print('%-66s %-18r %-22r %-4s %-5s %-5s %s' % (lbl, a, p, r, refs.ext01(a, p), refs.rbx01(a, p), fuzz.cv.matches_pattern(a, p)))
