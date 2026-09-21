// [2026-09-21 사용자 결정 — docs-review 1-1] GFM 각주(`[^name]`)를 페이지 하단으로 점프시키지 않고, 각주 번호를
// 누르면 그 자리에 작은 다이얼로그(네이티브 popover)로 띄운다 — 위키의 각주 툴팁과 같은 모양. 읽던 자리를 잃지 않게
// 하는 것이 목적(괄호 풀이는 아는 사람도 매번 건너뛰어야 해서 각주로 택함). Popover API가 없는 브라우저에서는 기본
// 동작(하단으로 점프)을 그대로 둔다. 하단 각주 목록은 그대로 남긴다(인쇄·검색·popover 미지원 대비). 의존성 없음.
(function () {
	if (!('showPopover' in HTMLElement.prototype)) return;
	var current = null;

	function close() {
		if (current) { try { current.hidePopover(); } catch (e) {} current.remove(); current = null; }
	}

	function open(ref) {
		close();
		var id = decodeURIComponent((ref.getAttribute('href') || '').replace(/^#/, ''));
		var li = id && document.getElementById(id);
		if (!li) return false;
		var box = document.createElement('div');
		box.className = 'fn-popover';
		box.setAttribute('popover', 'auto');
		box.innerHTML = li.innerHTML;
		// 각주 하단 목록의 "되돌아가기" 링크(↩)는 다이얼로그 안에서 뜻이 없다
		box.querySelectorAll('a[data-footnote-backref]').forEach(function (a) { a.remove(); });
		document.body.appendChild(box);
		current = box;
		box.addEventListener('toggle', function (e) { if (e.newState === 'closed') { box.remove(); if (current === box) current = null; } });
		box.showPopover();
		// 번호 바로 아래, 화면 안에 들어오게 좌우를 맞춘다(popover는 top layer라 position:fixed 좌표를 그대로 쓴다)
		var r = ref.getBoundingClientRect();
		var w = box.offsetWidth, h = box.offsetHeight;
		var left = Math.max(8, Math.min(r.left, window.innerWidth - w - 8));
		var top = r.bottom + 6;
		if (top + h > window.innerHeight - 8) top = Math.max(8, r.top - h - 6);
		box.style.left = left + 'px';
		box.style.top = top + 'px';
		return true;
	}

	document.addEventListener('click', function (e) {
		var ref = e.target.closest && e.target.closest('a[data-footnote-ref]');
		if (!ref) return;
		if (open(ref)) e.preventDefault();
	});
})();
