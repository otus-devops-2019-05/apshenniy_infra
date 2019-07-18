terraform {
  backend "gcs" {
    bucket = "terraform-tfstate"
    prefix = "stage"
  }
}
