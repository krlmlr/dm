test_that("dm_rows_insert()", {
  skip_if_not_installed("nycflights13")
  skip_if_not_installed("RSQLite")
  scoped_options(lifecycle_verbosity = "quiet")

  expect_snapshot({
    # Entire dataset with all dimension tables populated
    # with flights and weather data truncated:
    flights_init <-
      dm_nycflights13() %>%
      dm_zoom_to(flights) %>%
      filter(FALSE) %>%
      dm_update_zoomed() %>%
      dm_zoom_to(weather) %>%
      filter(FALSE) %>%
      dm_update_zoomed()

    sqlite <- dbConnect(RSQLite::SQLite())

    # Target database:
    flights_sqlite <- copy_dm_to(sqlite, flights_init, temporary = FALSE)
    print(dm_nrow(flights_sqlite))

    # First update:
    flights_jan <-
      dm_nycflights13() %>%
      dm_select_tbl(flights, weather) %>%
      dm_zoom_to(flights) %>%
      filter(month == 1) %>%
      dm_update_zoomed() %>%
      dm_zoom_to(weather) %>%
      filter(month == 1) %>%
      dm_update_zoomed()
    print(dm_nrow(flights_jan))

    # Copy to temporary tables on the target database:
    flights_jan_sqlite <- copy_dm_to(sqlite, flights_jan)

    # Dry run by default:
    out <- dm_rows_insert(flights_sqlite, flights_jan_sqlite)
    print(dm_nrow(flights_sqlite))

    # Explicitly request persistence:
    dm_rows_insert(flights_sqlite, flights_jan_sqlite, in_place = TRUE)
    print(dm_nrow(flights_sqlite))

    # Second update:
    flights_feb <-
      dm_nycflights13() %>%
      dm_select_tbl(flights, weather) %>%
      dm_zoom_to(flights) %>%
      filter(month == 2) %>%
      dm_update_zoomed() %>%
      dm_zoom_to(weather) %>%
      filter(month == 2) %>%
      dm_update_zoomed()

    # Copy to temporary tables on the target database:
    flights_feb_sqlite <- copy_dm_to(sqlite, flights_feb)

    # Explicit dry run:
    flights_new <- dm_rows_insert(
      flights_sqlite,
      flights_feb_sqlite,
      in_place = FALSE
    )
    print(dm_nrow(flights_new))
    print(dm_nrow(flights_sqlite))

    # Check for consistency before applying:
    flights_new %>%
      dm_examine_constraints()

    # Apply:
    dm_rows_insert(flights_sqlite, flights_feb_sqlite, in_place = TRUE)
    print(dm_nrow(flights_sqlite))
  })
})

test_that("dm_rows_update()", {
  skip_if_local_src()
  expect_snapshot({
    # Test bad column order
    dm_filter_rearranged <-
      dm_for_filter() %>%
      dm_select(tf_2, d, everything()) %>%
      dm_select(tf_4, i, everything()) %>%
      dm_select(tf_5, l, m, everything())

    suppressMessages(dm_copy <- copy_dm_to(my_test_src(), dm_filter_rearranged))

    dm_update_local <- dm(
      tf_1 = tibble(
        a = 2L,
        b = "q"
      ),
      tf_2 = tibble(
        c = c("worm"),
        d = 10L,
      ),
      tf_4 = tibble(
        h = "e",
        i = "sieben",
      ),
      tf_5 = tibble(
        k = 3L,
        m = "tree",
      ),
    )

    dm_update_copy <- suppressMessages(copy_dm_to(my_test_src(), dm_update_local))

    dm_copy %>%
      pull_tbl(tf_2) %>%
      arrange_all()

    dm_copy %>%
      dm_rows_update(dm_update_copy) %>%
      pull_tbl(tf_2) %>%
      arrange_all()

    dm_copy %>%
      pull_tbl(tf_2) %>%
      arrange_all()

    dm_copy %>%
      dm_rows_update(dm_update_copy, in_place = FALSE) %>%
      pull_tbl(tf_2) %>%
      arrange_all()

    dm_copy %>%
      dm_get_tables() %>%
      map(arrange_all)

    dm_copy %>%
      dm_rows_update(dm_update_copy, in_place = TRUE)

    dm_copy %>%
      dm_get_tables() %>%
      map(arrange_all)
  })
})

test_that("dm_rows_truncate()", {
  skip_if_local_src()

  expect_snapshot({
    suppressMessages(dm_copy <- copy_dm_to(my_test_src(), dm_for_filter()))

    dm_truncate_local <- dm(
      tf_2 = tibble(
        c = c("worm"),
        d = 10L,
      ),
      tf_5 = tibble(
        k = 3L,
        m = "tree",
      ),
    )

    dm_truncate_copy <- suppressMessages(copy_dm_to(my_test_src(), dm_truncate_local))

    dm_copy %>%
      pull_tbl(tf_2) %>%
      arrange_all()

    dm_copy %>%
      dm_rows_truncate(dm_truncate_copy) %>%
      pull_tbl(tf_2) %>%
      arrange_all()

    dm_copy %>%
      pull_tbl(tf_2) %>%
      arrange_all()

    dm_copy %>%
      dm_rows_truncate(dm_truncate_copy, in_place = FALSE) %>%
      pull_tbl(tf_2) %>%
      arrange_all()

    dm_copy %>%
      dm_get_tables() %>%
      map(arrange_all)

    dm_copy %>%
      dm_rows_truncate(dm_truncate_copy, in_place = TRUE)

    dm_copy %>%
      dm_get_tables() %>%
      map(arrange_all)
  })
})
