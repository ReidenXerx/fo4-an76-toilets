---
name: gitnexus-area-tools
description: "Skill for the Tools area of fo4-an76-toilets. 43 symbols across 5 files."
---

# Tools

43 symbols | 5 files | Cohesion: 89%

## When to Use

- Working with code in `tools/`
- Understanding how build, new_id, topic_array work
- Modifying tools-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `tools/make_esp.py` | build, new_id, topic_array, child_group, field (+11) |
| `tools/make_widget.py` | build_swf, main, rect, sbits, shape (+9) |
| `tools/make_mcm.py` | build, button, slider, switcher, form (+1) |
| `tools/make_voice.py` | lipgen_copy, main, make_fuz, vowel_run_lip |
| `tools/make_meshes.py` | extract, hide_geometry, main |

## Entry Points

Start here when exploring this area:

- **`build`** (Function) — `tools/make_esp.py:195`
- **`new_id`** (Function) — `tools/make_esp.py:204`
- **`topic_array`** (Function) — `tools/make_esp.py:338`
- **`child_group`** (Function) — `tools/make_esp.py:173`
- **`field`** (Function) — `tools/make_esp.py:148`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `build` | Function | `tools/make_esp.py` | 195 |
| `new_id` | Function | `tools/make_esp.py` | 204 |
| `topic_array` | Function | `tools/make_esp.py` | 338 |
| `child_group` | Function | `tools/make_esp.py` | 173 |
| `field` | Function | `tools/make_esp.py` | 148 |
| `group` | Function | `tools/make_esp.py` | 168 |
| `main` | Function | `tools/make_esp.py` | 397 |
| `obj` | Function | `tools/make_esp.py` | 179 |
| `obnd` | Function | `tools/make_esp.py` | 191 |
| `record` | Function | `tools/make_esp.py` | 163 |
| `vmad` | Function | `tools/make_esp.py` | 183 |
| `wstring` | Function | `tools/make_esp.py` | 158 |
| `zstring` | Function | `tools/make_esp.py` | 154 |
| `build_swf` | Function | `tools/make_widget.py` | 207 |
| `main` | Function | `tools/make_widget.py` | 229 |
| `rect` | Function | `tools/make_widget.py` | 163 |
| `sbits` | Function | `tools/make_widget.py` | 155 |
| `shape` | Function | `tools/make_widget.py` | 178 |
| `tag` | Function | `tools/make_widget.py` | 172 |
| `voice_clips` | Function | `tools/make_esp.py` | 89 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `Main → Bytes` | cross_community | 6 |
| `Main → Wstring` | cross_community | 5 |
| `Main → New_id` | cross_community | 4 |
| `Main → Field` | cross_community | 4 |
| `Main → Zstring` | cross_community | 4 |
| `Main → Form` | intra_community | 4 |
| `Main → Lipgen_copy` | intra_community | 4 |
| `Main → U` | intra_community | 4 |
| `Main → Wstring` | intra_community | 4 |
| `Main → Wstring` | cross_community | 4 |

## How to Explore

1. `context({name: "build"})` — see callers and callees
2. `query({search_query: "tools"})` — find related execution flows
3. Read key files listed above for implementation details
4. `explain({target: "<file or symbol>"})` — persisted taint findings (source→sink data flows), when indexed with `--pdg`
