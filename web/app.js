const $ = (s) => document.querySelector(s);
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'arca_interface';
const post = (name, data = {}) => fetch(`https://${resource}/${name}`, { method: 'POST', body: JSON.stringify(data) }).then((r) => r.json()).catch(() => null);
const sound = (name) => post('sound', { name });

let data = null;      // payload from the client
let page = 'home';    // 'home' | settings category id | 'keybinds' | 'game'
let focus = 0;        // focused row / button on the current page
let pending = {};     // unsaved settings changes: { key: value }
let modalOpen = false;

/* ---------- helpers ---------- */
function tabs() {
    const list = [{ id: 'home', label: 'Home', icon: 'fa-solid fa-house' }];
    data.settings.forEach((c) => list.push({ id: c.id, label: c.label, icon: c.icon || 'fa-solid fa-sliders' }));
    list.push({ id: 'keybinds', label: 'Keybinds', icon: 'fa-solid fa-keyboard' });
    list.push({ id: 'game', label: 'GTA Settings', icon: 'fa-solid fa-gear' });
    return list;
}
const category = () => data.settings.find((c) => c.id === page);
const allRows = () => data.settings.flatMap((c) => c.settings);
const rowByKey = (key) => allRows().find((r) => r.key === key);
const current = (row) => (row.key in pending ? pending[row.key] : row.value);
const saved = (key) => rowByKey(key)?.value;
const live = (key) => { const r = rowByKey(key); return r ? current(r) : undefined; };

function choices(row) {
    if (row.type === 'toggle') return [{ value: false, label: 'Off' }, { value: true, label: 'On' }];
    if (row.type === 'select') return row.options;
    return null;
}
function display(row, value) {
    if (row.type === 'slider') return `${value}${row.suffix || ''}`;
    return (choices(row).find((o) => o.value === value) || {}).label ?? String(value);
}

function setPending(row, value) {
    if (value === row.value) delete pending[row.key];
    else pending[row.key] = value;
}

function change(row, dir) {
    if (row.gta) return; // GTA's own settings are read-only from scripts
    const v = current(row);
    if (row.type === 'slider') {
        const step = row.step || 1;
        const next = Math.min(row.max, Math.max(row.min, Math.round((v + dir * step) / step) * step));
        if (next === v) return;
        setPending(row, next);
    } else {
        const opts = choices(row);
        const i = opts.findIndex((o) => o.value === v);
        const next = Math.min(opts.length - 1, Math.max(0, i + dir));
        if (next === i) return;
        setPending(row, opts[next].value);
    }
    sound('change');
    render();
}

/* ---------- rendering ---------- */
function renderTabs() {
    const list = tabs();
    $('#tabs').innerHTML =
        `<span class="tab-hint"><kbd>Q</kbd></span>` +
        list.map((t) => `<button class="tab${t.id === page ? ' active' : ''}" data-tab="${esc(t.id)}"><i class="${esc(t.icon)}"></i><span class="t-label">${esc(t.label)}</span></button>`).join('') +
        `<span class="tab-hint"><kbd>E</kbd></span>`;
}

function renderHome() {
    const p = data.player || {};
    const streamer = live('streamerMode');
    const buttons = homeButtons();
    const money = (n) => (typeof n === 'number' ? `$${n.toLocaleString('en-US')}` : '-');
    $('#page').innerHTML =
        `<div class="home-list">` +
            buttons.map((b, i) => b.sep ? `<div class="home-sep"></div>` :
                `<button class="home-btn ${b.cls || ''}${i === focus ? ' focus' : ''}" data-home="${i}"><i class="${b.icon}"></i>${esc(b.label)}</button>`).join('') +
        `</div>` +
        `<div class="card">` +
            `<h2>${streamer ? 'Hidden' : esc(p.name || 'Unknown')}</h2>` +
            `<div class="sub">${esc(p.job || 'Unemployed')}</div>` +
            `<div class="stats">` +
                `<div class="stat"><span>Server ID</span><b>${streamer ? '•••' : esc(p.id)}</b></div>` +
                `<div class="stat"><span>Citizen ID</span><b>${streamer ? '•••' : esc(p.citizenid || '-')}</b></div>` +
                `<div class="stat"><span>Cash</span><b>${money(p.cash)}</b></div>` +
                `<div class="stat"><span>Bank</span><b>${money(p.bank)}</b></div>` +
            `</div>` +
            (data.links.discord || data.links.website
                ? `<div class="links">` +
                    (data.links.discord ? `<a href="${esc(data.links.discord)}" target="_blank"><i class="fa-brands fa-discord"></i> Discord</a>` : '') +
                    (data.links.website ? `<a href="${esc(data.links.website)}" target="_blank"><i class="fa-solid fa-globe"></i> Website</a>` : '') +
                  `</div>`
                : '') +
        `</div>`;
}

function homeButtons() {
    const list = [
        { label: 'Resume', icon: 'fa-solid fa-play', cls: 'primary', run: close },
        { label: 'Map', icon: 'fa-solid fa-map-location-dot', run: () => post('map') },
        { label: 'Settings', icon: 'fa-solid fa-sliders', run: () => go(data.settings[0]?.id || 'keybinds') },
        { label: 'Keybinds', icon: 'fa-solid fa-keyboard', run: () => go('keybinds') },
        { label: 'GTA Settings', icon: 'fa-solid fa-gear', run: () => go('game') },
    ];
    if (data.hud) list.push({ label: 'HUD Settings', icon: 'fa-solid fa-gauge-high', run: () => post('hud') });
    list.push({ sep: true });
    list.push({ label: 'Switch Character', icon: 'fa-solid fa-users', run: () => confirmBox('Switch character?', 'Your current character is saved and you\'ll go back to character selection.', 'Switch', () => post('switchCharacter')) });
    list.push({ label: 'Disconnect', icon: 'fa-solid fa-plug-circle-xmark', cls: 'danger', run: () => confirmBox('Disconnect?', 'You\'ll leave the server. Your character is saved.', 'Disconnect', () => post('disconnect')) });
    list.push({ label: 'Quit Game', icon: 'fa-solid fa-power-off', cls: 'danger', run: () => confirmBox('Quit to desktop?', 'This closes FiveM completely.', 'Quit', () => post('quit')) });
    return list;
}

function renderSettings() {
    const cat = category();
    const rows = cat.settings;
    focus = Math.min(focus, rows.length - 1);
    const row = rows[focus];

    $('#page').innerHTML =
        `<div class="list">` +
            `<div class="section">${esc(cat.label)}</div>` +
            rows.map((r, i) => {
                const v = current(r);
                let ctrl;
                if (r.gta && r.type === 'slider') {
                    const pct = ((v - r.min) / (r.max - r.min)) * 100;
                    ctrl = `<div class="slider ro"><div class="fill" style="width:${pct}%"></div><div class="num">${esc(display(r, v))} <i class="fa-solid fa-lock"></i></div></div>`;
                } else if (r.gta) {
                    ctrl = `<div class="picker ro"><div class="val">${esc(display(r, v))} <i class="fa-solid fa-lock"></i></div></div>`;
                } else if (r.type === 'slider') {
                    const pct = ((v - r.min) / (r.max - r.min)) * 100;
                    ctrl = `<div class="slider" data-slider="${i}"><div class="fill" style="width:${pct}%"></div><div class="num">${esc(display(r, v))}</div></div>`;
                } else {
                    const opts = choices(r);
                    const idx = opts.findIndex((o) => o.value === v);
                    ctrl = `<div class="picker">` +
                        `<button class="arrow" data-dir="-1" data-row="${i}" ${idx <= 0 ? 'disabled' : ''}><i class="fa-solid fa-chevron-left"></i></button>` +
                        `<div class="val">${esc(display(r, v))}</div>` +
                        `<button class="arrow" data-dir="1" data-row="${i}" ${idx >= opts.length - 1 ? 'disabled' : ''}><i class="fa-solid fa-chevron-right"></i></button>` +
                        `<div class="segs">${opts.map((_, j) => `<i class="${j === idx ? 'on' : ''}"></i>`).join('')}</div>` +
                    `</div>`;
                }
                return `<div class="row${i === focus ? ' focus' : ''}${r.key in pending ? ' changed' : ''}" data-focus="${i}"><span class="r-label">${esc(r.label)}</span>${ctrl}</div>`;
            }).join('') +
        `</div>` +
        `<div class="info">` +
            (row ? `<h3>${esc(row.label)}</h3>` +
                (row.description ? `<p>${esc(row.description)}</p>` : '') +
                (choices(row)
                    ? `<div class="opts">${choices(row).map((o) => `<div class="opt${o.value === current(row) ? ' on' : ''}">${esc(o.label)}</div>`).join('')}</div>`
                    : `<div class="default">Range ${esc(display(row, row.min))} – ${esc(display(row, row.max))}</div>`) +
                `<div class="default">Default: ${esc(display(row, row.default))}</div>` +
                (row.gta ? `<p>This is one of GTA's own settings, so it's changed in GTA's settings menu. It updates here when you come back.</p>` +
                    `<button class="cta" data-native="1"><i class="fa-solid fa-up-right-from-square"></i>Change in GTA Settings</button>` : '')
            : '') +
        `</div>`;
}

function renderKeybinds() {
    const groups = {};
    data.keybinds.forEach((k) => (groups[k.category] = groups[k.category] || []).push(k));
    $('#page').innerHTML =
        `<div class="list">` +
            Object.entries(groups).map(([name, list]) =>
                `<div class="section">${esc(name)}</div>` +
                `<div>${list.map((k) => `<div class="kb"><span>${esc(k.label)}</span><span class="key${k.key ? '' : ' none'}">${esc(k.key || 'Unbound')}</span></div>`).join('')}</div>`
            ).join('') +
        `</div>` +
        `<div class="info">` +
            `<h3>Changing a key</h3>` +
            `<p>Keys are set in GTA's own settings, so they're saved with your game and stay set next time you join.</p>` +
            `<p>Open GTA Settings, go to <b>Key Bindings</b>, then <b>FiveM</b>, and pick the action you want to change. The new key shows up here straight away.</p>` +
            `<button class="cta" data-native="1"><i class="fa-solid fa-keyboard"></i>Open GTA Key Bindings</button>` +
        `</div>`;
}

const GAME_CARDS = [
    { icon: 'fa-solid fa-desktop', title: 'Graphics', text: 'Resolution, window mode, VSync, texture, shadow and other quality settings.' },
    { icon: 'fa-solid fa-keyboard', title: 'Key Bindings', text: 'Rebind GTA keys, and every Arca action under the FiveM section.' },
    { icon: 'fa-solid fa-sliders', title: 'Sensitivity', text: 'Mouse and controller sensitivity, deadzones and acceleration.' },
    { icon: 'fa-solid fa-headset', title: 'Audio Output', text: 'Speaker setup, output device and in-game voice chat devices.' },
];

function renderGame() {
    focus = Math.min(focus, GAME_CARDS.length - 1);
    $('#page').innerHTML =
        `<div class="list"><div class="section">GTA Settings</div>` +
            `<div class="cards">${GAME_CARDS.map((c, i) => `<button class="g-card${i === focus ? ' focus' : ''}" data-native="1" data-focus="${i}"><i class="${c.icon}"></i><h4>${esc(c.title)}</h4><p>${esc(c.text)}</p></button>`).join('')}</div>` +
        `</div>` +
        `<div class="info">` +
            `<h3>Game settings</h3>` +
            `<p>The Display, Audio, Camera and Controls tabs show your current GTA settings. To change them, or anything below, open GTA's settings menu; this menu comes back when you close it. Picking one opens GTA's settings menu; this menu comes back when you close it.</p>` +
            `<button class="cta" data-native="1"><i class="fa-solid fa-up-right-from-square"></i>Open GTA Settings</button>` +
        `</div>`;
}

function renderFooter() {
    let html = '';
    if (page === 'home') {
        html = `<button class="fbtn" data-foot="close"><kbd>ESC</kbd>Resume</button>`;
    } else if (category()) {
        const dirty = Object.keys(pending).length > 0;
        html = `<button class="fbtn accent" data-foot="apply" ${dirty ? '' : 'disabled'}><kbd>&#9166;</kbd>Apply</button>` +
            `<button class="fbtn" data-foot="restore"><kbd>R</kbd>Restore to Default</button>` +
            `<button class="fbtn" data-foot="back"><kbd>ESC</kbd>Back</button>`;
    } else {
        html = `<button class="fbtn" data-foot="back"><kbd>ESC</kbd>Back</button>`;
    }
    $('#footer').innerHTML = html;
}

function render() {
    $('#scale').style.transform = `scale(${(live('uiScale') || 100) / 100})`;
    renderTabs();
    if (page === 'home') renderHome();
    else if (page === 'keybinds') renderKeybinds();
    else if (page === 'game') renderGame();
    else renderSettings();
    renderFooter();
    tickClock();
}

/* ---------- navigation ---------- */
function go(id, force) {
    if (id === page) return;
    if (!force && Object.keys(pending).length) {
        return confirmBox('Unsaved changes', 'Apply your changes before leaving this page?', 'Apply',
            () => apply().then(() => go(id, true)),
            { label: 'Discard', run: () => { pending = {}; go(id, true); } });
    }
    page = id;
    focus = 0;
    sound('move');
    render();
}

function switchTab(dir) {
    const list = tabs();
    const i = list.findIndex((t) => t.id === page);
    go(list[(i + dir + list.length) % list.length].id);
}

function back() {
    if (page === 'home') return close();
    go('home');
}

async function apply() {
    if (!Object.keys(pending).length) return;
    const res = await post('apply', { values: pending });
    if (res && res.settings) data.settings = res.settings;
    pending = {};
    render();
    if (res && res.failed && res.failed.length) {
        const names = res.failed.map((k) => rowByKey(k)?.label || k).join(', ');
        confirmBox('Some settings didn\'t change', `GTA didn't accept: ${names}. You can change them in GTA's own settings instead.`, 'Open GTA Settings', () => post('gameSettings'));
    }
}

function restore() {
    const cat = category();
    if (!cat) return;
    cat.settings.forEach((r) => { if (!r.gta) setPending(r, r.default); });
    sound('change');
    render();
}

function close() {
    if (Object.keys(pending).length) {
        return confirmBox('Unsaved changes', 'Apply your changes before closing?', 'Apply',
            () => apply().then(() => { pending = {}; post('close'); }),
            { label: 'Discard', run: () => { pending = {}; post('close'); } });
    }
    post('close');
}

function rowsOnPage() {
    if (page === 'home') return homeButtons().length;
    if (page === 'game') return GAME_CARDS.length;
    return category()?.settings.length || 0;
}

function moveFocus(dir) {
    const n = rowsOnPage();
    if (!n) return;
    let next = focus;
    do { next = (next + dir + n) % n; } while (page === 'home' && homeButtons()[next].sep);
    focus = next;
    sound('move');
    render();
}

function activate() {
    if (page === 'home') return homeButtons()[focus]?.run();
    if (page === 'game') return post('gameSettings');
    if (category()?.settings[focus]?.gta) return post('gameSettings');
    if (category()) return apply();
}

/* ---------- confirm modal ---------- */
function confirmBox(title, text, okLabel, onOk, extra) {
    modalOpen = true;
    $('#m-title').textContent = title;
    $('#m-text').textContent = text;
    const danger = okLabel === 'Disconnect' || okLabel === 'Quit';
    $('#m-actions').innerHTML =
        `<button data-m="cancel">Cancel</button>` +
        (extra ? `<button data-m="extra">${esc(extra.label)}</button>` : '') +
        `<button class="${danger ? 'bad' : 'go'}" data-m="ok">${esc(okLabel)}</button>`;
    $('#modal').classList.remove('hidden');
    $('#m-actions').onclick = (e) => {
        const b = e.target.closest('[data-m]');
        if (!b) return;
        hideModal();
        if (b.dataset.m === 'ok') onOk();
        if (b.dataset.m === 'extra') extra.run();
    };
}
function hideModal() { modalOpen = false; $('#modal').classList.add('hidden'); }

/* ---------- input ---------- */
document.addEventListener('click', (e) => {
    if (modalOpen) return;
    const tab = e.target.closest('[data-tab]');
    if (tab) return go(tab.dataset.tab);

    const home = e.target.closest('[data-home]');
    if (home) { focus = Number(home.dataset.home); sound('select'); return homeButtons()[focus].run(); }

    const arrow = e.target.closest('[data-dir]');
    if (arrow) { focus = Number(arrow.dataset.row); return change(category().settings[focus], Number(arrow.dataset.dir)); }

    if (e.target.closest('[data-native]')) { sound('select'); return post('gameSettings'); }

    const foot = e.target.closest('[data-foot]');
    if (foot) {
        const act = foot.dataset.foot;
        if (act === 'close') return close();
        if (act === 'apply') return apply();
        if (act === 'restore') return restore();
        if (act === 'back') return back();
    }

    const row = e.target.closest('[data-focus]');
    if (row && Number(row.dataset.focus) !== focus) { focus = Number(row.dataset.focus); render(); }
});

// click / drag on a slider bar sets the value
document.addEventListener('mousedown', (e) => {
    const bar = e.target.closest('[data-slider]');
    if (!bar || modalOpen) return;
    const row = category().settings[Number(bar.dataset.slider)];
    focus = Number(bar.dataset.slider);
    const r = bar.getBoundingClientRect(); // the bar is re-rendered on every change, but in the same place
    const setFrom = (x) => {
        const t = Math.min(1, Math.max(0, (x - r.left) / r.width));
        const step = row.step || 1;
        setPending(row, Math.round((row.min + t * (row.max - row.min)) / step) * step);
        render();
    };
    setFrom(e.clientX);
    const move = (ev) => setFrom(ev.clientX);
    const up = () => { window.removeEventListener('mousemove', move); window.removeEventListener('mouseup', up); };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
});

window.addEventListener('keydown', (e) => {
    if ($('#menu').classList.contains('hidden')) return;
    if (modalOpen) { if (e.key === 'Escape') hideModal(); return; }
    const k = e.key.toLowerCase();
    if (k === 'escape') { e.preventDefault(); return back(); }
    if (k === 'q') return switchTab(-1);
    if (k === 'e') return switchTab(1);
    if (k === 'arrowup' || k === 'w') { e.preventDefault(); return moveFocus(-1); }
    if (k === 'arrowdown' || k === 's') { e.preventDefault(); return moveFocus(1); }
    if (k === 'enter' || k === ' ') { e.preventDefault(); return activate(); }
    if (category()) {
        const row = category().settings[focus];
        if (k === 'arrowleft' || k === 'a') return row && change(row, -1);
        if (k === 'arrowright' || k === 'd') return row && change(row, 1);
        if (k === 'r') return restore();
    }
});

/* ---------- clock ---------- */
function tickClock() {
    const d = new Date();
    const h24 = live('clock') !== '12h';
    $('#clock').textContent = d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: !h24 });
}
setInterval(() => { if (data) tickClock(); }, 10000);

/* ---------- messages ---------- */
window.addEventListener('message', ({ data: msg }) => {
    if (msg.action === 'open') {
        data = msg.data;
        pending = {};
        page = msg.data.page && (msg.data.page === 'game' || msg.data.page === 'keybinds') ? msg.data.page : 'home';
        focus = 0;
        hideModal();
        $('#server-name').textContent = data.server.name || 'Arca';
        $('#server-players').innerHTML = data.server.players != null
            ? `<i class="fa-solid fa-user-group"></i>${esc(data.server.players)} / ${esc(data.server.maxPlayers)} online` : '';
        $('#menu').classList.remove('hidden');
        render();
    } else if (msg.action === 'close') {
        $('#menu').classList.add('hidden');
        hideModal();
    }
});

// browser preview: open web/index.html?preview
if (location.search.includes('preview')) {
    document.body.style.background = 'linear-gradient(135deg,#3a4a44,#1a2420)';
    window.postMessage({ action: 'open', data: {
        server: { name: 'Day1RP', players: 12, maxPlayers: 64 },
        links: { discord: 'https://discord.gg/example', website: '' },
        player: { id: 7, name: 'James Moretti', citizenid: 'AW8LEN9M', job: 'LSPD - Lieutenant', cash: 4753, bank: 5050 },
        hud: true,
        settings: [
            { id: 'gameplay', label: 'Gameplay', icon: 'fa-solid fa-person-running', settings: [
                { key: 'streamerMode', label: 'Streamer Mode', type: 'toggle', default: false, value: false, description: 'Hides your server ID and character name on the pause menu.' },
                { key: 'idleCamera', label: 'Idle Camera', type: 'toggle', default: false, value: false, description: 'GTA\'s cinematic camera when you stand still.' },
            ] },
            { id: 'interface', label: 'Interface', icon: 'fa-solid fa-display', settings: [
                { key: 'uiScale', label: 'Menu Scale', type: 'slider', default: 100, value: 100, min: 80, max: 120, step: 5, suffix: '%', description: 'Size of this pause menu.' },
                { key: 'clock', label: 'Clock Format', type: 'select', default: '24h', value: '24h', options: [{ value: '24h', label: '24 Hour' }, { value: '12h', label: '12 Hour' }], description: 'How times are shown.' },
            ] },
        ],
        keybinds: [
            { category: 'General', label: 'Open inventory', key: 'F2' },
            { category: 'General', label: 'Open phone', key: 'M' },
            { category: 'Hotbar', label: 'Hotbar slot 1', key: '1' },
            { category: 'Hotbar', label: 'Hotbar slot 2', key: null },
        ],
    } });
    const start = new URLSearchParams(location.search).get('page'); // e.g. ?preview&page=interface
    if (start) setTimeout(() => go(start), 0);
}
