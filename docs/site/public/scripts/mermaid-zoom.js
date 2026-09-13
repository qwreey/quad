// [2026-09-13 코디네이터 지시] mermaid 다이어그램 클릭 확대.
// astro-mermaid는 클라이언트에서 `<pre class="mermaid">`를 `<pre class="mermaid" data-processed><svg>...</svg></pre>`로
// 바꿔치기한다(astro-mermaid-integration.js 493·638·667행 근처가 그 패턴의 소스) — starlight-image-zoom은 빌드 타임
// rehype 변환이라 이 svg를 못 잡으므로(대상은 markdown의 img/picture뿐) 이 svg 전용으로 별도 라이트박스를 만든다.
// Starlight의 `head` 설정(astro.config.mjs)이 이 파일을 모든 페이지에 <script defer>로 싣는다.
(function () {
	'use strict';

	function findSvg(target) {
		var pre = target.closest('pre.mermaid[data-processed]');
		if (!pre) return null;
		return pre.querySelector('svg');
	}

	function openZoom(svg) {
		var dialog = document.createElement('dialog');
		dialog.className = 'mermaid-zoom-dialog';

		var closeBtn = document.createElement('button');
		closeBtn.type = 'button';
		closeBtn.className = 'mermaid-zoom-close';
		closeBtn.setAttribute('aria-label', '닫기');
		closeBtn.textContent = '×';

		var hint = document.createElement('p');
		hint.className = 'mermaid-zoom-hint';
		hint.textContent = '휠/핀치로 확대, 드래그로 이동 — Esc나 배경 클릭으로 닫기';

		var wrap = document.createElement('div');
		wrap.className = 'mermaid-zoom-wrap';

		var clone = svg.cloneNode(true);
		clone.removeAttribute('id');
		clone.style.maxWidth = 'none';
		clone.style.maxHeight = 'none';
		wrap.appendChild(clone);

		dialog.appendChild(closeBtn);
		dialog.appendChild(wrap);
		dialog.appendChild(hint);
		document.body.appendChild(dialog);

		var scale = 1, tx = 0, ty = 0, dragging = false, startX = 0, startY = 0;
		function apply() {
			clone.style.transform = 'translate(' + tx + 'px, ' + ty + 'px) scale(' + scale + ')';
		}
		function clampScale(s) {
			return Math.min(8, Math.max(0.5, s));
		}
		// 처음 열 때 svg 자체 크기 기준으로 살짝 확대 — 원본이 페이지 폭 절반짜리 작은 그림이라 열자마자
		// 눈에 띄는 확대가 되도록(사용자 원 불만: "작아서 트랙패드로 확대해서 봐야 했음").
		scale = 1.4;
		apply();

		wrap.addEventListener('wheel', function (ev) {
			ev.preventDefault();
			var delta = -ev.deltaY * 0.0015;
			scale = clampScale(scale + delta * scale);
			apply();
		}, { passive: false });

		wrap.addEventListener('pointerdown', function (ev) {
			dragging = true;
			startX = ev.clientX - tx;
			startY = ev.clientY - ty;
			wrap.setPointerCapture(ev.pointerId);
			wrap.classList.add('dragging');
		});
		wrap.addEventListener('pointermove', function (ev) {
			if (!dragging) return;
			tx = ev.clientX - startX;
			ty = ev.clientY - startY;
			apply();
		});
		function endDrag() {
			dragging = false;
			wrap.classList.remove('dragging');
		}
		wrap.addEventListener('pointerup', endDrag);
		wrap.addEventListener('pointercancel', endDrag);

		// 트랙패드 핀치는 대부분 브라우저에서 wheel + ctrlKey로 온다(위 wheel 핸들러가 이미 처리) —
		// 별도 gesture 이벤트는 Safari 전용이라 생략(사용자 언급이 트랙패드 확대였지만 wheel 경로로 커버됨).

		closeBtn.addEventListener('click', function () { dialog.close(); });
		dialog.addEventListener('click', function (ev) {
			if (ev.target === dialog) dialog.close();
		});
		dialog.addEventListener('close', function () { dialog.remove(); });

		dialog.showModal();
	}

	document.addEventListener('click', function (ev) {
		var svg = findSvg(ev.target);
		if (!svg) return;
		ev.preventDefault();
		openZoom(svg);
	});
})();
