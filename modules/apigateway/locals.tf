locals {
  name_prefix = var.name

  is_http_api = var.protocol_type == "HTTP" || var.protocol_type == "WEBSOCKET"
  is_rest_api = var.protocol_type == "REST"

  default_tags = {
    ManagedBy = "Terraform"
    Service   = "APIGateway"
  }

  merged_tags = merge(local.default_tags, var.tags)

  api_id = local.is_http_api ? try(aws_apigatewayv2_api.this[0].id, null) : try(aws_api_gateway_rest_api.this[0].id, null)

  stage_name = var.stage_name

  default_log_format = jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    routeKey       = "$context.routeKey"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
    errorMessage   = "$context.error.message"
  })

  log_format = var.access_log_settings != null ? var.access_log_settings.format : local.default_log_format
}
