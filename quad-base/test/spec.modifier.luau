--!nocheck
--[[
	Modifier 값 런타임 계약 (M7 단위 ①, round17) — `base/modifier-plan.md`
	3(immutable clone 체이닝, `Modifier()`)·4(setter 리터럴/함수, 내부 저장소,
	핸들러 계층 값 error)·4-1(4분기)·8(`Apply`)·9(`Overridden`·`Peek`)·2-1(`None`
	실재값 vs `nil` 부재)절 + M2가 심은 `isModifier` 가드(7절)의 실물 재확인.
	flatten/`ProcessedModifier`는 단위 ②(`spec.flatten`). 이 spec의 9~12번 블록은 단위 ④(modifier-plan 11절 —
	클래스 태그·`TypedFactory`/`DefineSubtype`·검사형 `As<Class>()`·무검사 `As(name)`·예약 캐스트 접두).
]]

local mock = require("./mock")
local ModifierModule = require("../src/Modifier")
local FieldsKey = ModifierModule._FieldsKey

local SPEC_FILE = "spec.modifier.luau"
local q = mock.newQuad()
local Modifier = q.Modifier
local None = q.None

local function fieldOf(mod, key)
	return mod[FieldsKey][key]
end

print("=== 1. Modifier() — 빈 인스턴스, 브랜드, frozen, 예약 메소드 ===")
do
	local m = Modifier()
	assert(q.isModifier(m), "brand")
	assert(next(m[FieldsKey]) == nil, "no fields")
	assert(not pcall(function()
		m.x = 1
	end), "outer table frozen")
	assert(type(m.Apply) == "function" and type(m.Peek) == "function" and type(m.Overridden) == "function", "reserved methods resolve before the generic setter")
	assert(rawget(m, "FontSize") == nil, "no literal field keys ever land on self")
	print("PASS")
end

print()
print("=== 2. setter 체이닝 — 리터럴/함수, 원본 불변, 형제 분기, 재호출(스파이크 17 재현) ===")
do
	local m0 = Modifier()
	local m1 = m0:FontSize(14)
	local m2 = m1:Round(8)
	local m3 = m2:FontSize(function(old)
		return old * 1.2
	end)
	assert(fieldOf(m1, "FontSize") == 14 and fieldOf(m2, "Round") == 8, "literal setters")
	assert(fieldOf(m3, "FontSize") == 14 * 1.2 and fieldOf(m3, "Round") == 8, "transform gets the raw current value; other fields carried")
	assert(fieldOf(m0, "FontSize") == nil and fieldOf(m1, "Round") == nil and fieldOf(m2, "FontSize") == 14, "originals untouched (immutable)")
	assert(m1 ~= m2 and m2 ~= m3 and q.isModifier(m3), "every setter returns a new branded Modifier")
	local a, b = m1:Round(4), m1:Round(100)
	assert(fieldOf(a, "Round") == 4 and fieldOf(b, "Round") == 100 and fieldOf(m1, "Round") == nil, "sibling branches do not cross-contaminate")
	local deep = m1
	for i = 1, 5 do
		deep = deep:Round(function(old)
			return (old or 0) + i
		end)
	end
	assert(fieldOf(deep, "Round") == 15, "re-chaining the same field keeps going through __index")
	-- nil = 필드 부재(2-1 M-5), None = 실재값(유일한 unsetter)
	local gone = m2:Round(nil)
	assert(fieldOf(gone, "Round") == nil and fieldOf(gone, "FontSize") == 14, "mod:X(nil) yields a Modifier WITHOUT that field")
	local unset = m2:Round(None)
	assert(fieldOf(unset, "Round") == None, "mod:X(None) stores None as a real value")
	print("PASS")
end

print()
print("=== 3. State 필드 — 리터럴은 반응성을 끊고, 함수는 :Compute 파생으로 반응성 유지 (4-1) ===")
do
	local src = q.Source(10)
	local m = Modifier():Size(src)
	assert(fieldOf(m, "Size") == src, "a State literal is stored as the handle itself")
	local derived = m:Size(function(old)
		return old:Get() * 2
	end)
	local d = fieldOf(derived, "Size")
	assert(q.isState(d) and d ~= src and d:Get() == 20, "State + function → old:Compute(fn), a derived State")
	src:Set(15)
	assert(d:Get() == 30, "derived field stays reactive")
	local cut = derived:Size(99)
	assert(fieldOf(cut, "Size") == 99, "State + literal → replaced wholesale (reactivity deliberately cut)")
	print("PASS")
end

print()
print("=== 4. Peek — raw 그대로(State 핸들·None·nil 구별), Apply = factory(self) ===")
do
	local src = q.Source("a")
	local m = Modifier():Text(src):Gone(None)
	assert(m:Peek("Text") == src, "Peek returns the State handle, never :Get()")
	assert(m:Peek("Gone") == None and m:Peek("Never") == nil, "None vs nil are distinguishable")
	local seen
	local out = m:Apply(function(self)
		seen = self
		return self:FontSize(3)
	end)
	assert(seen == m and fieldOf(out, "FontSize") == 3 and fieldOf(m, "FontSize") == nil, "Apply calls factory(self) and returns its result as-is")
	local Boldify = function(weight)
		return function(mod)
			return mod:FontWeight(weight)
		end
	end
	local chained = Modifier():FontSize(14):Apply(Boldify(700)):Apply(function(mod)
		return mod:Italic(true)
	end)
	assert(fieldOf(chained, "FontWeight") == 700 and fieldOf(chained, "Italic") == true and fieldOf(chained, "FontSize") == 14, "read order = apply order")
	print("PASS")
end

print()
print("=== 5. Overridden — 닷·콜론, 뒤가 필드 단위로 이김, 입력 불변, baked 값 그대로, 비Modifier 인자 error ===")
do
	local a = Modifier():FontSize(14):Color("red"):Keep(1)
	local b = Modifier():FontSize(20):Color(None)
	local m = Modifier.Overridden(a, b)
	assert(fieldOf(m, "FontSize") == 20 and fieldOf(m, "Color") == None and fieldOf(m, "Keep") == 1, "later wins field by field; None wins as a real value")
	assert(fieldOf(a, "FontSize") == 14 and fieldOf(b, "Keep") == nil, "inputs untouched")
	local n = a:Overridden(b)
	assert(fieldOf(n, "FontSize") == 20 and fieldOf(n, "Keep") == 1, "colon form == Modifier.Overridden(self, ...)")
	assert(fieldOf(Modifier.Overridden(b, a), "FontSize") == 14, "order-dependent (A:Overridden(B) ~= B:Overridden(A))")
	-- State 필드는 baked 핸들 그대로 복사(파생 재계산 없음)
	local src = q.Source(1)
	local withState = Modifier.Overridden(Modifier():X(src), Modifier():Y(2))
	assert(fieldOf(withState, "X") == src, "State handles are copied as-is (baked)")
	-- 그 필드 없는 Modifier(mod:X(nil))는 상대 값을 못 덮는다(2-1 M-5 대조)
	local absent = a:Color(nil)
	assert(fieldOf(Modifier.Overridden(b, absent), "Color") == None, "absent field cannot override; None can")
	local ok, err = pcall(function()
		Modifier.Overridden(a, 5)
	end)
	assert(not ok, "non-Modifier argument rejected")
	mock.assertBlamesUser(err, SPEC_FILE, "Overridden blame")
	local ok2 = pcall(function()
		Modifier.Overridden()
	end)
	assert(not ok2, "zero arguments rejected")
	print("PASS")
end

print()
print("=== 6. 핸들러 계층 값은 필드에 못 든다 — 리터럴·변환 반환 둘 다 즉시 error, State는 통과 ===")
do
	local m = Modifier()
	local cases = {
		["Modifier"] = Modifier(),
		["Observer"] = q.Source(1):Observer(function() end),
		["Effect"] = q.Effect(function() end),
		["Slot"] = q.Slot(),
	}
	for label, v in cases do
		local ok, err = pcall(function()
			m:Field(v)
		end)
		assert(not ok, "literal rejected: " .. label)
		mock.assertBlamesUser(err, SPEC_FILE, "handler-layer literal " .. label)
		local ok2, err2 = pcall(function()
			m:Field(function()
				return v
			end)
		end)
		assert(not ok2, "transform result rejected: " .. label)
		mock.assertBlamesUser(err2, SPEC_FILE, "handler-layer via fn " .. label)
	end
	assert(q.isState(fieldOf(m:Field(q.Source(1)), "Field")), "State/Source pass")
	print("PASS")
end

print()
print("=== 7. M2 가드 재확인(7절) — Modifier는 State/Source의 값이 될 수 없다 ===")
do
	local mod = Modifier():X(1)
	local ok1, err1 = pcall(function()
		q.Source(mod)
	end)
	assert(not ok1, "Source(mod) rejected")
	mock.assertBlamesUser(err1, SPEC_FILE, "Source(mod)")
	local src = q.Source(1)
	local ok2, err2 = pcall(function()
		src:Set(mod)
	end)
	assert(not ok2, "src:Set(mod) rejected")
	mock.assertBlamesUser(err2, SPEC_FILE, "Set(mod)")
	local computed = src:Compute(function()
		return mod
	end)
	local ok3 = pcall(function()
		computed:Get()
	end)
	assert(not ok3, "a Compute yielding a Modifier is rejected at cache time")
	print("PASS")
end

print()
print("=== 8. Modifier(...) 인자(H-310, 사용자 확정) — Modifier/필드 테이블 혼합, 뒤가 덮어씀, 검증 셋 ===")
do
	local base = Modifier():FontSize(14):Color("red")
	local m = Modifier(base, { FontSize = 20, Bold = true }, Modifier():Color(None))
	assert(fieldOf(m, "FontSize") == 20 and fieldOf(m, "Bold") == true and fieldOf(m, "Color") == None, "later args override field-wise; None is a real value")
	assert(fieldOf(base, "FontSize") == 14 and fieldOf(base, "Color") == "red", "inputs untouched")
	assert(next(Modifier()[FieldsKey]) == nil and next(Modifier({})[FieldsKey]) == nil, "Modifier() == Modifier({})")
	local src = q.Source(1)
	assert(fieldOf(Modifier({ X = src }), "X") == src, "State values pass through the field table")
	for label, fn in {
		["non-table arg"] = function()
			Modifier(5)
		end,
		["numeric key"] = function()
			Modifier({ [1] = "x" })
		end,
		["handler-layer value"] = function()
			Modifier({ X = Modifier() })
		end,
		-- 리뷰 반영(에이전트 추가 규칙): quad 객체는 필드 테이블이 아니다
		["Source arg"] = function()
			Modifier(q.Source(1))
		end,
		["None arg"] = function()
			Modifier(None)
		end,
		["function value"] = function()
			Modifier({ X = function() end })
		end,
	} :: { [string]: () -> () } do
		local ok, err = pcall(fn)
		assert(not ok, "rejected: " .. label)
		mock.assertBlamesUser(err, SPEC_FILE, "Modifier(...) " .. label)
	end
	print("PASS")
end

print()
local R: any = nil -- 9절이 등록한 클래스 생성자(10~12절 공유)
print("=== 9. TypedFactory(name) / DefineSubtype(parent, subtype) — 한 함수에 한 일, dedup, 부모 여럿, 순환 거부 (11절) ===")
do
	local TF, DS = Modifier.TypedFactory, Modifier.DefineSubtype
	-- 관계는 순서 자유(양쪽 이름이 같이 알려진다) — 잎부터 등록해도 된다
	DS("SpecGuiObject", "SpecTextLabel")
	DS("SpecInstance", "SpecGuiObject")
	DS("SpecInstance", "SpecUICorner")
	local Inst, Gui, Label, Corner = TF("SpecInstance"), TF("SpecGuiObject"), TF("SpecTextLabel"), TF("SpecUICorner")
	assert(type(Label) == "function", "TypedFactory returns the tagged constructor")
	local t = Label({ Text = "x" }, Modifier():Bold(true))
	assert(q.isModifier(t) and t.__quadModifier == "SpecTextLabel", "constructor tags the value with the class name")
	assert(fieldOf(t, "Text") == "x" and fieldOf(t, "Bold") == true, "same merge body as Modifier(...) (H-310)")
	assert(Modifier().__quadModifier == true, "base Modifier() stays untyped (true)")
	assert(t:Text("y").__quadModifier == "SpecTextLabel", "setters keep the tag")
	assert(TF("SpecTextLabel") == Label, "TypedFactory dedup: same name → same ctor")
	DS("SpecGuiObject", "SpecTextLabel") -- 같은 간선 재등록은 no-op
	-- 부모 여럿(인터페이스): 컴포넌트 클래스가 엔진 클래스와 인터페이스를 동시에 상속
	DS("SpecTextButton", "SpecMaterialButton")
	DS("SpecGuiObject", "SpecTextButton")
	DS("SpecElevated", "SpecMaterialButton")
	local Material = TF("SpecMaterialButton")
	assert(Material():Elevation(2).__quadModifier == "SpecMaterialButton", "custom class is first-class")
	assert(TF("SpecElevated")():Elevation(1):AsSpecMaterialButton().__quadModifier == "SpecMaterialButton", "descent through the interface parent")
	assert(Inst():AsSpecMaterialButton().__quadModifier == "SpecMaterialButton", "descent through the engine parent path")
	for label, fn in {
		["cycle"] = function()
			DS("SpecTextLabel", "SpecInstance")
		end,
		["self edge"] = function()
			DS("SpecInstance", "SpecInstance")
		end,
		["bad name"] = function()
			TF(5)
		end,
		["bad parent"] = function()
			DS(nil, "SpecX")
		end,
	} :: { [string]: () -> () } do
		local ok, err = pcall(fn)
		assert(not ok, "rejected: " .. label)
		mock.assertBlamesUser(err, SPEC_FILE, "registry " .. label)
	end
	R = { Inst = Inst, Gui = Gui, Label = Label, Corner = Corner, Material = Material }
	print("PASS")
end

print()
print("=== 10. As<Class>() — 검사형 하강: 무타입·자기·조상 태그만 통과, 미등록·비조상은 사용자 줄 error ===")
do
	local g = R.Gui():Visible(true)
	local down = g:AsSpecTextLabel()
	assert(down.__quadModifier == "SpecTextLabel" and fieldOf(down, "Visible") == true, "downcast retags, fields kept")
	assert(g.__quadModifier == "SpecGuiObject", "source untouched (immutable clone)")
	assert(R.Inst():Name("n"):AsSpecGuiObject():AsSpecMaterialButton().__quadModifier == "SpecMaterialButton", "two-step descent")
	assert(down:AsSpecTextLabel() == down or down:AsSpecTextLabel().__quadModifier == "SpecTextLabel", "identity cast")
	assert(Modifier():X(1):AsSpecUICorner().__quadModifier == "SpecUICorner", "untyped (true) casts anywhere")
	for label, fn in {
		["unknown class"] = function()
			g:AsSpecNope()
		end,
		["not an ancestor (sibling)"] = function()
			g:AsSpecTextLabel():AsSpecUICorner()
		end,
		["upcast"] = function()
			down:AsSpecGuiObject()
		end,
	} :: { [string]: () -> () } do
		local ok, err = pcall(fn)
		assert(not ok, "rejected: " .. label)
		mock.assertBlamesUser(err, SPEC_FILE, "As<Class> " .. label)
	end
	print("PASS")
end

print()
print("=== 11. As() / As(name) — 무검사: 인자 없으면 self, 이름은 존재 검사만(조상 무관), 잘못된 이름은 error ===")
do
	local corner = R.Corner():CornerRadius(4)
	assert(corner:As() == corner, "As() is the value itself (type-level cast only)")
	local forced = corner:As("SpecTextLabel")
	assert(forced.__quadModifier == "SpecTextLabel" and fieldOf(forced, "CornerRadius") == 4, "As(name) retags without an ancestry check")
	for label, fn in {
		["unknown name"] = function()
			corner:As("SpecNope")
		end,
		["non-string"] = function()
			corner:As(3)
		end,
	} :: { [string]: () -> () } do
		local ok, err = pcall(fn)
		assert(not ok, "rejected: " .. label)
		mock.assertBlamesUser(err, SPEC_FILE, "As(name) " .. label)
	end
	print("PASS")
end

print()
print("=== 12. 예약 캐스트 접두 — As+대문자는 setter가 되지 않는다(오타가 필드로 새지 않음), As+소문자는 setter ===")
do
	local m = Modifier()
	local ok = pcall(function()
		m:AsTextLabl() -- 오타: 옛 런타임이면 필드 "AsTextLabl" = nil 의 조용한 no-op
	end)
	assert(not ok, "unknown As<Name> errors instead of minting a field")
	assert(fieldOf(m:AspectRatio(2), "AspectRatio") == 2, "As + lowercase is an ordinary setter")
	assert(fieldOf(m:Assume(1), "Assume") == 1, "lowercase after As stays a setter")
	-- Overridden 결과는 무타입(입력 태그를 고르지 않는다 — 필요하면 As<Class>로)
	assert(Modifier.Overridden(R.Gui():X(1), R.Label():Y(2)).__quadModifier == true, "Overridden result is untyped")
	print("PASS")
end

print()
print()
print("=== 13. 3순회 H-377 — 브랜드는 메타테이블이 아니다: AttributeKey/MapperDescriptor는 필드 테이블이 아니다(Name이 필드로 병합돼 조용히 rename되던 것) ===")
do
	local okK, errK = pcall(function()
		q.Modifier(q.AttributeKey("Selected"))
	end)
	assert(not okK and string.find(tostring(errK), "must be a Modifier or a plain field table", 1, true) ~= nil, "AttributeKey is not a field table: " .. tostring(errK))
	mock.assertBlamesUser(errK, "spec.modifier.luau", "AttributeKey-arg blame")
	local desc = q.newMapperClass("Frame")("k")({})
	local okD, errD = pcall(function()
		q.Modifier(desc)
	end)
	assert(not okD and string.find(tostring(errD), "must be a Modifier or a plain field table", 1, true) ~= nil, "MapperDescriptor is not a field table: " .. tostring(errD))
	-- positive control — a real plain table still merges
	assert(q.Modifier({ Name = "x" }):Peek("Name") == "x", "plain field table untouched")
	print("PASS")
end

print("=== 14. 회신 3차 Q11 (a) — 제네릭 setter도 construct처럼 문자열 키만(H-310 거울): m[AttributeKey]는 즉시 error, 사용자 줄 blame ===")
do
	local m = q.Modifier({})
	local okK, errK = pcall(function()
		return (m :: any)[q.AttributeKey("Hp")]
	end)
	assert(not okK and string.find(tostring(errK), "setter keys must be strings", 1, true) ~= nil, "non-string setter key: " .. tostring(errK))
	mock.assertBlamesUser(errK, "spec.modifier.luau", "setter key blame")
	assert(q.Modifier({}):Name("x"):Peek("Name") == "x", "string setters untouched")
	-- round3 `H-448`: construct refuses the keys the setter path can never produce
	for _, bad in { { AsTextLabl = 1 }, { Apply = 1 }, { [""] = 1 } } :: { any } do
		local okB, errB = pcall(function() return q.Modifier(bad) end)
		assert(not okB and (string.find(tostring(errB), "reserved", 1, true) ~= nil or string.find(tostring(errB), "non-empty", 1, true) ~= nil), "construct rejects: " .. tostring(errB))
		mock.assertBlamesUser(errB, "spec.modifier.luau", "construct key blame")
	end
	print("PASS")
end

print()
print("=== ALL PASS ===")
