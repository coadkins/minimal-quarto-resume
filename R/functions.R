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