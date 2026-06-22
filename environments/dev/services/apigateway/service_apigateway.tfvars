api_name          = "app-api"
api_protocol_type = "HTTP"
api_stage_name    = "dev"

enable_access_logging = true
enable_throttling     = true
throttle_burst_limit  = 500
throttle_rate_limit   = 1000

authorizer_type = "JWT"
jwt_issuer      = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example"
jwt_audience    = ["api-client-id"]

integration_configs = {
  "GET /api/health" = {
    integration_type   = "HTTP_PROXY"
    integration_uri    = "https://backend.example.com/health"
    integration_method = "GET"
  }
  "GET /api/users" = {
    integration_type   = "HTTP_PROXY"
    integration_uri    = "https://backend.example.com/users"
    integration_method = "GET"
  }
  "POST /api/users" = {
    integration_type   = "HTTP_PROXY"
    integration_uri    = "https://backend.example.com/users"
    integration_method = "POST"
  }
}

enable_xray = true

environment = "dev"
owner       = "platform-team"

additional_tags = {
  Project    = "api-platform"
  CostCenter = "engineering"
  ManagedBy  = "Terraform"
}
