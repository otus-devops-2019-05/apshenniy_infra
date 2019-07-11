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

variable privat_key_path {
  description = "Path to the privat key used for ssh access"
}

variable disk_image {
  description = "Disk image"
}

variable zone {
  description = "Resource Terraform"
  default     = "europe-west1-b"
}
