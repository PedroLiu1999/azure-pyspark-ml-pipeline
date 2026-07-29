variable "location" {
  type        = string
  default     = "Germany West Central"
  description = "Azure region for resources"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment stage"
}