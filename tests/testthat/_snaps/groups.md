# ysx_regroup validates its inputs

    Code
      ysx_regroup(list(), "ID")
    Condition
      Error in `ysx_regroup()`:
      ! inherits(spec, "yspec") is not TRUE

---

    Code
      ysx_regroup(spec, character())
    Condition
      Error in `ysx_regroup()`:
      ! length(groups) > 0L is not TRUE

---

    Code
      ysx_regroup(spec, c("ID", "NOPE", "ALSO"))
    Condition
      Error:
      ! Group column(s) not found in spec: NOPE, ALSO

# ysx_ungroup validates its input

    Code
      ysx_ungroup(list())
    Condition
      Error in `ysx_ungroup()`:
      ! inherits(spec, "yspec") is not TRUE

# ysx_check_repeats raises on repeats by default

    Code
      ysx_check_repeats(data, spec)
    Condition
      Error:
      ! 1 of 2 group(s) defined by AGE, ID do not have 1 row(s) (row counts found: 2)

---

    Code
      ysx_check_repeats(data, spec, count = 2)
    Condition
      Error:
      ! 1 of 2 group(s) defined by AGE, ID do not have 2 row(s) (row counts found: 1)

# ysx_check_repeats takes groups directly without changing spec

    Code
      ysx_check_repeats(data, spec, groups = "ID")
    Condition
      Error:
      ! 1 of 2 group(s) defined by ID do not have 1 row(s) (row counts found: 2)

---

    Code
      ysx_check_repeats(data, spec, groups = "NOPE")
    Condition
      Error:
      ! Group column(s) not found in spec: NOPE

# ysx_check_repeats treats missing values as group values

    Code
      ysx_check_repeats(data.frame(ID = c(NA, 1, NA)), spec)
    Condition
      Error:
      ! 1 of 2 group(s) defined by ID do not have 1 row(s) (row counts found: 2)

# ysx_check_repeats handles absent and missing group columns

    Code
      ysx_check_repeats(data, spec)
    Condition
      Error:
      ! Group column(s) not found in data: AGE

# ysx_check_repeats validates its inputs

    Code
      ysx_check_repeats(list(), spec)
    Condition
      Error in `check_repeats()`:
      ! is.data.frame(data) is not TRUE

---

    Code
      ysx_check_repeats(data, list())
    Condition
      Error in `check_repeats()`:
      ! inherits(spec, "yspec") is not TRUE

---

    Code
      ysx_check_repeats(data, spec, count = 0)
    Condition
      Error in `check_repeats()`:
      ! count >= 1 is not TRUE

---

    Code
      ysx_check_repeats(data, spec, count = 1.5)
    Condition
      Error in `check_repeats()`:
      ! count == round(count) is not TRUE

---

    Code
      ysx_check_repeats(data, spec, error_on_fail = NA)
    Condition
      Error in `check_repeats()`:
      ! !is.na(error_on_fail) is not TRUE

