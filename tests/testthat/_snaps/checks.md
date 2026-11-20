# spec columns absent from the data raise unless error_on_fail = FALSE

    Code
      ysx_check_missing(data, yspec::ys_select(spec, SEX, CVA1, AGE, ID))
    Condition
      Error:
      ! Specification column(s) not found in data: AGE, ID

# ysx_check_missing validates inputs and na_ok settings

    Code
      ysx_check_missing(list(), spec)
    Condition
      Error in `ysx_check_missing()`:
      ! is.data.frame(data) is not TRUE

---

    Code
      ysx_check_missing(data, list())
    Condition
      Error in `ysx_check_missing()`:
      ! inherits(spec, "yspec") is not TRUE

---

    Code
      ysx_check_missing(data, spec)
    Condition
      Error:
      ! SEX: dots$na_ok must be true or false.

---

    Code
      ysx_check_missing(data, spec, list())
    Condition
      Error in `ysx_check_missing()`:
      ! is.null(spec2) || inherits(spec2, "yspec") is not TRUE

---

    Code
      ysx_check_missing(data, spec, error_on_fail = NA)
    Condition
      Error in `ysx_check_missing()`:
      ! !is.na(error_on_fail) is not TRUE

# pre_grp_count accepts yaml null and None and is validated

    Code
      ysx_check(data, spec)
    Message
      The data set passed all checks.
    Condition
      Error:
      ! USUBJID: dots$pre_grp_count must be a positive whole number, null or None.

---

    Code
      ysx_check(data, spec)
    Message
      The data set passed all checks.
    Condition
      Error:
      ! USUBJID: dots$pre_grp_count must be a positive whole number, null or None.

---

    Code
      ysx_check(data, spec)
    Message
      The data set passed all checks.
    Condition
      Error:
      ! Group columns have conflicting dots$pre_grp_count settings: USUBJID, ID

