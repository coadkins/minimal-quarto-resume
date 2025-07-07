# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(here)
library(targets)
library(tarchetypes)

# Set target options:
tar_option_set(
  packages = c(
    # Packages that your targets need for their tasks.
    "dplyr",
    "here",
    "paws.storage",
    "purrr",
    "pins",
    "quarto",
    "readr",
    "stringr"
  )
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source(here("R", "functions.R"))

list(
  tar_target(
    name = resume_file,
    here("data", "resume_data.csv"),
    format = "file"
  ),
  tar_target(
    name = raw_resume_data,
    command = read_resume_data(file = resume_file)
  ),
  tar_target(name = board, command = set_up_board()),
  tar_target(
    name = write_pin_side_effect,
    command = resume_pin_write(board = board, data = raw_resume_data)
  ),
  tar_target(
    name = parsed_resume_data,
    command = parse_bullets(raw_resume_data)
  ),
  tar_target(
    name = education_entries,
    command = filter_resume_entries(parsed_resume_data, 
      exp_style = "education")
  ),
  tar_target(
    name = experience_entries,
    command = filter_resume_entries(
      parsed_resume_data,
      exp_style = "work"
    )
  ),
  tar_target(
    name = skills_entries,
    command = filter_resume_entries(parsed_resume_data, exp_style = "skills")
  ),
  tar_quarto(
    resume_out,
    here("minimal_quarto_resume.qmd"),
    extra_files = here("_quarto.yml"),
    quiet = FALSE
  )
)
