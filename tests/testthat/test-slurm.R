test_that("slurm_apply returns rslurm_job", {
  f <- function(x) x
  p <- data.frame(x = 1:5)
  slurm_job <- slurm_apply(f, p, "simple_test")
  expect_is(slurm_job, "slurm_job")
})
