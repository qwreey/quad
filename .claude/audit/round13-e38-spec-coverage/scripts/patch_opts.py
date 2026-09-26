"""Scratch-copy only: log every option key/value at the option-consuming entries (same line — line numbers preserved)."""
import sys, os
root = sys.argv[1]
def log(site, var, extra=''):
    return (f' for __k, __v in (if type({var}) == "table" then {var} else {{}}) :: any do print("@@OPT\\t{site}" {extra}.. "\\t" .. tostring(__k) '
            f'.. "\\t" .. typeof(__v) .. "\\t" .. tostring(__v)) end; if {var} == nil then print("@@OPT\\t{site}" {extra}.. "\\t<nil>") end')
SITES = [('quad-base/src/Debounce.luau', 'local function make(module: any, name: string, reset: boolean, opts: any): any', log('', 'opts', '.. name ')),
         ('quad-roblox/src/Tween.luau', 'local function newTween(opts: any, raise: ((string, number) -> ())?): any', log('Tween', 'opts')),
         ('quad-roblox/src/Animate.luau', 'local function Animate(info: any): any', log('Animate', 'info')),
         ('quad-base/src/Slot/List.luau', 'function S.Slot_mt.List(self: any, data: any, updateFn: any, keyFn: any?, opts: any?): any', log('SlotList', 'opts')),
         ('quad-base/src/Slot/List.luau', 'function S.Slot_mt.Single(self: any, state: any, updateFn: any?, opts: any?): any', log('SlotSingle', 'opts'))]
for rel, sig, add in SITES:
    for base in [os.path.join(root, rel)] + [os.path.join(dp, f) for dp, dn, fn in os.walk(root) for f in fn if '.pesde' in dp and os.path.join(dp, f).endswith(rel.split('/', 1)[1]) and rel.split('/')[0].replace('-', '_') in dp]:
        t = open(base).read()
        assert t.count(sig) == 1, (base, sig)
        t = t.replace(sig, sig + add); open(base, 'w').write(t); print('patched', base.replace(root, ''))
