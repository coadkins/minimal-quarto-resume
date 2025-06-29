# Functions for setting up pins and S3
set_up_board <- function() {
  s3_config_complete <- all(
    nzchar(Sys.getenv("S3_BUCKET")),
    nzchar(Sys.getenv("S3_REGION")),
    nzchar(Sys.getenv("S3_ENDPOINT")),
    nzchar(Sys.getenv("AWS_ACCESS_KEY_ID")),
    nzchar(Sys.getenv("AWS_SECRET_ACCESS_KEY"))
  )
board <- if(s3_config_complete) {  
  pins::board_s3(
  bucket = Sys.getenv("S3_BUCKET"),
  versioned = TRUE,
  cache = here("cache"),
  region = Sys.getenv("S3_REGION"),
  endpoint = Sys.getenv("S3_ENDPOINT"),
  access_key = Sys.getenv("S3_PUB_KEY"),
  secret_access_key = Sys.getenv("S3_PRIV_KEY"))
} else {
  # fall back to local board if no env. varaibles for S3
  pins::board_folder(here("_pins"))
  warning("S3 configuration incomplete: One or more required environment variables are missing.\n",
          "Required variables: S3_BUCKET, S3_REGION, S3_ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY\n",
          "Targets will use local storage instead of AWS S3.",
          call. = FALSE)
} 
  return(board)
}

# Functions for loading and uploading raw resume data
## `read_resume_data()` reads resume data with defaults that match the .csv template
read_resume_data <- function(
  file,
  col_types = cols(
    exp_type = "c",
    title = "c",
    location = "c",
    date = "D",
    start = "D",
    end = "D",
    bullets = "c"
  )
) {
  out <- readr::read_csv(file = file, col_types = col_types)
  return(out)
}
## `resume_pin_write()` writes the pins with preferred defaults for this project
resume_pin_write <- function(
  board = board,
  data,
  name = "resume_data",
  type = "csv",
  title = "Corys Resume Data",
  description = "Raw data for generating a quarto resume that describes education, skills and work experience",
  tags = version_tag 
) {
  pins::pin_write(
    board = board,
    x = data,
    name = name,
    type = type,
    title = title,
    description = description,
    tags = tags
  )
  return(name)
}

# Functions for creating resume entries
## `parse_bullets()` transforms lists of resume item details into a usable format
parse_bullets <- function(
  df,
  bullet_col = "bullets",
  output_col = "bullets_parsed"
) {
  df |>
    dplyr::mutate(
      !!output_col := purrr::map(.data[[bullet_col]], \(x) {
        items <- strsplit(x, "\n")
        items <- sapply(
          items,
          \(x) gsub("^\\s*-\\s*", "", x),
          USE.NAMES = FALSE
        )
        items <- sapply(items, trimws, USE.NAMES = FALSE)
        items <- items[items != ""]
        return(items)
      })
    )
}

## `filter_resume_entries`
filter_resume_entries <- function(data, 
  exp_col = exp_type, exp_style, 
  date_col = date) {
filtered_df <- data |>
  dplyr::filter({{ exp_col }} == exp_style)
if (exp_style == "education" || exp_style == "work") {
  filtered_df <- filtered_df |>
    dplyr::arrange(desc({{ date_col }})) |>
    dplyr::mutate(date = as.character({{ date_col }}))
  } 
return(filtered_df)
}

## 'resume_entry_default()` generates typst code for education and experience entries from a data frame
resume_entry_default <- function(
  data,
  title = "title",
  location = "location",
  date = "date",
  description = "description",
  details = "bullets_parsed"
) {
  strings <- apply(data, 1, function(row) {
    s <- "#resume-entry("
    if (!is.na(row[title])) {
      s <- sprintf("%stitle: \"%s\",", s, row[title])
    }
    if (!is.na(row[location])) {
      s <- sprintf("%slocation: \"%s\",", s, row[location])
    }
    if (!is.na(row[date])) {
      s <- sprintf("%sdate: \"%s\",", s, row[date])
    }
    if (!is.na(row[description])) {
      s <- sprintf("%sdescription: \"%s\",", s, row[description])
    }
    s <- paste0(s, ")")

    if (!is.na(row[details])) {
      t <- sapply(row[details], \(x) {
        sprintf("[%s],", x)
      })
      t <- paste0(t, collapse = "\n")
    }
    t <- paste0("#resume-item((", t, "))")
    s <- paste(s, t, sep = "\n")
    return(s)
  })
  cat(paste0("```{=typst}\n", paste(strings, collapse = "\n"), "\n```"))
}

## `resume_entry_skills()` generates typst code for skill listings from a data frame of resume items
resume_entry_skills <- function(
  data,
  title = "title",
  details = "bullets_parsed"
) {
  strings <- apply(data, 1, function(row) {
    if (!is.na(row[title])) {
      s <- sprintf("(\"%s\", (", row[title])
    }
    if (!is.na(row[details])) {
      t <- sapply(row[details], \(x) {
        sprintf("[%s],", x)
      })
      t <- c(t, ")),")
      t <- paste0(t, collapse = "\n")
    }
    s <- paste(s, t, sep = "\n")
    return(s)
  })
  cat(paste0(
    "```{=typst}\n",
    "#skills-entry((\n",
    paste(strings, collapse = "\n"),
    "\n))",
    "\n```"
  ))
}
