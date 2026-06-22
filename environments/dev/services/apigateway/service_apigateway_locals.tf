locals {
  api_name_prefix = "${var.environment}-${var.api_name}"

  service_tags = merge(
    {
      Environment = var.environment
      Owner       = var.owner
      Service     = "apigateway"
    },
    var.additional_tags
  )

  log_group_name = "/aws/apigateway/${local.api_name_prefix}"

  access_log_format = jsonencode({
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

  authorizer_config = var.authorizer_type != "NONE" ? {
    name             = "${var.api_name}-authorizer"
    authorizer_type  = var.authorizer_type
    identity_sources = ["$request.header.Authorization"]
    jwt_configuration = var.authorizer_type == "JWT" ? {
      audience = var.jwt_audience
      issuer   = var.jwt_issuer
    } : null
  } : null
}
