# ys_write rejects non-spec inputs and non-YAML paths

    Code
      ys_write(list(), "spec.yaml")
    Condition
      Error in `ys_write()`:
      ! inherits(x, "yspec") is not TRUE

---

    Code
      ys_write(spec, "spec.txt")
    Condition
      Error in `ys_write()`:
      ! grepl("\\.yaml$", path) is not TRUE

