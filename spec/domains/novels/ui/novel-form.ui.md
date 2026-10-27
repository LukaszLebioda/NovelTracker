# Novel form — UI note (low fidelity)

**Status:** draft for review
**Date:** 2026-10-27
**Screen goal:** Create one novel entry.
**Actor:** user (authentication and per-user ownership are deferred)
**Linked rules:** REQ-001…REQ-011, REQ-037…REQ-039

> Visual/layout only — NOT the behavioural source of truth.
> Behaviour lives in `spec/features/novels/*.feature`.
> Editing is a deferred feature; this note currently covers creation.

## Fields

| Field | Control | Notes |
|---|---|---|
| Author | single-line text box | plain input |
| Polish title | single-line text box | plain input |
| Original title | single-line text box | plain input |
| Year of publishing | number field with up/down (spinner) arrows | 4 digits |
| Genre | dropdown, MULTIPLE selections allowed | at least one required |
| Picture | image picker; shows a preview thumbnail | optional; default icon if none |
| Description | text box that grows taller as you type | optional |
| Favourite | checkbox/toggle | marks the entry (REQ-037 at creation) |

## Layout (low fidelity)

```
+----------------------------------------------------------------+
|  Add novel                                                     |
+----------------------------------------------------------------+
|  Author          [______________________________]              |
|  Polish title    [______________________________]              |
|  Original title  [______________________________]              |
|  Year            [ 1954  ^v ]                                  |
|  Genre           [ Fantasy, Adventure        v ] multi-select  |
|  Picture         [ preview thumbnail ]                         |
|  Description     [                              ]              |
|                  [ grows taller as you type     ]              |
|  Favourite       [x] mark as favourite (asterisk)              |
|                  [ Save ]   [ Cancel ]                         |
+----------------------------------------------------------------+
```
