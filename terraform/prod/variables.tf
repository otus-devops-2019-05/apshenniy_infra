variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the public key used for ssh access"
}

variable app_disk_image {
  description = "Disk image"
}

variable db_disk_image {
  description = "Disk image"
}

variable zone {
  description = "google compute instance zone"
  default     = "europe-west1-b"
}
