# invalid order settings fail only for converted columns

    Code
      ysx_factors(data, spec, BIGGEST)
    Condition
      Error:
      ! Variable 'BIGGEST': dots$order must be 'first' or 'biggest'.

---

    Code
      ysx_factors(data, spec, BIGGEST)
    Condition
      Error:
      ! Variable 'BIGGEST': dots$order must be 'first' or 'biggest'.

---

    Code
      ysx_factors(data, spec, BIGGEST)
    Condition
      Error:
      ! Variable 'BIGGEST': dots$order must be 'first' or 'biggest'.

---

    Code
      ysx_factors(data, spec, BIGGEST)
    Condition
      Error:
      ! Variable 'BIGGEST': dots$order must be 'first' or 'biggest'.

# values outside the specification warn when they become NA

    Code
      result <- ysx_factors(data, spec)
    Condition
      Warning:
      Variable 'FIRST': 2 value(s) not in the specification became NA: 9, 8

---

    Code
      invisible(ysx_factors(many, spec))
    Condition
      Warning:
      Variable 'FIRST': 10 value(s) not in the specification became NA: 11, 12, 13, 14, 15, ...

