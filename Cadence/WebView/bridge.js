(function () {
    'use strict';

    if (window.__cadenceBridgeInstalled) {
        return;
    }
    window.__cadenceBridgeInstalled = true;

    const native = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.cadence;

    const post = (msg) => {
        try {
            if (native) native.postMessage(msg);
        } catch (e) {
            console.warn('[Cadence] postMessage failed', e);
        }
    };

    // -------- video element handling --------
    let video = null;
    let lastEmit = 0;

    const findVideo = () => document.querySelector('video');

    const emitState = (force) => {
        if (!video) return;
        const now = Date.now();
        if (!force && now - lastEmit < 1000) return;
        lastEmit = now;

        const meta = navigator.mediaSession && navigator.mediaSession.metadata;
        const artworkList = meta && meta.artwork ? meta.artwork : [];
        const artwork = artworkList.length ? artworkList[artworkList.length - 1].src : '';

        post({
            type: 'state',
            isPlaying: !video.paused && !video.ended && video.readyState > 2,
            elapsed: Number(video.currentTime) || 0,
            duration: isFinite(video.duration) ? Number(video.duration) : 0,
            title: meta ? (meta.title || '') : '',
            artist: meta ? (meta.artist || '') : '',
            album: meta ? (meta.album || '') : '',
            artwork: artwork,
        });
    };

    const attachVideo = (v) => {
        if (!v || v === video) return;
        video = v;
        video.addEventListener('play', () => emitState(true));
        video.addEventListener('pause', () => emitState(true));
        video.addEventListener('ended', () => emitState(true));
        video.addEventListener('seeked', () => emitState(true));
        video.addEventListener('loadedmetadata', () => emitState(true));
        video.addEventListener('timeupdate', () => emitState(false));
        emitState(true);
    };

    const tryAttachVideo = () => {
        const v = findVideo();
        if (v) {
            attachVideo(v);
        }
    };

    const videoObserver = new MutationObserver(tryAttachVideo);
    videoObserver.observe(document.documentElement, { childList: true, subtree: true });
    tryAttachVideo();

    // -------- mediaSession metadata polling --------
    // YT Music updates navigator.mediaSession.metadata when the track changes.
    // We poll for changes once per second and re-emit on change.
    let lastMetaSig = '';
    setInterval(() => {
        if (!video) return;
        const m = navigator.mediaSession && navigator.mediaSession.metadata;
        if (!m) return;
        const art = m.artwork && m.artwork.length ? m.artwork[m.artwork.length - 1].src : '';
        const sig = (m.title || '') + '|' + (m.artist || '') + '|' + (m.album || '') + '|' + art;
        if (sig !== lastMetaSig) {
            lastMetaSig = sig;
            emitState(true);
        }
    }, 1000);

    // -------- native -> page commands --------
    // Multilingual aria-label fragments. Keep entries lowercase.
    const LABEL_FRAGMENTS = {
        next: ['next song', 'next track', 'next video', 'next', 'volgende nummer', 'volgende track', 'volgende'],
        previous: ['previous song', 'previous track', 'previous video', 'previous', 'vorige nummer', 'vorige track', 'vorige'],
    };

    // Known YT Music class names on the player-bar buttons.
    const CLASS_HINTS = {
        next: ['next-button', 'ytmusic-next-button'],
        previous: ['previous-button', 'ytmusic-previous-button'],
    };

    const findPlayerBar = () => document.querySelector('ytmusic-player-bar');

    const findPlayerControl = (kind) => {
        const bar = findPlayerBar();
        if (!bar) {
            console.warn('[Cadence] ytmusic-player-bar not found yet');
            return null;
        }

        // Strategy 1: class-name hints (most stable across YT Music updates)
        for (const cls of CLASS_HINTS[kind] || []) {
            const byClass = bar.querySelector('.' + cls);
            if (byClass) return byClass;
        }

        // Strategy 2: aria-label / title containing any locale fragment
        const fragments = LABEL_FRAGMENTS[kind] || [kind];
        const candidates = bar.querySelectorAll('button, [role="button"], tp-yt-paper-icon-button, yt-button-shape');
        for (const el of candidates) {
            const aria = (el.getAttribute('aria-label') || '').toLowerCase();
            const title = (el.getAttribute('title') || '').toLowerCase();
            for (const frag of fragments) {
                if (aria.includes(frag) || title.includes(frag)) return el;
            }
        }
        return null;
    };

    const triggerPlayerControl = (kind) => {
        const el = findPlayerControl(kind);
        if (!el) {
            console.warn('[Cadence] no element found for', kind);
            return false;
        }
        console.log('[Cadence] clicking', kind, 'on', el.tagName, el.getAttribute('aria-label') || el.className);
        // A plain .click() works on YT Music's tp-yt-paper-icon-button. Fall back
        // to a synthesized mouse event sequence if needed.
        try {
            el.click();
        } catch (e) {
            console.warn('[Cadence] .click() threw, falling back to mouse events', e);
            const opts = { bubbles: true, cancelable: true, view: window };
            el.dispatchEvent(new MouseEvent('mousedown', opts));
            el.dispatchEvent(new MouseEvent('mouseup', opts));
            el.dispatchEvent(new MouseEvent('click', opts));
        }
        return true;
    };

    window.cadenceBridge = {
        play() {
            if (video && video.paused) {
                const p = video.play();
                if (p && typeof p.catch === 'function') p.catch(() => {});
            }
        },
        pause() {
            if (video && !video.paused) {
                video.pause();
            }
        },
        togglePlayPause() {
            if (!video) return;
            if (video.paused) {
                const p = video.play();
                if (p && typeof p.catch === 'function') p.catch(() => {});
            } else {
                video.pause();
            }
        },
        next() {
            triggerPlayerControl('next');
        },
        previous() {
            triggerPlayerControl('previous');
        },
        seekTo(seconds) {
            if (video && isFinite(seconds)) {
                video.currentTime = seconds;
            }
        },
        // Debug helper: returns labels of all player-bar buttons so we can see
        // exactly what YT Music is rendering on this machine.
        _debugButtons() {
            const bar = findPlayerBar();
            if (!bar) return 'no player bar';
            const out = [];
            for (const el of bar.querySelectorAll('button, [role="button"], tp-yt-paper-icon-button, yt-button-shape')) {
                out.push({
                    tag: el.tagName.toLowerCase(),
                    cls: el.className,
                    aria: el.getAttribute('aria-label') || '',
                    title: el.getAttribute('title') || '',
                });
            }
            return out;
        },
    };

    post({ type: 'ready' });
})();
