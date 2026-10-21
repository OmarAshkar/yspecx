# field validation applies only to used variables without overrides

    Code
      ys_plt_relab(plot, spec, label_type = "long")
    Condition
      Error:
      ! Field 'long' is unavailable for variable 'AGE'.

---

    Code
      ys_plt_relab(plot, spec, label_type = "long")
    Condition
      Error:
      ! Field 'long' is unavailable for variable 'AGE'.

---

    Code
      ys_plt_relab(plot, spec, var_map = c(AGE = "UNKNOWN"))
    Condition
      Error:
      ! Every var_map target must name a variable in spec.

---

    Code
      ys_plt_relab(plot, spec, label_type = "other")
    Condition
      Error in `match.arg()`:
      ! 'arg' should be one of "long", "short"

