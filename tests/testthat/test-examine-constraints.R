nyc_check <- tibble::tribble(
  ~table, ~kind, ~columns, ~ref_table, ~is_key, ~problem,
  "flights", "FK", "dest", "airports", FALSE, "<reason>",
  "flights", "FK", "tailnum", "planes", FALSE, "<reason>",
  "airlines", "PK", "carrier", NA, TRUE, "",
  "airports", "PK", "faa", NA, TRUE, "",
  "planes", "PK", "tailnum", NA, TRUE, "",
  "flights", "FK", "carrier", "airlines", TRUE, "",
) %>%
  mutate(columns = new_keys(columns)) %>%
  new_dm_examine_constraints()

test_that("`dm_examine_constraints()` works", {

  # case of no constraints:
  expect_identical(
    dm_examine_constraints(dm_test_obj()),
    tibble(
      table = character(0),
      kind = character(0),
      columns = new_keys(character()),
      ref_table = character(0),
      is_key = logical(0),
      problem = character(0)
    ) %>%
      new_dm_examine_constraints()
  )

  skip_if_src("maria")

  # case of some constraints, all met:
  expect_identical(
    dm_examine_constraints(dm_for_disambiguate()),
    tibble(
      table = c("iris_1", "iris_2"),
      kind = c("PK", "FK"),
      columns = new_keys("key"),
      ref_table = c(NA, "iris_1"),
      is_key = TRUE,
      problem = ""
    ) %>%
      new_dm_examine_constraints()
  )

  skip_if_src("postgres")
  skip_if_not_installed("nycflights13")

  # case of some constraints, some violated:
  expect_identical(
    dm_examine_constraints(dm_nycflights_small()) %>%
      mutate(problem = if_else(problem == "", "", "<reason>")),
    nyc_check
  )
})

test_that("output", {
  skip_if_not_installed("nycflights13")

  expect_snapshot({
    dm() %>% dm_examine_constraints()

    dm_nycflights13() %>% dm_examine_constraints()
    dm_nycflights13(cycle = TRUE) %>% dm_examine_constraints()
    dm_nycflights13(cycle = TRUE) %>%
      dm_select_tbl(-flights) %>%
      dm_examine_constraints()

    "n column"
    dm_for_filter_w_cycle() %>%
      dm_examine_constraints()
  })
})

test_that("output as tibble", {
  skip_if_not_installed("nycflights13")

  expect_snapshot({
    dm_nycflights13(cycle = TRUE) %>%
      dm_examine_constraints() %>%
      as_tibble()
  })
})
