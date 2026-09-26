-- 클래스마다 하나씩 생성된 별칭. Frame이라면:
D.Frame: (FrameParam<FrameElem>) -> Frame

-- props 테이블의 모양(생성 타입 — 클래스마다 프로퍼티·이벤트 목록이 다르다)
export type FrameParam<E> = {
	[number]: E,       -- 숫자 키: 자식과 디스크립터
	Size: PV8?,        -- 문자 키: 프로퍼티
	Visible: PV0?,
	-- …
	MouseEnter: (((x: number, y: number) -> ()) | StateMarker<(x: number, y: number) -> ()> | None)?,
	-- …
}
