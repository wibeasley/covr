context("print function")
test_that("format_percentage works as expected", {
  expect_equal(format_percentage(0), crayon::red("0.00%"))

  expect_equal(format_percentage(0.25), crayon::red("25.00%"))

  expect_equal(format_percentage(0.51), crayon::red("51.00%"))

  expect_equal(format_percentage(0.765), crayon::yellow("76.50%"))

  expect_equal(format_percentage(0.865), crayon::yellow("86.50%"))

  expect_equal(format_percentage(0.965), crayon::green("96.50%"))
})

test_that("print.coverage prints by = \"line\" by default", {
  cov <- package_coverage("TestPrint")

  expect_message(print(cov, by = "expression"),
    rex::rex("R", one_of("/", "\\"), "TestPrint.R: ", anything, "66.67%"))

  expect_message(print(cov, by = "line"),
    rex::rex("Test Coverage: ", anything, "100.00%"))

  expect_message(print(cov, by = "line"),
    rex::rex("R", one_of("/", "\\"), "TestPrint.R: ", anything, "100.00%"))

  # test default
  expect_message(print(cov),
    rex::rex("Test Coverage: ", anything, "100.00%"))

  expect_message(print(cov),
    rex::rex("R", one_of("/", "\\"), "TestPrint.R: ", anything, "100.00%"))
})
test_that("print.coverage prints by = \"line\" by default", {
  cov <- package_coverage("TestPrint")

  expect_message(print(cov, group = "functions"),
    rex::rex("test_me", anything, "100.00%"))

  expect_message(print(cov, group = "functions", by = "expression"),
    rex::rex("test_me", anything, "66.67%"))
})
