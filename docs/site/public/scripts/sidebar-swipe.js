// [2026-09-14] Mobile sidebar swipe — replaces starlight-sidebar-swipe, which predates Starlight's
// popover-based mobile sidebar (0.42: <sl-sidebar-pane popover id="starlight__sidebar">) and left the
// pane hidden (blank panel). Here we only drive the native popover: edge-swipe right opens it,
// swipe left over the open pane closes it. Desktop (min-width 50em) is untouched — the pane is not a
// popover there. No dependencies; ~40 lines.
(function () {
	var EDGE = 28;      // px from the left edge where an open-swipe may start
	var MIN_DX = 48;    // horizontal travel to count as a swipe
	var MAX_DY = 40;    // vertical drift allowed
	var mobile = window.matchMedia('(max-width: 50em)');
	var start = null;

	function pane() { return document.getElementById('starlight__sidebar'); }
	function isOpen(p) { try { return p.matches(':popover-open'); } catch (e) { return false; } }

	document.addEventListener('touchstart', function (e) {
		if (!mobile.matches || e.touches.length !== 1) { start = null; return; }
		var t = e.touches[0];
		var p = pane();
		if (!p) { start = null; return; }
		var open = isOpen(p);
		// open-swipe must begin at the left edge; close-swipe may begin anywhere while open
		if (!open && t.clientX > EDGE) { start = null; return; }
		start = { x: t.clientX, y: t.clientY, open: open };
	}, { passive: true });

	document.addEventListener('touchend', function (e) {
		if (!start) return;
		var t = e.changedTouches[0];
		var dx = t.clientX - start.x, dy = Math.abs(t.clientY - start.y);
		var s = start; start = null;
		if (dy > MAX_DY) return;
		var p = pane();
		if (!p || typeof p.showPopover !== 'function') return;
		try {
			if (!s.open && dx > MIN_DX) p.showPopover();
			else if (s.open && dx < -MIN_DX) p.hidePopover();
		} catch (err) { /* popover not applicable (desktop layout) */ }
	}, { passive: true });
})();
