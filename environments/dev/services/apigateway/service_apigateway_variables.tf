variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "dev-apigateway"
}

variable "api_protocol_type" {
  description = "Protocol type for the API (HTTP, REST, or WEBSOCKET)"
  type        = string
  default     = "HTTP"
}

variable "api_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "dev"
}

variable "enable_access_logging" {
  description = "Enable CloudWatch access logging"
  type        = bool
  default     = true
}

variable "enable_throttling" {
  description = "Enable throttling on the API stage"
  type        = bool
  default     = true
}

variable "throttle_burst_limit" {
  description = "Throttle burst limit"
  type        = number
  default     = 500
}

variable "throttle_rate_limit" {
  description = "Throttle rate limit (requests per second)"
  type        = number
  default     = 1000
}

variable "authorizer_type" {
  description = "Type of authorizer (JWT, LAMBDA, or NONE)"
  type        = string
  default     = "JWT"
}

variable "jwt_issuer" {
  description = "JWT issuer URL for JWT authorizer"
  type        = string
  default     = ""
}

variable "jwt_audience" {
  description = "JWT audience for JWT authorizer"
  type        = list(string)
  default     = []
}

variable "integration_configs" {
  description = "Map of integration configurations"
  type = map(object({
    integration_type   = string
    integration_uri    = string
    integration_method = optional(string, "POST")
  }))
  default = {}
}

variable "enable_xray" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "platform-team"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
