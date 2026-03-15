import { useState, useMemo, useRef, useCallback } from "react";

// ============ DATA ============
const INITIAL_DATA = {
  references: [
    { id: "r1", title: "基礎ステップ - ボックス", memo: "右足から開始。4拍子でカウント", mirror: false, hidden: false, createdAt: "2026-03-08" },
    { id: "r2", title: "ウェーブ - アイソレ", memo: "胸→腰の順で波を意識", mirror: true, hidden: false, createdAt: "2026-03-09" },
    { id: "r3", title: "振付A - サビ部分", memo: "", mirror: false, hidden: false, createdAt: "2026-03-10" },
  ],
  myVideos: [
    { id: "m1", label: "練習1", refId: "r1", date: "2026-03-10", hidden: false },
    { id: "m2", label: "練習2", refId: "r1", date: "2026-03-12", hidden: false },
    { id: "m3", label: "自撮り", refId: "r2", date: "2026-03-11", hidden: false },
    { id: "m4", label: "通し練習", refId: "r2", date: "2026-03-13", hidden: false },
    { id: "m5", label: "撮り直し", refId: "r1", date: "2026-03-14", hidden: false },
  ],
  lastPractice: { refId: "r1", myVideoId: "m2" },
};

const c = {
  bg: "#0f0f0f", surface: "#1a1a1a", surfaceHover: "#242424",
  border: "#2a2a2a", text: "#e8e8e8", textSub: "#777", textDim: "#555",
  accent: "#4ecdc4", accentDim: "#4ecdc418",
  red: "#ff6b6b", orange: "#f0a050",
  refBg: "#0c1929", myBg: "#0c2919",
  refAccent: "#5b9bd5", myAccent: "#6bcf7f",
  tabBg: "#141414", tabBorder: "#222",
};

// ============ SWIPE ROW ============
function SwipeRow({ children, onHide, onDelete }) {
  const rowRef = useRef(null);
  const startX = useRef(0);
  const currentX = useRef(0);
  const swiping = useRef(false);
  const [offset, setOffset] = useState(0);
  const [revealed, setRevealed] = useState(false);
  const ACTION_WIDTH = onHide ? 140 : 80;

  const handleTouchStart = useCallback((e) => { startX.current = e.touches[0].clientX; swiping.current = true; }, []);
  const handleTouchMove = useCallback((e) => {
    if (!swiping.current) return;
    const diff = e.touches[0].clientX - startX.current;
    currentX.current = diff;
    setOffset(revealed ? Math.max(0, Math.min(ACTION_WIDTH, ACTION_WIDTH + diff)) : Math.max(0, Math.min(ACTION_WIDTH, diff)));
  }, [revealed, ACTION_WIDTH]);
  const handleTouchEnd = useCallback(() => {
    swiping.current = false;
    const threshold = ACTION_WIDTH / 3;
    if (revealed) {
      if (currentX.current < -threshold) { setOffset(0); setRevealed(false); } else { setOffset(ACTION_WIDTH); }
    } else {
      if (currentX.current > threshold) { setOffset(ACTION_WIDTH); setRevealed(true); } else { setOffset(0); }
    }
    currentX.current = 0;
  }, [revealed, ACTION_WIDTH]);

  const mouseDown = useRef(false);
  const handleMouseDown = useCallback((e) => { startX.current = e.clientX; mouseDown.current = true; swiping.current = true; }, []);
  const handleMouseMove = useCallback((e) => {
    if (!mouseDown.current) return;
    currentX.current = e.clientX - startX.current;
    setOffset(revealed ? Math.max(0, Math.min(ACTION_WIDTH, ACTION_WIDTH + currentX.current)) : Math.max(0, Math.min(ACTION_WIDTH, currentX.current)));
  }, [revealed, ACTION_WIDTH]);
  const handleMouseUp = useCallback(() => { if (!mouseDown.current) return; mouseDown.current = false; handleTouchEnd(); }, [handleTouchEnd]);
  const handleMouseLeave = useCallback(() => { if (mouseDown.current) { mouseDown.current = false; handleTouchEnd(); } }, [handleTouchEnd]);

  const close = () => { setOffset(0); setRevealed(false); };

  return (
    <div style={{ position: "relative", overflow: "hidden" }}>
      <div style={{ position: "absolute", top: 0, left: 0, bottom: 0, width: ACTION_WIDTH, display: "flex", zIndex: 1 }}>
        {onHide && (
          <button onClick={() => { close(); onHide(); }} style={{
            flex: 1, border: "none", background: c.orange, color: "#000", fontSize: 12, fontWeight: 700, cursor: "pointer",
            display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2,
          }}><span style={{ fontSize: 16 }}>👁‍🗨</span>非表示</button>
        )}
        <button onClick={() => { close(); onDelete(); }} style={{
          flex: 1, border: "none", background: c.red, color: "#fff", fontSize: 12, fontWeight: 700, cursor: "pointer",
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2,
        }}><span style={{ fontSize: 16 }}>🗑</span>削除</button>
      </div>
      <div ref={rowRef}
        onTouchStart={handleTouchStart} onTouchMove={handleTouchMove} onTouchEnd={handleTouchEnd}
        onMouseDown={handleMouseDown} onMouseMove={handleMouseMove} onMouseUp={handleMouseUp} onMouseLeave={handleMouseLeave}
        style={{ position: "relative", zIndex: 2, background: c.bg, transform: `translateX(${offset}px)`,
          transition: swiping.current ? "none" : "transform 0.25s ease", userSelect: "none" }}>
        {children}
      </div>
    </div>
  );
}

// ============ TAB BAR (4 tabs) ============
function TabBar({ active, onChange }) {
  const tabs = [
    { id: "compare", icon: "⏯", label: "比較" },
    { id: "references", icon: "🎬", label: "見本動画" },
    { id: "myvideos", icon: "📹", label: "自分の動画" },
    { id: "settings", icon: "⚙", label: "設定" },
  ];
  return (
    <div style={st.tabBar}>
      {tabs.map(t => (
        <button key={t.id} onClick={() => onChange(t.id)}
          style={{ ...st.tab, ...(active === t.id ? st.tabActive : {}) }}>
          <span style={{ fontSize: 17 }}>{t.icon}</span>
          <span style={{ fontSize: 9, marginTop: 2, fontWeight: active === t.id ? 700 : 400 }}>{t.label}</span>
        </button>
      ))}
    </div>
  );
}

// ============ COMPARE / PLAYER TAB (unified) ============
function CompareTab({ data, setData, navigateTo, initMode, initRefId, initMyId }) {
  const [mode, setMode] = useState(initMode || "compare");
  const [refId, setRefId] = useState(initRefId || data.lastPractice?.refId || data.references.find(r => !r.hidden)?.id);
  const [myVideoId, setMyVideoId] = useState(initMyId || data.lastPractice?.myVideoId || null);
  const [bothPlaying, setBothPlaying] = useState(false);
  const [refPlaying, setRefPlaying] = useState(false);
  const [myPlaying, setMyPlaying] = useState(false);
  const [soloPlaying, setSoloPlaying] = useState(false);
  const [refSpeed, setRefSpeed] = useState(1);
  const [mySpeed, setMySpeed] = useState(1);
  const [soloSpeed, setSoloSpeed] = useState(1);
  const [syncOffset, setSyncOffset] = useState(0);
  const [showSyncPanel, setShowSyncPanel] = useState(false);
  const [showRefPicker, setShowRefPicker] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  // Solo mode list
  const [soloViewMode, setSoloViewMode] = useState("ref");
  const [soloCollapsed, setSoloCollapsed] = useState({});
  const [soloAddRefId, setSoloAddRefId] = useState(null);

  const visibleRefs = data.references.filter(r => !r.hidden);
  const ref = visibleRefs.find(r => r.id === refId) || visibleRefs[0];
  const myVidsForRef = data.myVideos.filter(v => v.refId === (ref?.id) && !v.hidden);
  const myVid = data.myVideos.find(v => v.id === myVideoId);
  const visibleMyVideos = data.myVideos.filter(v => !v.hidden);

  const speeds = [0.25, 0.5, 0.75, 1];
  const cycleSpeed = (cur) => speeds[(speeds.indexOf(cur) + 1) % speeds.length];

  const playBoth = () => { const n = !bothPlaying; setBothPlaying(n); setRefPlaying(n); setMyPlaying(n); };

  const selectRef = (id) => {
    setRefId(id);
    const vids = data.myVideos.filter(v => v.refId === id && !v.hidden);
    setMyVideoId(vids[0]?.id || null);
    setShowRefPicker(false); setSyncOffset(0);
  };

  const addMyVideo = (type) => {
    const targetRefId = mode === "solo" ? (soloAddRefId || myVid?.refId || ref?.id) : ref?.id;
    if (!targetRefId) return;
    const nv = {
      id: `m${Date.now()}`,
      label: type === "record" ? `${new Date().toLocaleDateString("ja")} 撮影` : `${new Date().toLocaleDateString("ja")} 選択`,
      refId: targetRefId, date: new Date().toISOString().slice(0, 10), hidden: false,
    };
    setData(d => ({ ...d, myVideos: [...d.myVideos, nv] }));
    setMyVideoId(nv.id);
    setSoloPlaying(false);
    setShowAddModal(false);
  };

  const toggleSoloCollapse = (key) => setSoloCollapsed(prev => ({ ...prev, [key]: !prev[key] }));

  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  const formatDate = (d) => { if (d === today) return "今日"; if (d === yesterday) return "昨日"; return d.replace(/^\d{4}-/, "").replace("-", "/"); };
  const getRefTitle = (rid) => data.references.find(r => r.id === rid)?.title || "不明";

  const soloGroupedByRef = useMemo(() => {
    const groups = {};
    data.references.filter(r => !r.hidden).forEach(r => {
      const vids = visibleMyVideos.filter(v => v.refId === r.id).sort((a, b) => b.date.localeCompare(a.date));
      if (vids.length > 0) groups[r.id] = { title: r.title, videos: vids };
    });
    return groups;
  }, [visibleMyVideos, data.references]);

  const soloGroupedByDate = useMemo(() => {
    const groups = {};
    [...visibleMyVideos].sort((a, b) => b.date.localeCompare(a.date)).forEach(v => {
      if (!groups[v.date]) groups[v.date] = [];
      groups[v.date].push(v);
    });
    return groups;
  }, [visibleMyVideos]);

  if (!ref) {
    return (
      <div style={st.emptyState}>
        <span style={{ fontSize: 40, marginBottom: 12 }}>🎬</span>
        <span>見本動画を先に追加してください</span>
        <button style={{ ...st.linkBtn, marginTop: 12 }} onClick={() => navigateTo("references")}>見本動画タブへ →</button>
      </div>
    );
  }

  const renderSoloThumbRow = (videos, groupRefId) => (
    <div style={st.thumbRow}>
      <div style={st.addThumb} onClick={() => { setSoloAddRefId(groupRefId); setShowAddModal(true); }}>
        <span style={{ fontSize: 18 }}>＋</span><span>撮影/選択</span>
      </div>
      {videos.map(mv => (
        <div key={mv.id} style={{ ...st.myThumb, borderColor: myVideoId === mv.id ? c.myAccent : "transparent" }}
          onClick={() => { setMyVideoId(mv.id); setSoloPlaying(false); }}>
          <span style={{ fontSize: 22 }}>📹</span>
          <span style={st.myThumbLabel}>{mv.label}</span>
          <span style={{ fontSize: 9, color: c.textDim }}>
            {soloViewMode === "ref" ? formatDate(mv.date) : getRefTitle(mv.refId).slice(0, 6)}
          </span>
        </div>
      ))}
    </div>
  );

  return (
    <div style={{ paddingBottom: 90 }}>
      {/* Header with mode toggle */}
      <div style={st.pageHeader}>
        <span style={{ fontSize: 17, fontWeight: 700 }}>{mode === "compare" ? "比較" : "自分の動画"}</span>
        <button style={st.modeToggleBtn} onClick={() => { setMode(mode === "compare" ? "solo" : "compare"); }}>
          {mode === "compare" ? "📹 単体再生" : "⏯ 比較モード"}
        </button>
      </div>

      {/* ========= COMPARE MODE ========= */}
      {mode === "compare" && (
        <>
          <button style={st.refSelector} onClick={() => setShowRefPicker(!showRefPicker)}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, flex: 1, minWidth: 0 }}>
              <span style={{ fontSize: 16 }}>🎬</span>
              <span style={{ fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{ref.title}</span>
            </div>
            <span style={{ color: c.textSub, fontSize: 12 }}>▼ 切替</span>
          </button>
          {showRefPicker && (
            <div style={st.refPickerDropdown}>
              {visibleRefs.map(r => (
                <div key={r.id} style={{ ...st.refPickerItem, background: r.id === refId ? c.accentDim : "transparent" }}
                  onClick={() => selectRef(r.id)}>
                  <span style={{ fontWeight: 600 }}>{r.title}</span>
                  <span style={{ fontSize: 11, color: c.textSub }}>{data.myVideos.filter(v => v.refId === r.id && !v.hidden).length}本</span>
                </div>
              ))}
            </div>
          )}
          {/* Video panels */}
          <div style={st.compareArea}>
            <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
              <div style={{ ...st.videoBox, background: c.refBg }}>
                <span style={{ ...st.videoLabel, background: c.refAccent + "cc", color: "#000" }}>見本</span>
                {ref.mirror && <span style={{ ...st.videoLabel, right: 8, left: "auto", background: "#fff3", fontSize: 9 }}>🪞</span>}
                <span style={{ fontSize: 30, marginBottom: 4 }}>🎬</span>
                <span style={{ fontSize: 10, padding: "0 8px", textAlign: "center", lineHeight: 1.4 }}>{ref.title}</span>
                {refPlaying && <div style={{ ...st.playingDot, background: c.refAccent }}>▶</div>}
              </div>
              <div style={st.miniControls}>
                <button style={st.miniBtn} onClick={() => { setRefPlaying(!refPlaying); if(bothPlaying) setBothPlaying(false); }}>{refPlaying ? "⏸" : "▶"}</button>
                <button style={{ ...st.speedBadge, color: c.refAccent, borderColor: c.refAccent + "44" }}
                  onClick={() => setRefSpeed(cycleSpeed(refSpeed))}>{refSpeed}x</button>
              </div>
            </div>
            <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
              <div style={{ ...st.videoBox, background: myVideoId ? c.myBg : c.surface }}>
                <span style={{ ...st.videoLabel, background: c.myAccent + "cc", color: "#000" }}>自分</span>
                {myVideoId ? (
                  <><span style={{ fontSize: 30, marginBottom: 4 }}>📹</span><span style={{ fontSize: 10 }}>{myVid?.label}</span>
                  {myPlaying && <div style={{ ...st.playingDot, background: c.myAccent }}>▶</div>}</>
                ) : (<span style={{ fontSize: 11 }}>↓ から選択</span>)}
              </div>
              <div style={st.miniControls}>
                <button style={{ ...st.miniBtn, opacity: myVideoId ? 1 : 0.3 }}
                  onClick={() => { if(!myVideoId) return; setMyPlaying(!myPlaying); if(bothPlaying) setBothPlaying(false); }}>{myPlaying ? "⏸" : "▶"}</button>
                <button style={{ ...st.speedBadge, color: c.myAccent, borderColor: c.myAccent + "44" }}
                  onClick={() => setMySpeed(cycleSpeed(mySpeed))}>{mySpeed}x</button>
              </div>
            </div>
          </div>
          <div style={st.timeline}><div style={st.timelineProgress} /></div>
          <div style={st.timelineTime}><span>0:12</span><span>0:34</span></div>
          <div style={st.controls}>
            <button style={st.ctrlBtn} onClick={() => {}}>↩</button>
            <button style={st.playBtnMain} onClick={playBoth}>{bothPlaying ? "⏸" : "▶▶"}</button>
            <button style={st.ctrlBtn} onClick={() => {}}>↪</button>
          </div>
          <div style={{ textAlign: "center", fontSize: 10, color: c.textDim, marginTop: -2, marginBottom: 2 }}>同時再生 / 5秒送り戻し</div>
          {/* Sync */}
          <div style={st.sectionPad}>
            <button style={st.syncToggle} onClick={() => setShowSyncPanel(!showSyncPanel)}>
              <span style={{ fontSize: 13 }}>⚙ 開始位置合わせ</span>
              <span style={{ fontSize: 12, color: c.accent, fontWeight: 700 }}>{syncOffset === 0 ? "± 0.0s" : `${syncOffset > 0 ? "+" : ""}${syncOffset.toFixed(1)}s`}</span>
            </button>
            {showSyncPanel && (
              <div style={st.syncPanel}>
                <div style={{ fontSize: 11, color: c.textSub, marginBottom: 10, lineHeight: 1.6 }}>＋ = 自分が遅れてスタート ／ − = 自分が先にスタート</div>
                <div style={st.syncRow}>
                  <button style={st.syncBtn} onClick={() => setSyncOffset(Math.round((syncOffset - 0.5) * 10) / 10)}>-0.5s</button>
                  <button style={st.syncBtn} onClick={() => setSyncOffset(Math.round((syncOffset - 0.1) * 10) / 10)}>-0.1s</button>
                  <span style={st.syncValue}>{syncOffset === 0 ? "0.0" : `${syncOffset > 0 ? "+" : ""}${syncOffset.toFixed(1)}`}s</span>
                  <button style={st.syncBtn} onClick={() => setSyncOffset(Math.round((syncOffset + 0.1) * 10) / 10)}>+0.1s</button>
                  <button style={st.syncBtn} onClick={() => setSyncOffset(Math.round((syncOffset + 0.5) * 10) / 10)}>+0.5s</button>
                </div>
                <button style={{ ...st.syncBtn, marginTop: 8, color: c.red, borderColor: c.red + "33" }} onClick={() => setSyncOffset(0)}>リセット</button>
              </div>
            )}
          </div>
          {ref.memo && <div style={st.sectionPad}><div style={st.sectionTitle}>メモ</div><div style={{ fontSize: 13, color: c.text, lineHeight: 1.6, padding: "2px 0 8px" }}>{ref.memo}</div></div>}
          {/* My videos thumbs */}
          <div style={st.sectionPad}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <span style={st.sectionTitle}>この見本の自分動画</span>
              <span style={{ fontSize: 11, color: c.textDim }}>{myVidsForRef.length}本</span>
            </div>
            <div style={st.thumbRow}>
              <div style={st.addThumb} onClick={() => setShowAddModal(true)}>
                <span style={{ fontSize: 18 }}>＋</span><span>撮影/選択</span>
              </div>
              {myVidsForRef.map(mv => (
                <div key={mv.id} style={{ ...st.myThumb, borderColor: myVideoId === mv.id ? c.myAccent : "transparent" }}
                  onClick={() => setMyVideoId(mv.id)}>
                  <span style={{ fontSize: 22 }}>📹</span>
                  <span style={st.myThumbLabel}>{mv.label}</span>
                  <span style={{ fontSize: 9, color: c.textDim }}>{mv.date.slice(5)}</span>
                </div>
              ))}
            </div>
          </div>
        </>
      )}

      {/* ========= SOLO MODE ========= */}
      {mode === "solo" && (
        <>
          <div style={st.playerArea}>
            <div style={st.playerBox}>
              {myVid ? (
                <>
                  <span style={{ fontSize: 44, marginBottom: 8 }}>📹</span>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>{myVid.label}</span>
                  <span style={{ fontSize: 11, color: c.textSub, marginTop: 4 }}>{formatDate(myVid.date)}　|　🎬 {getRefTitle(myVid.refId)}</span>
                  {soloPlaying && <div style={{ ...st.playingDot, background: c.myAccent }}>▶ 再生中</div>}
                </>
              ) : (
                <span style={{ fontSize: 13, color: c.textSub }}>下から動画を選択してください</span>
              )}
            </div>
          </div>
          <div style={st.timeline}><div style={{ ...st.timelineProgress, background: c.myAccent }} /></div>
          <div style={st.timelineTime}><span>0:08</span><span>0:34</span></div>
          <div style={st.controls}>
            <button style={{ ...st.speedBadge, color: c.myAccent, borderColor: c.myAccent + "44" }}
              onClick={() => setSoloSpeed(cycleSpeed(soloSpeed))}>{soloSpeed}x</button>
            <button style={st.ctrlBtn} onClick={() => {}}>↩</button>
            <button style={{ ...st.playBtnMain, background: c.myAccent, opacity: myVid ? 1 : 0.3 }}
              onClick={() => { if(myVid) setSoloPlaying(!soloPlaying); }}>{soloPlaying ? "⏸" : "▶"}</button>
            <button style={st.ctrlBtn} onClick={() => {}}>↪</button>
            <button style={st.ctrlBtn} onClick={() => {}}>🔁</button>
          </div>
          {/* Video list */}
          <div style={{ ...st.viewToggleWrap, marginTop: 8 }}>
            <button style={{ ...st.viewToggleBtn, ...(soloViewMode === "ref" ? st.viewToggleActive : {}) }}
              onClick={() => setSoloViewMode("ref")}>🎬 見本別</button>
            <button style={{ ...st.viewToggleBtn, ...(soloViewMode === "date" ? st.viewToggleActive : {}) }}
              onClick={() => setSoloViewMode("date")}>📅 日付</button>
          </div>
          <div style={{ paddingBottom: 4 }}>
            {soloViewMode === "ref" ? (
              Object.entries(soloGroupedByRef).map(([rid, group]) => {
                const key = `s-ref-${rid}`;
                const isCol = soloCollapsed[key];
                const isCur = myVid?.refId === rid;
                return (
                  <div key={key}>
                    <div style={{ ...st.groupHeader, ...(isCur ? { background: c.accentDim } : {}) }} onClick={() => toggleSoloCollapse(key)}>
                      <div style={{ display: "flex", alignItems: "center", gap: 8, flex: 1, minWidth: 0 }}>
                        <span style={{ ...st.collapseArrow, transform: isCol ? "rotate(-90deg)" : "rotate(0deg)" }}>▼</span>
                        <span style={{ fontSize: 13 }}>🎬</span>
                        <span style={{ fontWeight: 700, fontSize: 13, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{group.title}</span>
                      </div>
                      <span style={st.groupCount}>{group.videos.length}本</span>
                    </div>
                    {!isCol && <div style={{ padding: "0 16px 4px" }}>{renderSoloThumbRow(group.videos, rid)}</div>}
                  </div>
                );
              })
            ) : (
              Object.entries(soloGroupedByDate).map(([date, videos]) => {
                const key = `s-date-${date}`;
                const isCol = soloCollapsed[key];
                const isCur = myVid?.date === date;
                return (
                  <div key={key}>
                    <div style={{ ...st.groupHeader, ...(isCur ? { background: c.accentDim } : {}) }} onClick={() => toggleSoloCollapse(key)}>
                      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                        <span style={{ ...st.collapseArrow, transform: isCol ? "rotate(-90deg)" : "rotate(0deg)" }}>▼</span>
                        <span style={{ fontWeight: 700, fontSize: 13 }}>{formatDate(date)}</span>
                      </div>
                      <span style={st.groupCount}>{videos.length}本</span>
                    </div>
                    {!isCol && <div style={{ padding: "0 16px 4px" }}>{renderSoloThumbRow(videos, myVid?.refId)}</div>}
                  </div>
                );
              })
            )}
          </div>
        </>
      )}

      {/* Add modal (shared) */}
      {showAddModal && (
        <div style={st.overlay} onClick={() => setShowAddModal(false)}>
          <div style={st.modal} onClick={e => e.stopPropagation()}>
            <div style={st.modalTitle}>動画を追加</div>
            <div style={st.modalOption} onClick={() => addMyVideo("record")}
              onMouseEnter={e => e.currentTarget.style.background = c.surfaceHover}
              onMouseLeave={e => e.currentTarget.style.background = "transparent"}>
              <span style={{ fontSize: 20 }}>📷</span> カメラで撮影
            </div>
            <div style={st.modalOption} onClick={() => addMyVideo("gallery")}
              onMouseEnter={e => e.currentTarget.style.background = c.surfaceHover}
              onMouseLeave={e => e.currentTarget.style.background = "transparent"}>
              <span style={{ fontSize: 20 }}>📁</span> フォルダから選択
            </div>
            <div style={{ ...st.modalOption, color: c.textSub, justifyContent: "center", marginTop: 8 }}
              onClick={() => setShowAddModal(false)}>キャンセル</div>
          </div>
        </div>
      )}
    </div>
  );
}

// ============ REFERENCES TAB ============
function ReferencesTab({ data, setData, navigateTo }) {
  const [editingId, setEditingId] = useState(null);
  const [editMemo, setEditMemo] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [newMemo, setNewMemo] = useState("");
  const [newHasVideo, setNewHasVideo] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(null);
  const visibleRefs = data.references.filter(r => !r.hidden);

  const saveMemo = (id) => { setData(d => ({ ...d, references: d.references.map(r => r.id === id ? { ...r, memo: editMemo } : r) })); setEditingId(null); };
  const toggleMirror = (id) => { setData(d => ({ ...d, references: d.references.map(r => r.id === id ? { ...r, mirror: !r.mirror } : r) })); };
  const hideRef = (id) => { setData(d => ({ ...d, references: d.references.map(r => r.id === id ? { ...r, hidden: true } : r), myVideos: d.myVideos.map(v => v.refId === id ? { ...v, hidden: true } : v) })); };
  const addRef = () => {
    if (!newTitle || !newHasVideo) return;
    setData(d => ({ ...d, references: [...d.references, { id: `r${Date.now()}`, title: newTitle, memo: newMemo, mirror: false, hidden: false, createdAt: new Date().toISOString().slice(0, 10) }] }));
    setShowAdd(false); setNewTitle(""); setNewMemo(""); setNewHasVideo(false);
  };
  const deleteRef = (id) => { setData(d => ({ ...d, references: d.references.filter(r => r.id !== id), myVideos: d.myVideos.filter(v => v.refId !== id) })); setShowDeleteConfirm(null); };

  return (
    <div style={{ paddingBottom: 90 }}>
      <div style={st.pageHeader}>
        <span style={{ fontSize: 17, fontWeight: 700 }}>見本動画</span>
        <button style={st.addBtn} onClick={() => setShowAdd(true)}>＋ 追加</button>
      </div>
      {visibleRefs.length > 0 && <div style={{ textAlign: "center", fontSize: 10, color: c.textDim, padding: "0 0 6px" }}>→ スワイプで非表示・削除</div>}
      {visibleRefs.length === 0 ? (
        <div style={st.emptyState}><span style={{ fontSize: 40, marginBottom: 12 }}>🎬</span><span>見本動画を追加しましょう</span></div>
      ) : visibleRefs.map(ref => {
        const count = data.myVideos.filter(v => v.refId === ref.id && !v.hidden).length;
        return (
          <SwipeRow key={ref.id} onHide={() => hideRef(ref.id)} onDelete={() => setShowDeleteConfirm(ref.id)}>
            <div style={{ ...st.refCard, cursor: "pointer" }} onClick={() => navigateTo("compare", ref.id)}>
              <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
                <div style={{ ...st.refThumb, background: c.refBg }}><span style={{ fontSize: 26 }}>🎬</span>
                  {ref.mirror && <span style={{ position: "absolute", top: 2, right: 2, fontSize: 10 }}>🪞</span>}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{ref.title}</div>
                  <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>
                    <span style={st.badge}>自分 {count}本</span>
                    <span style={{ fontSize: 11, color: c.textDim }}>{ref.createdAt}</span>
                  </div>
                </div>
              </div>
              {editingId === ref.id ? (
                <div style={{ marginTop: 10 }} onClick={e => e.stopPropagation()}>
                  <textarea style={st.textarea} value={editMemo} onChange={e => setEditMemo(e.target.value)} placeholder="メモを入力..." />
                  <div style={{ display: "flex", gap: 8, marginTop: 6 }}>
                    <button style={{ ...st.primaryBtn, flex: 1 }} onClick={() => saveMemo(ref.id)}>保存</button>
                    <button style={st.ghostBtn} onClick={() => setEditingId(null)}>取消</button>
                  </div>
                </div>
              ) : <div style={{ marginTop: 8, fontSize: 13, color: ref.memo ? c.text : c.textDim, lineHeight: 1.6 }}>{ref.memo || "メモなし"}</div>}
              <div style={{ display: "flex", gap: 12, marginTop: 10, alignItems: "center" }} onClick={e => e.stopPropagation()}>
                <button style={st.linkBtn} onClick={() => { setEditingId(ref.id); setEditMemo(ref.memo); }}>メモ編集</button>
                <button style={{ ...st.linkBtn, color: ref.mirror ? c.accent : c.textSub }} onClick={() => toggleMirror(ref.id)}>🪞 {ref.mirror ? "ON" : "OFF"}</button>
              </div>
            </div>
          </SwipeRow>
        );
      })}
      {showAdd && (
        <div style={st.overlay} onClick={() => setShowAdd(false)}><div style={st.modal} onClick={e => e.stopPropagation()}>
          <div style={st.modalTitle}>見本動画を追加</div>
          <div style={{ padding: "0 20px" }}>
            <label style={st.label}>動画ソース</label>
            {!newHasVideo ? (
              <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
                <div style={{ ...st.uploadBox, flex: 1 }} onClick={() => setNewHasVideo(true)}><span style={{ fontSize: 22 }}>📷</span><span>撮影</span></div>
                <div style={{ ...st.uploadBox, flex: 1 }} onClick={() => setNewHasVideo(true)}><span style={{ fontSize: 22 }}>📁</span><span>フォルダ</span></div>
              </div>
            ) : (
              <div style={{ ...st.selectedBadge, marginBottom: 14 }}>
                <span style={{ color: c.accent, fontWeight: 600 }}>✓ 選択済み</span>
                <button style={{ ...st.linkBtn, color: c.red, fontSize: 11 }} onClick={() => setNewHasVideo(false)}>取消</button>
              </div>
            )}
            <label style={st.label}>タイトル *</label>
            <input style={st.input} value={newTitle} onChange={e => setNewTitle(e.target.value)} placeholder="例: ウェーブ基礎" />
            <label style={{ ...st.label, marginTop: 12 }}>メモ（任意）</label>
            <textarea style={{ ...st.textarea, minHeight: 60 }} value={newMemo} onChange={e => setNewMemo(e.target.value)} placeholder="ポイントなど" />
            <button style={{ ...st.primaryBtn, width: "100%", marginTop: 14, marginBottom: 8, ...(!newTitle || !newHasVideo ? { opacity: 0.4 } : {}) }}
              onClick={addRef} disabled={!newTitle || !newHasVideo}>追加する</button>
          </div>
        </div></div>
      )}
      {showDeleteConfirm && (
        <div style={st.overlay} onClick={() => setShowDeleteConfirm(null)}><div style={st.modal} onClick={e => e.stopPropagation()}>
          <div style={{ padding: "4px 24px 16px", fontSize: 14, lineHeight: 1.6 }}>この見本動画と紐づく自分の動画をすべて削除しますか？</div>
          <div style={st.modalOption} onClick={() => deleteRef(showDeleteConfirm)}><span style={{ color: c.red }}>🗑 削除する</span></div>
          <div style={{ ...st.modalOption, color: c.textSub, justifyContent: "center" }} onClick={() => setShowDeleteConfirm(null)}>キャンセル</div>
        </div></div>
      )}
    </div>
  );
}

// ============ MY VIDEOS TAB ============
function MyVideosTab({ data, setData, navigateTo }) {
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(null);
  const [viewMode, setViewMode] = useState("date");
  const [collapsed, setCollapsed] = useState({});
  const toggleCollapse = (key) => setCollapsed(prev => ({ ...prev, [key]: !prev[key] }));
  const visibleVideos = data.myVideos.filter(v => !v.hidden);

  const groupedByDate = useMemo(() => {
    const g = {}; [...visibleVideos].sort((a, b) => b.date.localeCompare(a.date)).forEach(v => { if (!g[v.date]) g[v.date] = []; g[v.date].push(v); }); return g;
  }, [visibleVideos]);
  const groupedByRef = useMemo(() => {
    const g = {}; data.references.forEach(r => { const vids = visibleVideos.filter(v => v.refId === r.id).sort((a, b) => b.date.localeCompare(a.date)); if (vids.length > 0) g[r.id] = { title: r.title, videos: vids }; });
    const orphaned = visibleVideos.filter(v => !data.references.find(r => r.id === v.refId)); if (orphaned.length > 0) g["_orphan"] = { title: "紐づけなし", videos: orphaned }; return g;
  }, [visibleVideos, data.references]);

  const hideVideo = (id) => { setData(d => ({ ...d, myVideos: d.myVideos.map(v => v.id === id ? { ...v, hidden: true } : v) })); };
  const deleteVideo = (id) => { setData(d => ({ ...d, myVideos: d.myVideos.filter(v => v.id !== id) })); setShowDeleteConfirm(null); };
  const getRefTitle = (rid) => data.references.find(r => r.id === rid)?.title || "不明";
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  const formatDate = (d) => { if (d === today) return "今日"; if (d === yesterday) return "昨日"; return d.replace(/^\d{4}-/, "").replace("-", "/"); };

  const renderRow = (v, showRef, showDate) => (
    <SwipeRow key={v.id} onHide={() => hideVideo(v.id)} onDelete={() => setShowDeleteConfirm(v.id)}>
      <div style={{ ...st.myVideoCard, cursor: "pointer" }} onClick={() => navigateTo("compare-solo", v.refId, v.id)}>
        <div style={{ ...st.myVideoCardThumb, background: c.myBg }}><span style={{ fontSize: 22 }}>📹</span></div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 600, marginBottom: 2 }}>{v.label}</div>
          <div style={{ fontSize: 12, color: c.textSub, display: "flex", alignItems: "center", gap: 6 }}>
            {showRef && <><span style={{ fontSize: 10 }}>🎬</span><span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{getRefTitle(v.refId)}</span></>}
            {showDate && <span>{formatDate(v.date)}</span>}
          </div>
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "center", flexShrink: 0 }} onClick={e => e.stopPropagation()}>
          <button style={st.linkBtn} onClick={() => navigateTo("compare", v.refId, v.id)}>比較 →</button>
        </div>
      </div>
    </SwipeRow>
  );

  return (
    <div style={{ paddingBottom: 90 }}>
      <div style={st.pageHeader}>
        <span style={{ fontSize: 17, fontWeight: 700 }}>自分の動画</span>
        <span style={{ fontSize: 12, color: c.textSub }}>{visibleVideos.length} 本</span>
      </div>
      {visibleVideos.length > 0 && (
        <><div style={st.viewToggleWrap}>
          <button style={{ ...st.viewToggleBtn, ...(viewMode === "date" ? st.viewToggleActive : {}) }} onClick={() => setViewMode("date")}>📅 日付</button>
          <button style={{ ...st.viewToggleBtn, ...(viewMode === "ref" ? st.viewToggleActive : {}) }} onClick={() => setViewMode("ref")}>🎬 見本別</button>
        </div>
        <div style={{ textAlign: "center", fontSize: 10, color: c.textDim, padding: "4px 0 2px" }}>→ スワイプで非表示・削除</div></>
      )}
      {visibleVideos.length === 0 ? (
        <div style={st.emptyState}><span style={{ fontSize: 40, marginBottom: 12 }}>📹</span><span>比較タブから動画を撮影・選択すると<br/>ここに表示されます</span></div>
      ) : viewMode === "date" ? (
        Object.entries(groupedByDate).map(([date, videos]) => {
          const key = `date-${date}`; const isCol = collapsed[key];
          return (<div key={key}><div style={st.groupHeader} onClick={() => toggleCollapse(key)}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <span style={{ ...st.collapseArrow, transform: isCol ? "rotate(-90deg)" : "rotate(0deg)" }}>▼</span>
              <span style={{ fontWeight: 700 }}>{formatDate(date)}</span>
            </div><span style={st.groupCount}>{videos.length}本</span>
          </div>{!isCol && videos.map(v => renderRow(v, true, false))}</div>);
        })
      ) : (
        Object.entries(groupedByRef).map(([rid, group]) => {
          const key = `ref-${rid}`; const isCol = collapsed[key];
          return (<div key={key}><div style={st.groupHeader} onClick={() => toggleCollapse(key)}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, flex: 1, minWidth: 0 }}>
              <span style={{ ...st.collapseArrow, transform: isCol ? "rotate(-90deg)" : "rotate(0deg)" }}>▼</span>
              <span style={{ fontSize: 14 }}>🎬</span>
              <span style={{ fontWeight: 700, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{group.title}</span>
            </div><span style={st.groupCount}>{group.videos.length}本</span>
          </div>{!isCol && group.videos.map(v => renderRow(v, false, true))}</div>);
        })
      )}
      {showDeleteConfirm && (
        <div style={st.overlay} onClick={() => setShowDeleteConfirm(null)}><div style={st.modal} onClick={e => e.stopPropagation()}>
          <div style={{ padding: "4px 24px 16px", fontSize: 14 }}>この動画を削除しますか？</div>
          <div style={st.modalOption} onClick={() => deleteVideo(showDeleteConfirm)}><span style={{ color: c.red }}>🗑 削除する</span></div>
          <div style={{ ...st.modalOption, color: c.textSub, justifyContent: "center" }} onClick={() => setShowDeleteConfirm(null)}>キャンセル</div>
        </div></div>
      )}
    </div>
  );
}

// ============ SETTINGS TAB ============
function SettingsTab({ data, setData }) {
  const [page, setPage] = useState("menu");
  const hiddenVideos = data.myVideos.filter(v => v.hidden);
  const hiddenRefs = data.references.filter(r => r.hidden);
  const getRefTitle = (rid) => data.references.find(r => r.id === rid)?.title || "不明";

  const unhideVideo = (id) => { setData(d => ({ ...d, myVideos: d.myVideos.map(v => v.id === id ? { ...v, hidden: false } : v) })); };
  const deleteVideo = (id) => { setData(d => ({ ...d, myVideos: d.myVideos.filter(v => v.id !== id) })); };
  const unhideRef = (id) => { setData(d => ({ ...d, references: d.references.map(r => r.id === id ? { ...r, hidden: false } : r), myVideos: d.myVideos.map(v => v.refId === id ? { ...v, hidden: false } : v) })); };
  const deleteRef = (id) => { setData(d => ({ ...d, references: d.references.filter(r => r.id !== id), myVideos: d.myVideos.filter(v => v.refId !== id) })); };

  return (
    <div style={{ paddingBottom: 90 }}>
      {page === "menu" && (<>
        <div style={st.pageHeader}><span style={{ fontSize: 17, fontWeight: 700 }}>設定</span></div>
        <div style={st.settingsItem} onClick={() => setPage("hiddenVideos")}
          onMouseEnter={e => e.currentTarget.style.background = c.surfaceHover}
          onMouseLeave={e => e.currentTarget.style.background = "transparent"}>
          <span style={{ fontSize: 18 }}>📹</span>
          <div style={{ flex: 1 }}><div style={{ fontWeight: 600 }}>非表示の自分の動画</div><div style={{ fontSize: 12, color: c.textSub, marginTop: 2 }}>{hiddenVideos.length > 0 ? `${hiddenVideos.length}件` : "なし"}</div></div>
          <span style={{ color: c.textSub, fontSize: 18 }}>›</span>
        </div>
        <div style={st.settingsItem} onClick={() => setPage("hiddenRefs")}
          onMouseEnter={e => e.currentTarget.style.background = c.surfaceHover}
          onMouseLeave={e => e.currentTarget.style.background = "transparent"}>
          <span style={{ fontSize: 18 }}>🎬</span>
          <div style={{ flex: 1 }}><div style={{ fontWeight: 600 }}>非表示の見本動画</div><div style={{ fontSize: 12, color: c.textSub, marginTop: 2 }}>{hiddenRefs.length > 0 ? `${hiddenRefs.length}件` : "なし"}</div></div>
          <span style={{ color: c.textSub, fontSize: 18 }}>›</span>
        </div>
      </>)}
      {page === "hiddenVideos" && (<>
        <div style={st.pageHeader}>
          <button style={st.backBtn} onClick={() => setPage("menu")}>← 設定</button>
          <span style={{ fontSize: 15, fontWeight: 700 }}>非表示の自分の動画</span><div style={{ width: 48 }} />
        </div>
        {hiddenVideos.length === 0 ? <div style={{ ...st.emptyState, padding: "60px 20px" }}><span style={{ fontSize: 32, marginBottom: 8 }}>📹</span><span>非表示の動画はありません</span></div> : (
          <div>{hiddenVideos.map(v => (
            <SwipeRow key={v.id} onDelete={() => deleteVideo(v.id)}>
              <div style={st.hiddenRow}>
                <div style={{ ...st.myVideoCardThumb, background: c.myBg, width: 44, height: 44 }}><span style={{ fontSize: 18 }}>📹</span></div>
                <div style={{ flex: 1, minWidth: 0 }}><div style={{ fontWeight: 600, fontSize: 13 }}>{v.label}</div><div style={{ fontSize: 11, color: c.textSub }}>🎬 {getRefTitle(v.refId)} ・ {v.date}</div></div>
                <button style={{ ...st.smallActionBtn, background: c.accent + "22", color: c.accent }} onClick={() => unhideVideo(v.id)}>再表示</button>
              </div>
            </SwipeRow>
          ))}</div>
        )}
      </>)}
      {page === "hiddenRefs" && (<>
        <div style={st.pageHeader}>
          <button style={st.backBtn} onClick={() => setPage("menu")}>← 設定</button>
          <span style={{ fontSize: 15, fontWeight: 700 }}>非表示の見本動画</span><div style={{ width: 48 }} />
        </div>
        {hiddenRefs.length === 0 ? <div style={{ ...st.emptyState, padding: "60px 20px" }}><span style={{ fontSize: 32, marginBottom: 8 }}>🎬</span><span>非表示の見本動画はありません</span></div> : (
          <div>{hiddenRefs.map(r => {
            const count = data.myVideos.filter(v => v.refId === r.id).length;
            return (
              <SwipeRow key={r.id} onDelete={() => deleteRef(r.id)}>
                <div style={st.hiddenRow}>
                  <div style={{ ...st.myVideoCardThumb, background: c.refBg, width: 44, height: 44 }}><span style={{ fontSize: 18 }}>🎬</span></div>
                  <div style={{ flex: 1, minWidth: 0 }}><div style={{ fontWeight: 600, fontSize: 13 }}>{r.title}</div><div style={{ fontSize: 11, color: c.textSub }}>自分の動画 {count}本 ・ {r.createdAt}</div></div>
                  <button style={{ ...st.smallActionBtn, background: c.accent + "22", color: c.accent }} onClick={() => unhideRef(r.id)}>再表示</button>
                </div>
              </SwipeRow>
            );
          })}</div>
        )}
      </>)}
    </div>
  );
}

// ============ APP ============
export default function App() {
  const [tab, setTab] = useState("compare");
  const [data, setData] = useState(INITIAL_DATA);
  const [initRefId, setInitRefId] = useState(null);
  const [initMyId, setInitMyId] = useState(null);
  const [initMode, setInitMode] = useState(null);

  const navigateTo = (target, refId, myId) => {
    if (target === "compare-solo") {
      setTab("compare"); setInitRefId(refId); setInitMyId(myId); setInitMode("solo");
    } else if (target === "compare") {
      setTab("compare"); setInitRefId(refId); setInitMyId(myId); setInitMode("compare");
    } else {
      setTab(target);
    }
  };

  return (
    <div style={st.app}>
      {tab === "compare" && <CompareTab data={data} setData={setData} navigateTo={navigateTo} initMode={initMode} initRefId={initRefId} initMyId={initMyId} key={`${initRefId}-${initMyId}-${initMode}`} />}
      {tab === "references" && <ReferencesTab data={data} setData={setData} navigateTo={navigateTo} />}
      {tab === "myvideos" && <MyVideosTab data={data} setData={setData} navigateTo={navigateTo} />}
      {tab === "settings" && <SettingsTab data={data} setData={setData} />}
      <TabBar active={tab} onChange={setTab} />
    </div>
  );
}

// ============ STYLES ============
const st = {
  app: { fontFamily: "'Helvetica Neue', 'Hiragino Sans', sans-serif", background: c.bg, color: c.text, minHeight: "100vh", maxWidth: 420, margin: "0 auto", position: "relative", fontSize: 14 },
  tabBar: { position: "fixed", bottom: 0, left: "50%", transform: "translateX(-50%)", width: "100%", maxWidth: 420, display: "flex", background: c.tabBg, borderTop: `1px solid ${c.tabBorder}`, zIndex: 50 },
  tab: { flex: 1, display: "flex", flexDirection: "column", alignItems: "center", padding: "8px 0 6px", background: "none", border: "none", color: c.textSub, cursor: "pointer", transition: "color 0.15s" },
  tabActive: { color: c.accent },
  pageHeader: { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "16px 16px 12px", position: "sticky", top: 0, background: c.bg, zIndex: 10 },
  backBtn: { background: "none", border: "none", color: c.accent, fontSize: 14, cursor: "pointer", padding: "4px 0" },
  modeToggleBtn: {
    padding: "6px 12px", borderRadius: 8, border: `1px solid ${c.border}`,
    background: c.surface, color: c.accent, fontSize: 12, fontWeight: 700, cursor: "pointer",
  },
  refSelector: { display: "flex", alignItems: "center", width: "calc(100% - 32px)", margin: "0 16px", padding: "10px 14px", borderRadius: 10, border: `1px solid ${c.border}`, background: c.surface, color: c.text, cursor: "pointer", fontSize: 14 },
  refPickerDropdown: { margin: "4px 16px 0", borderRadius: 10, overflow: "hidden", border: `1px solid ${c.border}`, background: c.surface },
  refPickerItem: { padding: "12px 14px", cursor: "pointer", display: "flex", justifyContent: "space-between", alignItems: "center", borderBottom: `1px solid ${c.border}`, fontSize: 14 },
  compareArea: { display: "flex", gap: 8, padding: "10px 16px" },
  videoBox: { flex: 1, aspectRatio: "9/16", borderRadius: 10, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", fontSize: 13, color: c.textSub, position: "relative", overflow: "hidden" },
  videoLabel: { position: "absolute", top: 8, left: 8, fontSize: 10, fontWeight: 700, padding: "2px 8px", borderRadius: 4 },
  playingDot: { position: "absolute", bottom: 8, left: "50%", transform: "translateX(-50%)", fontSize: 9, fontWeight: 700, color: "#000", padding: "2px 10px", borderRadius: 99 },
  miniControls: { display: "flex", gap: 6, justifyContent: "center", alignItems: "center" },
  miniBtn: { width: 32, height: 28, borderRadius: 6, border: `1px solid ${c.border}`, background: c.surface, color: c.text, fontSize: 13, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" },
  speedBadge: { fontSize: 11, fontWeight: 700, padding: "4px 10px", borderRadius: 6, border: "1px solid", background: "transparent", cursor: "pointer" },
  controls: { display: "flex", justifyContent: "center", gap: 16, padding: "10px 16px", alignItems: "center" },
  ctrlBtn: { width: 44, height: 44, borderRadius: 99, border: `1px solid ${c.border}`, background: c.surface, color: c.text, fontSize: 18, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" },
  playBtnMain: { width: 56, height: 56, borderRadius: 99, border: "none", background: c.accent, color: "#000", fontSize: 18, fontWeight: 700, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" },
  timeline: { margin: "0 16px", height: 4, background: c.border, borderRadius: 2, cursor: "pointer" },
  timelineProgress: { height: "100%", background: c.accent, borderRadius: 2, width: "35%" },
  timelineTime: { display: "flex", justifyContent: "space-between", padding: "6px 16px 0", fontSize: 11, color: c.textSub },
  sectionPad: { padding: "0 16px", marginTop: 8 },
  syncToggle: { width: "100%", display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 14px", borderRadius: 10, border: `1px solid ${c.border}`, background: c.surface, color: c.text, fontSize: 13, cursor: "pointer" },
  syncPanel: { marginTop: 8, padding: 14, borderRadius: 10, background: c.surface, border: `1px solid ${c.border}` },
  syncRow: { display: "flex", alignItems: "center", justifyContent: "center", gap: 6 },
  syncBtn: { padding: "6px 12px", borderRadius: 6, border: `1px solid ${c.border}`, background: "transparent", color: c.text, fontSize: 12, cursor: "pointer" },
  syncValue: { minWidth: 60, textAlign: "center", fontSize: 18, fontWeight: 700, color: c.accent },
  sectionTitle: { fontSize: 12, fontWeight: 700, color: c.textSub, textTransform: "uppercase", letterSpacing: 1, marginBottom: 6 },
  thumbRow: { display: "flex", gap: 8, overflowX: "auto", paddingBottom: 8, marginTop: 4 },
  addThumb: { width: 76, minWidth: 76, height: 100, borderRadius: 8, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", border: `2px dashed ${c.border}`, cursor: "pointer", fontSize: 11, color: c.textSub, gap: 4 },
  myThumb: { width: 76, minWidth: 76, height: 100, borderRadius: 8, background: c.myBg, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", cursor: "pointer", border: "2px solid transparent", transition: "border 0.15s", gap: 2 },
  myThumbLabel: { fontSize: 10, color: c.textSub },
  playerArea: { padding: "12px 16px" },
  playerBox: { width: "100%", aspectRatio: "16/9", borderRadius: 12, background: c.myBg, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", position: "relative", overflow: "hidden" },
  refCard: { margin: "0 16px 10px", padding: 14, borderRadius: 12, background: c.surface, border: `1px solid ${c.border}` },
  refThumb: { width: 56, height: 56, borderRadius: 8, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, position: "relative" },
  badge: { background: c.accentDim, color: c.accent, padding: "2px 8px", borderRadius: 99, fontSize: 11, fontWeight: 600 },
  addBtn: { padding: "6px 14px", borderRadius: 8, border: "none", background: c.accent, color: "#000", fontSize: 13, fontWeight: 700, cursor: "pointer" },
  groupHeader: { display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 16px 8px", cursor: "pointer", userSelect: "none" },
  groupCount: { fontSize: 11, color: c.textDim, flexShrink: 0 },
  collapseArrow: { fontSize: 10, color: c.textSub, transition: "transform 0.2s", display: "inline-block" },
  viewToggleWrap: { display: "flex", margin: "0 16px 4px", padding: 3, borderRadius: 10, background: c.surface, border: `1px solid ${c.border}` },
  viewToggleBtn: { flex: 1, padding: "7px 0", borderRadius: 8, border: "none", background: "transparent", color: c.textSub, fontSize: 13, cursor: "pointer", fontWeight: 600, transition: "all 0.15s" },
  viewToggleActive: { background: c.accent, color: "#000" },
  myVideoCard: { display: "flex", alignItems: "center", gap: 12, padding: "10px 16px", borderBottom: `1px solid ${c.border}` },
  myVideoCardThumb: { width: 48, height: 48, borderRadius: 8, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 },
  settingsItem: { display: "flex", alignItems: "center", gap: 14, padding: "16px 20px", cursor: "pointer", transition: "background 0.15s", borderBottom: `1px solid ${c.border}` },
  hiddenRow: { display: "flex", alignItems: "center", gap: 10, padding: "12px 20px", borderBottom: `1px solid ${c.border}` },
  smallActionBtn: { padding: "5px 10px", borderRadius: 6, border: "none", fontSize: 11, fontWeight: 700, cursor: "pointer" },
  linkBtn: { background: "none", border: "none", color: c.accent, fontSize: 12, cursor: "pointer", padding: 0 },
  primaryBtn: { padding: "10px", borderRadius: 8, border: "none", background: c.accent, color: "#000", fontSize: 14, fontWeight: 700, cursor: "pointer" },
  ghostBtn: { padding: "10px 16px", borderRadius: 8, border: `1px solid ${c.border}`, background: "transparent", color: c.text, fontSize: 14, cursor: "pointer" },
  label: { fontSize: 12, fontWeight: 600, color: c.textSub, marginBottom: 6, display: "block" },
  input: { width: "100%", padding: "10px 12px", borderRadius: 8, border: `1px solid ${c.border}`, background: c.surface, color: c.text, fontSize: 14, outline: "none", boxSizing: "border-box" },
  textarea: { width: "100%", padding: "10px 12px", borderRadius: 8, minHeight: 80, border: `1px solid ${c.border}`, background: c.surface, color: c.text, fontSize: 14, outline: "none", resize: "vertical", fontFamily: "inherit", boxSizing: "border-box" },
  uploadBox: { height: 80, borderRadius: 10, border: `2px dashed ${c.border}`, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", color: c.textSub, fontSize: 12, cursor: "pointer", gap: 6 },
  selectedBadge: { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "10px 14px", borderRadius: 10, border: `1px solid ${c.accent}`, background: c.accentDim },
  emptyState: { display: "flex", flexDirection: "column", alignItems: "center", color: c.textSub, padding: "60px 20px", fontSize: 14, lineHeight: 1.8, textAlign: "center" },
  overlay: { position: "fixed", inset: 0, background: "#000b", display: "flex", alignItems: "flex-end", justifyContent: "center", zIndex: 100 },
  modal: { background: c.surface, borderRadius: "16px 16px 0 0", width: "100%", maxWidth: 420, padding: "20px 0 32px" },
  modalTitle: { padding: "0 24px 16px", fontSize: 16, fontWeight: 700 },
  modalOption: { padding: "14px 24px", fontSize: 15, cursor: "pointer", display: "flex", alignItems: "center", gap: 12 },
};
