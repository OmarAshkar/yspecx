# a yspec change does not stop yspecx from loading

    Code
      local({
        testthat::local_mocked_bindings(extend_yspec_setup_names = function(keys)
          stop("binding not found"), .package = "yspecx")
        .onLoad("lib", "yspecx")
      })
    Condition
      Warning:
      yspecx could not register 'missing_code' with yspec (binding not found). yspec may warn about it in SETUP__.

