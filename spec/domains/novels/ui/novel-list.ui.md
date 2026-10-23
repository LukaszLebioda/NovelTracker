# Novel list — UI note (low fidelity)

**Status:** draft for review
**Date:** 2026-10-23
**Screen goal:** Browse, filter, and act on the reader's own novels.
**Actor:** signed-in reader
**Linked rules:** REQ-013…REQ-025, REQ-031, REQ-034, REQ-035, REQ-036

> Visual/layout only — NOT the behavioural source of truth.
> Behaviour lives in `spec/features/novels/*.feature`.

## Elements

| Element | Behaviour (rule) |
|---|---|
| Filter bar | filter by author surname, Polish title, or year (REQ-015/016/017) |
| Favourites filter | toggle to show only asterisk-marked novels (REQ-035) |
| Each row | picture thumbnail (click → larger view, REQ-036), both titles, year, genre(s), asterisk if favourite, description preview + "See more" (REQ-020/021) |
| Row actions | Edit (REQ-026), Delete (REQ-031) |

## Layout (low fidelity)

```
+----------------------------------------------------------------+
|  My novels        [ filter: author/title/year ]  [* favourites ]|
+----------------------------------------------------------------+
| [img] Władca Pierścieni           1954  Fantasy        * |E|D|  |
|       The Lord of the Rings                                    |
|       An epic high fantasy adv... [See more]                   |
+----------------------------------------------------------------+
| [img] Solaris                     1961  Sci-Fi           |E|D|  |
|       no description yet                                       |
+----------------------------------------------------------------+
```
