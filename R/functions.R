resume_entry_skills <- function(data,
                         title = "title",
                         details = "bullets_parsed") {
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
  cat(paste0("```{=typst}\n", "#skills-entry((\n", 
  paste(strings, collapse = "\n"), "\n))", "\n```"))
}

resume_entry_edu <- function(data,
    title = "title",
    location = "location",
    date = "date",
    description = "description",
    details = "bullets_parsed"){
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
      t <- paste0(t, collapse="\n")
    }
     t <- paste0("#resume-item((", t, "))")
     s <- paste(s, t, sep = "\n") 
    return(s)
  })
  cat(paste0("```{=typst}\n", paste(strings, collapse = "\n"), "\n```"))
}

  parse_bullets <- function(df, bullet_col = "bullets", output_col = "bullets_parsed") {
  df |>
    dplyr::mutate(
      !!output_col := map(.data[[bullet_col]], \(x) {
        items <- strsplit(x, "\n")
        items <- sapply(items, \(x) gsub("^\\s*-\\s*", "", x), 
                       USE.NAMES = FALSE)
        items <- sapply(items, trimws, USE.NAMES = FALSE)
        items <- items[items != ""]
        return(items)
      })
    )
  }