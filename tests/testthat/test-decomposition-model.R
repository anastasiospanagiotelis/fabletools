context("test-decomposition-model")

test_that("Decomposition modelling", {
  mdl_dcmp <- us_deaths %>%
    model(decomposition_model(feasts::STL, value, fable::NAIVE(seas_adjust)))
  
  expect_output(
    report(mdl_dcmp),
    "Series: seas_adjust \\nModel: NAIVE"
  )
  expect_output(
    report(mdl_dcmp),
    "Series: season_year \\nModel: SNAIVE"
  )
  
  fbl_dcmp <- forecast(mdl_dcmp)
  
  expect_equal(
    fbl_dcmp$value,
    rep(dcmp$season_year[61:72], 2) + dcmp$seas_adjust[72]
  )
})