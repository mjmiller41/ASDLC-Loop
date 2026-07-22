# Level moves the floors; track moves the ceremony

The system has two rigor dials and they must not overlap. We assign each exactly one job:

- **`level`** (repo-wide, committed) is the *only* dial that moves a **floor**. Lowering safety
  (`prototype`) or raising it (`production`) requires editing a committed file — a visible,
  reviewable act.
- **`track`** (per-task, chosen at Route by blast radius) moves only the **ceremony** — how much
  Frame / Plan / Review the director performs. It may drop all of them for a Quick change but never
  reads or lowers a floor.

Consequence, accepted deliberately: a Quick one-line change still pays the full verify-gate
(lint → types → tests → diff-size) on its finishing turn. A quick careless edit is exactly when a
broken lint/type/test bites, so that is the last place to relax. The honest way to skip the floor is
`level: prototype` or `/asdlc-off` — both visible — never a silent per-task downgrade. This makes the
house rule precise: **track never reads a floor.**
