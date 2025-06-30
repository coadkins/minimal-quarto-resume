# source the interactive helpers
source(here::here("R", "helpers.R"))
# Functions for setting up pins and S3
# Functions for loading and uploading raw resume data
## `read_resume_data()` reads resume data with defaults that match the .csv template
read_resume_data <- function(
  file,
  col_types = cols(
    experience_type = "c",
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
  title = paste0(
    quarto::quarto_inspect("minimal_quarto_resume.qmd")$author$firstname,
    "\'s ",
    "Resume Data"
  ),
  description = "Raw data for generating a quarto resume that describes education, skills and work experience",
  tags = ifelse(exists("version_tag", mode = "any"), version_tag, "default")
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
filter_resume_entries <- function(
  data,
  exp_col = experience_type,
  exp_style,
  date_col = date
) {
  filtered_df <- data |>
    dplyr::filter({{ exp_col }} == exp_style)
  if (exp_style == "education" || exp_style == "work") {
    filtered_df <- filtered_df |>
      dplyr::arrange(desc({{ date_col }})) |>
      dplyr::mutate(across(
        where(\(x) class(x) == "Date"),
        \(x) as.character(format(x, "%m/%Y"))
      ))
  }
  return(filtered_df)
}

## 'resume_entry_education()` generates typst code for education entries from a data frame
resume_entry_education <- function(
  data,
  title = "title",
  location = "location",
  date = "date",
  description = "description",
  details = "bullets_parsed"
) {
  # Handle empty data frame
  if (nrow(data) == 0) {
    return(invisible())
  }
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
## 'resume_entry_work` generates typst code for work entries from a data frame
## work entries make use of start and end dates
resume_entry_work <- function(
  data,
  title = "title",
  location = "location",
  start_date = "start",
  end_date = "end",
  description = "description",
  details = "bullets_parsed"
) {
  # Handle empty data frame
  if (nrow(data) == 0) {
    return(invisible())
  }
  strings <- apply(data, 1, function(row) {
    s <- "#resume-entry("
    if (!is.na(row[title])) {
      s <- sprintf("%stitle: \"%s\",", s, row[title])
    }
    if (!is.na(row[location])) {
      s <- sprintf("%slocation: \"%s\",", s, row[location])
    }
    if (!is.na(row[start_date])) {
      s <- sprintf("%sdate: \"%s", s, row[start_date])
    }
    if (!is.na(row[end_date])) {
      s <- sprintf("%s - %s\",", s, row[end_date])
    } else if (!is.na(row[start_date])) {
      s <- sprintf("%s - Present\",", s)
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
## skill entries do not have headings are instead are simple comma seperated lists
resume_entry_skills <- function(
  data,
  title = "title",
  details = "bullets_parsed"
) {  
  # Handle empty data frame
  if (nrow(data) == 0) {
    return(invisible())
  }
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
