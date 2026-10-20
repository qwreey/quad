--!strict
--[[
	Dispatch diagnostics — the match-failure message builders, cold path only (they run while building an
	error or under `q.debug`). Split out of `Dispatch/init.luau`'s `Init` closure because they read nothing of
	the dispatch state: only the module's registered brand predicates (`module.BrandPredicates`) and the
	`DispatchHint` capability brand. `install(module)` returns the three functions for that module instance.
	Ref: H-902
]]

local Brand = require("../Brand")

local DispatchHintBrand = Brand.DispatchHintBrand -- the brand object itself, not the public `q.Protocols` table

local function install(module: any)
	-- Diagnostics only (cold path): every registered `is<Brand>` field of the module, base and provider
	-- alike, each `pcall`ed — a buggy predicate must not turn a match-failure diagnostic into its own raise.
	-- round11 `H-563` (탐사 G′ 1): a module-level `is*` helper that is NOT a brand predicate
	-- (`q.isEmpty`, a plugin's `isMobile` ignoring its argument) answered `true` for a plain
	-- props table and the `H-470` gate killed EVERY `D.<Class>{}`. The fix then was a probe
	-- (`{}`/`0` must be false), which still let `isNonEmptyList`-style helpers through
	-- (round13 `H-698`). round13 Q106 (user decision 2026-09-28): a brand predicate is one
	-- REGISTERED in the module instance's `BrandPredicates` (a provider registers its own at install —
	-- quad-roblox `RobloxFactory.luau`; base ones at `init.luau` / `Slot/init.luau`, 2026-10-01); every
	-- other `is*` field is ignored, no probing. Returns every brand the value carries, sorted by name.
	local BrandPredicates = module.BrandPredicates
	local function brandNamesOf(v: any): { string }
		local names = {} :: { string }
		for name, predicate in module do
			if type(name) == "string" and string.sub(name, 1, 2) == "is" and type(predicate) == "function" and BrandPredicates:Is(predicate) then
				local ok, hit = pcall(predicate, v)
				if ok and hit == true then
					table.insert(names, string.sub(name, 3)) -- "isTween" -> "Tween"
				end
			end
		end
		table.sort(names)
		return names
	end
	-- The same names as one message fragment (`"PreRef, Ref"`), nil when the value carries no registered brand.
	local function brandNameOf(v: any): string?
		local names = brandNamesOf(v)
		return if #names > 0 then table.concat(names, ", ") else nil
	end

	-- Subject `Dispatch:` (namespace, no function — round8 O-1): both raises are OUTERMOST
	-- and reach the user through any entry (`q.Elem "Frame" {…}`, `Dispatch.drive`, a direct
	-- `Dispatch.process`, a delegating handler), so naming one function (`drive:` in
	-- `H-494`, `process:` in K-3) was wrong for the others. The blame line already says
	-- where the user entered.
	-- [2026-10-06 user decision, round14 Q161·Q182 (a)] the cause sentence: a value that belongs to the
	-- `q.Protocols.DispatchHint` capability brand is asked once (`v:__dispatchHint(k)` — each brand says
	-- what it is for: Store / Context / Provider / Blocker / AttrKey in quad-base, Tween in quad-roblox);
	-- nil → the generic tail. Not wrapped (a throwing hook is undefined, like the Bindable hooks); runs only
	-- while building this error (zero cost on the normal path). The old per-name branches here (Store,
	-- Context/Provider) moved into those brands — Dispatch names no core object (`H-278`).
	local function noMatchMessage(k: any, v: any): string
		local names = brandNamesOf(v)
		local brand = if #names > 0 then table.concat(names, ", ") else nil
		local hint: any = nil
		if DispatchHintBrand:Is(v) then -- the brand object itself (`Brand.luau`), not the public `q.Protocols` table (round14 확인 패스 code-review 3)
			hint = v:__dispatchHint(k)
		end
		-- The generic tail. [2026-10-01 user decision] a hit on ANY registered predicate means the brand's
		-- owner is installed (base always; a provider registers at install), so "provider not initialized"
		-- can only fit a value that carries no registered brand (round11 `H-567` / `H-613`). round13 Q90 ⑩
		-- (user decision 2026-09-28): at a string key an unbranded value misses for two reasons we cannot
		-- tell apart here without asking the handler list — name both, neutral wording (base knows no engine
		-- terms). A provider IS installed in the common case, so the provider-only hint pointed the wrong
		-- way for `size` / `AbsoluteSize`.
		local tail = if hint ~= nil then " - " .. hint
			elseif brand == nil and type(k) == "string"
			then " - this key may not be a field of this element (a typo, a read-only field, or one from another class), or the provider that handles it (e.g. quad-roblox) is not initialized"
			-- round15 `H-916`: no handler takes a bare function at an array position, so it is almost always
			-- a constructor or component left uncalled (`{ Elem }` for `{ Elem {} }`) — the provider tail
			-- below sent the user to check their setup instead.
			elseif brand == nil and type(v) == "function"
			then " - a function in an array slot: a constructor or component that was not called? (a missing {} or ())"
			elseif brand == nil
			then " - check that the provider for this value (e.g. quad-roblox) is initialized"
			elseif type(k) == "string" then " - a quad value at a string key: it belongs in a numeric (array) slot"
			else " - this quad value has no handler at an array position"
		return `Quad0076 Dispatch: no handler matched key {tostring(k)} (value: {typeof(v)}{if brand then `, brand: {brand}` else ""})` .. tail
			-- `H-257`: a nil here often started life as the None sentinel (NoneHandler
			-- recursion erases the provenance) — say so, or the user is told they
			-- passed the one value None exists to be distinguishable from
			.. (if v == nil then " (a nil at this depth may be an unwrapped None or a reactive nil - the key's own handler must accept nil)" else "")
	end

	return {
		brandNamesOf = brandNamesOf,
		brandNameOf = brandNameOf,
		noMatchMessage = noMatchMessage,
	}
end

return install
