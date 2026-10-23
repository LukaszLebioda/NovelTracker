# Novel form — UI note (low fidelity)

**Status:** draft for review
**Date:** 2026-10-23
**Screen goal:** Add or edit one novel entry.
**Actor:** signed-in reader
**Linked rules:** REQ-001…REQ-012 (create), REQ-026…REQ-028 (edit)

> Visual/layout only — NOT the behavioural source of truth.
> Behaviour lives in `spec/features/novels/*.feature`.

## Fields

| Field | Control | Notes |
|---|---|---|
| Author | single-line text box | plain input |
| Polish title | single-line text box | plain input |
| Original title | single-line text box | plain input |
| Year of publishing | number field with up/down (spinner) arrows | 4 digits |
| Genre | dropdown, MULTIPLE selections allowed | at least one required |
| Picture | image picker; shows a preview thumbnail | optional; default icon if none; the larger-view-on-click behaviour (REQ-036) belongs to the list, not this form |
| Description | text box that grows taller as you type | optional |
| Favourite | checkbox/toggle | marks the entry with an asterisk (REQ-034 on edit; REQ-037 at creation) |

## Layout (low fidelity)

```
+----------------------------------------------------------------+
|  Add / Edit novel                                              |
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
|                  [ Save ]   [ Cancel ]  (Cancel = navigation,   |
|                                          no behavioural rule)   |
+----------------------------------------------------------------+
```
