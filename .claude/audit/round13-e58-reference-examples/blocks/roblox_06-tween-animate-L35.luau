export type TweenConstructor = <T>(opts: TweenOptions<T>) -> Tween<T>

export type TweenOverride = "Cancel" | "Finish"
export type TweenOptions<T> = {
	read Value: T,                       -- 필수. 평범한 값이어야 한다
	read Info: TweenInfo?,               -- 있으면 아래 편의 필드를 전부 무시한다
	read Time: number?,
	read Style: Enum.EasingStyle?,
	read Direction: Enum.EasingDirection?,
	read RepeatCount: number?,
	read Reverses: boolean?,
	read DelayTime: number?,
	read Override: TweenOverride?,       -- 기본 "Cancel"
	read Dedup: boolean?,                -- 기본 true
	read Started: (() -> ())?,           -- 콜백 셋(인자 없음) — 뜻은 아래 "프로퍼티에서의 동작"
	read Completed: (() -> ())?,
	read Cancelled: (() -> ())?,
}
