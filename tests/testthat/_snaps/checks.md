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

