set_up_board <- function(
  warn = TRUE,
  bucket = Sys.getenv("S3_BUCKET"),
  versioned = TRUE,
  cache = here::here("cache"),
  region = Sys.getenv("S3_REGION"),
  endpoint = Sys.getenv("S3_ENDPOINT"),
  access_key = Sys.getenv("S3_PUB_KEY"),
  secret_access_key = Sys.getenv("S3_PRIV_KEY")
) {
  s3_config_complete <- all(
    nzchar(Sys.getenv("S3_BUCKET")),
    nzchar(Sys.getenv("S3_REGION")),
    nzchar(Sys.getenv("S3_ENDPOINT")),
    nzchar(Sys.getenv("AWS_ACCESS_KEY_ID")),
    nzchar(Sys.getenv("AWS_SECRET_ACCESS_KEY"))
  )
  board <- if (s3_config_complete) {
    pins::board_s3(
      bucket = bucket,
      versioned = versioned,
      cache = cache,
      region = region,
      endpoint = endpoint,
      access_key = access_key,
      secret_access_key = secret_access_key
    )
  } else {
    # fall back to local board if no env. varaibles for S3
    pins::board_folder(here::here("_pins"))
    if (warn == TRUE) {
      warning(
        "S3 configuration incomplete: One or more required environment variables are missing.\n",
        "Required variables: S3_BUCKET, S3_REGION, S3_ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY\n",
        "Targets will use local storage instead of AWS S3.",
        call. = FALSE
      )
    }
  }
  return(board)
}

tar_make_resume_tagged <- function(tag) {
  tag_list <- list(version_tag = tag)
  targets::tar_make(
    envir = list2env(tag_list, parent = globalenv()),
    callr_function = NULL
  )
}

use_resume_data <- function(
  tag,
  name = "resume_data",
  file = here::here("data", "resume_data.csv"),
  ...
) {
  board <- set_up_board(warn = FALSE, ...)
  # list all resume versions
  resume_versions <- pins::pin_versions(board, name)[["version"]]
  meta_list <- lapply(resume_versions, \(x) {
    meta <- pins::pin_meta(board, name, x)
    list(
    pin_hash = meta$pin_hash,
    tags = meta$tags,
    created = meta$created,
    version = meta$local$version)})
  meta_df <- do.call(rbind.data.frame, meta_list)
  # get the newest one with that tag
  pin_version <- meta_df |>
    dplyr::filter(tag == tags) |>
    dplyr::slice_max(order_by = created, n = 1) |>
    dplyr::pull(version)
  # write that version out to the disk
  if (length(pin_version) == 0) {
    stop('No matching pin tags found')
  }
  out <- pins::pin_read(board, name, version = pin_version)
  readr::write_csv(out, file)
}
