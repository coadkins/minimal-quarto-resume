pacman::p_load("here", "pins", "readr")
board <- board_s3(
  bucket = Sys.getenv("S3_BUCKET"),
  versioned = TRUE,
  cache = here("cache"),
  region = Sys.getenv("S3_REGION"),
  endpoint = Sys.getenv("S3_ENDPOINT"),
  access_key = Sys.getenv("S3_PUB_KEY"),
  secret_access_key = Sys.getenv("S3_PRIV_KEY")
)

df <- read_csv(here("data", "resume_data.csv"),
              col_types = cols(exp_type = "c", 
              title = "c", location = "c", date = "D", 
              start = "D", end = "D", bullets = "c"))
pin_write(
  board,
  df,
  name = "resume_data",
  type = "parquet",
  title = "Corys Resume Data",
  description = "Raw data for generating a quarto resume that describes education, skills and work experience",
  tags = "default"
)
