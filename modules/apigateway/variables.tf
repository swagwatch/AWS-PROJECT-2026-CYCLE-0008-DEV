variable "name" {
  description = "Name of the API Gateway"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "API Gateway name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "protocol_type" {
  description = "Protocol type for the API Gateway (HTTP, REST, or WEBSOCKET)"
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "REST", "WEBSOCKET"], var.protocol_type)
    error_message = "Protocol type must be one of: HTTP, REST, WEBSOCKET."
  }
}

variable "api_key_selection_expression" {
  description = "An API key selection expression. Valid values: $context.authorizer.usageIdentifierKey, $request.header.x-api-key"
  type        = string
  default     = "$request.header.x-api-key"
}

variable "route_selection_expression" {
  description = "The route selection expression for the API"
  type        = string
  default     = "$request.method $request.path"
}

variable "cors_configuration" {
  description = "CORS configuration for the API"
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["*"])
    allow_origins     = optional(list(string), ["*"])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 0)
  })
  default = null
}

variable "disable_execute_api_endpoint" {
  description = "Whether clients can invoke the API using the default execute-api endpoint"
  type        = bool
  default     = false
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "$default"
}

variable "stage_auto_deploy" {
  description = "Whether updates to the API automatically trigger a new deployment"
  type        = bool
  default     = true
}

variable "stage_throttle_settings" {
  description = "Throttle settings for the API stage"
  type = object({
    burst_limit = number
    rate_limit  = number
  })
  default = null
}

variable "access_log_settings" {
  description = "Settings for logging access information"
  type = object({
    destination_arn = string
    format          = string
  })
  default = null
}

variable "route_settings" {
  description = "Route settings for the API stage"
  type = map(object({
    detailed_metrics_enabled = optional(bool, false)
    logging_level            = optional(string, "OFF")
    data_trace_enabled       = optional(bool, false)
    throttling_burst_limit   = optional(number)
    throttling_rate_limit    = optional(number)
  }))
  default = {}
}

variable "authorizer_config" {
  description = "Configuration for API Gateway authorizer"
  type = object({
    name                             = optional(string, "default-authorizer")
    authorizer_type                  = string
    authorizer_uri                   = optional(string)
    authorizer_credentials_arn       = optional(string)
    authorizer_result_ttl_in_seconds = optional(number, 300)
    identity_sources                 = optional(list(string), [])
    jwt_configuration = optional(object({
      audience = list(string)
      issuer   = string
    }))
    authorizer_payload_format_version = optional(string, "2.0")
    enable_simple_responses           = optional(bool, false)
  })
  default = null
}

variable "integration_configs" {
  description = "Map of integration configurations keyed by route (e.g., 'GET /users')"
  type = map(object({
    integration_type       = string
    integration_uri        = optional(string)
    integration_method     = optional(string)
    connection_type        = optional(string, "INTERNET")
    connection_id          = optional(string)
    payload_format_version = optional(string, "2.0")
    timeout_milliseconds   = optional(number, 30000)
    request_parameters     = optional(map(string), {})
    request_templates      = optional(map(string), {})
    response_parameters    = optional(map(string), {})
    passthrough_behavior   = optional(string)
    credentials_arn        = optional(string)
  }))
  default = {}
}

variable "vpc_link_config" {
  description = "Configuration for VPC Link (for private integrations)"
  type = object({
    name               = string
    security_group_ids = list(string)
    subnet_ids         = list(string)
  })
  default = null
}

variable "domain_name_config" {
  description = "Custom domain name configuration"
  type = object({
    domain_name     = string
    certificate_arn = string
    endpoint_type   = optional(string, "REGIONAL")
    security_policy = optional(string, "TLS_1_2")
  })
  default = null
}

variable "api_mapping_config" {
  description = "API mapping configuration for custom domain"
  type = object({
    api_mapping_key = optional(string)
    stage           = optional(string)
  })
  default = null
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "enable_xray_tracing" {
  description = "Whether to enable X-Ray tracing for the API stage"
  type        = bool
  default     = false
}

variable "api_key_required" {
  description = "Whether an API key is required for routes"
  type        = bool
  default     = false
}

variable "rest_api_minimum_compression_size" {
  description = "Minimum response size to compress for REST API (bytes, -1 to disable)"
  type        = number
  default     = -1
}

variable "rest_api_endpoint_configuration" {
  description = "Endpoint configuration for REST API"
  type = object({
    types            = list(string)
    vpc_endpoint_ids = optional(list(string), [])
  })
  default = {
    types = ["REGIONAL"]
  }
}

variable "rest_api_policy" {
  description = "JSON formatted policy document for REST API"
  type        = string
  default     = null
}
