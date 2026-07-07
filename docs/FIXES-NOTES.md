# Recent Fixes — Engineering Notes

Three fixes currently applied in the codebase, what each does, and what it interferes with.

---

## 1. Composite `PreviewOwnerKey` fix (`PreviewPopoverController.swift`)

**What it does:** Previously `anchors`, `contentProviders`, and `yOffsets` were keyed by `CGWindowID` alone, shared across every display's bar. If the same window is tabbed on two displays, whichever display registered last silently overwrote the other's anchor. Now the key is `(windowID, ObjectIdentifier(previewState))`, so each display's registration is isolated. `currentOwnerKey` tracks the active composite key alongside the legacy `currentOwnerID`.

**What it interferes with:**
- **`AppKitTabButtonView.onDisappear`** — now must pass `previewState:` into `unregister()`. Any other future call site that unregisters without the matching `previewState` instance will silently no-op (key won't match, nothing gets removed), leaking a stale anchor entry for that display until overwritten.
- **`subscribe(to:)` / multi-display bring-up in `MultiDisplayManager`** — this fix assumes every display's `PreviewState` instance is distinct and stable for the lifetime of that display's bar. If a display's `PreviewState` is ever recreated (e.g. display reconnect rebuilding the whole window controller), old composite keys under the previous `ObjectIdentifier` become orphaned dead entries in the dictionaries — harmless memory-wise (they just never resolve again) but worth an eventual cleanup pass if display hotplug churn is high.
- **Cross-display relocate path** (`transition()`'s `existing.window === currentAnchorWindow` check) is untouched by this fix and still forces a full teardown/rebuild when hopping displays — that behavior is orthogonal but easy to conflate with this bug since both are "wrong display" symptoms.

---

## 2. `internalWindowSpaceIDs(for:)` — CGS Space-membership workaround

**What it does:** `CGSCopySpacesForWindows` is broken on macOS 14+ and always returns `[1]`. `internalWindowSpaceIDs` instead uses `observedWindowSpaces[windowID]`, a dictionary populated whenever a window was actually seen onscreen with its genuine Space ID, falling back to the (broken) direct CGS call only for windows never observed.

**What it interferes with:**
- **Cold-start / windows never seen onscreen** (e.g. a window created on a different Space before AeroBar launched) still falls through to the broken `windowSpaceIDs()` call and gets `[1]` — meaning any pruning/fullscreen logic gating on this function is only as good as its most recent *observed* placement. A window silently moved to another Space entirely off-screen (never re-observed) will keep reporting its last-known stale Space.
- **`observedWindowSpaces` cache invalidation** — nothing currently purges an entry when a window closes, so it persists until overwritten or the daemon restarts. Not a correctness bug today, but unbounded growth over a long session if window IDs churn a lot (e.g. apps like PDFgear/VLC that spawn/destroy dummy windows frequently).
- Any code path that assumes the raw `windowSpaceIDs()` function is reliable will still get bitten — the wrapper only helps callers who go through `internalWindowSpaceIDs`. Worth grepping for any remaining direct `windowSpaceIDs(...)` calls in hot paths (there are a couple left, around lines ~1434 and ~1719) to confirm they're intentionally using the raw fallback and not accidentally reintroducing the `[1]` bug.

---

## 3. `onDedicatedFullscreenSpace` heuristic-3 gating fix

**What it does:** The prune loop's dwell-timer heuristic 3 used to gate on `!hasRealSpaceMembershipNow` — a broad "does this window have any real Space membership at all" check — which permanently exempted windows from pruning even when the *reason* they had membership was unrelated to fullscreen. It's now gated on the narrower `!onDedicatedFullscreenSpace`, computed by intersecting `windowSpaceIDs(windowID)` against the current fullscreen Space set (`fullscreenSpaceIDsByScreen()`).

**What it interferes with:**
- This computation intentionally uses the **raw** `windowSpaceIDs(windowID)` (not `internalWindowSpaceIDs`) around line ~1434 — meaning it inherits the macOS 14+ `[1]` bug directly unless `fsSet` also happens to contain `1`. Double-check this was deliberate; if `windowSpacesNow` is always `[1]` on broken macOS versions, `onDedicatedFullscreenSpace` could false-positive/negative depending on whether Space ID `1` is ever a real fullscreen Space ID on the test machine. This is the one spot where fix #2 and fix #3 have a seam — worth explicitly tracing whether that call should be `internalWindowSpaceIDs` instead.
- **Ghost apps confirmed** (Notes, PDFgear, Activity Monitor, VLC) were the original repro cases for the *old* broad heuristic; since the new heuristic is stricter, it's worth re-confirming none of those four regressed into getting pruned too aggressively while genuinely fullscreened (the opposite failure mode from ghosting).
- Interacts with `ghostCandidateGracePeriod` (0.8s) and `recentlyDestroyedPIDs` — both are separate grace mechanisms layered on top of this heuristic. If heuristic 3 now prunes faster/more aggressively, it's possible for a window to get pruned before the 0.8s CGS/AX lag window closes, re-opening the exact race the grace period was built to cover. Worth a regression pass specifically on Space-transition timing, not just static fullscreen state.

---

## Overall recommendation

Fixes #2 and #3 are tightly coupled (both live in the same Space-membership tracking system) — any future change to one should be re-tested against the other's assumptions, especially the raw-vs-wrapped `windowSpaceIDs` call sites.
