# CloudWatch Log Group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  count             = var.access_log_settings != null ? 1 : 0
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = 30
  tags              = local.merged_tags
}

# HTTP API (API Gateway v2)
resource "aws_apigatewayv2_api" "this" {
  count = local.is_http_api ? 1 : 0

  name                         = local.name_prefix
  description                  = var.description
  protocol_type                = var.protocol_type
  api_key_selection_expression = var.api_key_selection_expression
  route_selection_expression   = var.route_selection_expression
  disable_execute_api_endpoint = var.disable_execute_api_endpoint

  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []
    content {
      allow_credentials = cors_configuration.value.allow_credentials
      allow_headers     = cors_configuration.value.allow_headers
      allow_methods     = cors_configuration.value.allow_methods
      allow_origins     = cors_configuration.value.allow_origins
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
    }
  }

  tags = local.merged_tags
}

# REST API (API Gateway v1)
resource "aws_api_gateway_rest_api" "this" {
  count = local.is_rest_api ? 1 : 0

  name                         = local.name_prefix
  description                  = var.description
  api_key_source               = var.api_key_selection_expression
  minimum_compression_size     = var.rest_api_minimum_compression_size
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  policy                       = var.rest_api_policy

  endpoint_configuration {
    types            = var.rest_api_endpoint_configuration.types
    vpc_endpoint_ids = var.rest_api_endpoint_configuration.vpc_endpoint_ids
  }

  tags = local.merged_tags
}

# API Gateway Stage (HTTP/WebSocket APIs)
resource "aws_apigatewayv2_stage" "this" {
  count = local.is_http_api ? 1 : 0

  api_id      = aws_apigatewayv2_api.this[0].id
  name        = local.stage_name
  auto_deploy = var.stage_auto_deploy

  dynamic "access_log_settings" {
    for_each = var.access_log_settings != null ? [var.access_log_settings] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
      format          = local.log_format
    }
  }

  dynamic "default_route_settings" {
    for_each = var.stage_throttle_settings != null ? [var.stage_throttle_settings] : []
    content {
      throttling_burst_limit = default_route_settings.value.burst_limit
      throttling_rate_limit  = default_route_settings.value.rate_limit
    }
  }

  dynamic "route_settings" {
    for_each = var.route_settings
    content {
      route_key                = route_settings.key
      detailed_metrics_enabled = route_settings.value.detailed_metrics_enabled
      logging_level            = route_settings.value.logging_level
      data_trace_enabled       = route_settings.value.data_trace_enabled
      throttling_burst_limit   = route_settings.value.throttling_burst_limit
      throttling_rate_limit    = route_settings.value.throttling_rate_limit
    }
  }

  tags = local.merged_tags

  depends_on = [aws_cloudwatch_log_group.api_gateway]
}

# REST API Stage
resource "aws_api_gateway_stage" "this" {
  count = local.is_rest_api ? 1 : 0

  deployment_id        = aws_api_gateway_deployment.this[0].id
  rest_api_id          = aws_api_gateway_rest_api.this[0].id
  stage_name           = local.stage_name
  xray_tracing_enabled = var.enable_xray_tracing

  dynamic "access_log_settings" {
    for_each = var.access_log_settings != null ? [var.access_log_settings] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
      format          = local.log_format
    }
  }

  tags = local.merged_tags

  depends_on = [aws_cloudwatch_log_group.api_gateway]
}

# REST API Deployment
resource "aws_api_gateway_deployment" "this" {
  count = local.is_rest_api ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.this[0].id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this[0]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# VPC Link for private integrations
resource "aws_apigatewayv2_vpc_link" "this" {
  count = var.vpc_link_config != null && local.is_http_api ? 1 : 0

  name               = var.vpc_link_config.name
  security_group_ids = var.vpc_link_config.security_group_ids
  subnet_ids         = var.vpc_link_config.subnet_ids

  tags = local.merged_tags
}

# Authorizer (HTTP APIs)
resource "aws_apigatewayv2_authorizer" "this" {
  count = var.authorizer_config != null && local.is_http_api ? 1 : 0

  api_id           = aws_apigatewayv2_api.this[0].id
  authorizer_type  = var.authorizer_config.authorizer_type
  name             = var.authorizer_config.name
  authorizer_uri   = var.authorizer_config.authorizer_uri
  identity_sources = var.authorizer_config.identity_sources

  authorizer_credentials_arn        = var.authorizer_config.authorizer_credentials_arn
  authorizer_result_ttl_in_seconds  = var.authorizer_config.authorizer_result_ttl_in_seconds
  authorizer_payload_format_version = var.authorizer_config.authorizer_payload_format_version
  enable_simple_responses           = var.authorizer_config.enable_simple_responses

  dynamic "jwt_configuration" {
    for_each = var.authorizer_config.jwt_configuration != null ? [var.authorizer_config.jwt_configuration] : []
    content {
      audience = jwt_configuration.value.audience
      issuer   = jwt_configuration.value.issuer
    }
  }
}

# Integrations (HTTP APIs)
resource "aws_apigatewayv2_integration" "this" {
  for_each = local.is_http_api ? var.integration_configs : {}

  api_id             = aws_apigatewayv2_api.this[0].id
  integration_type   = each.value.integration_type
  integration_uri    = each.value.integration_uri
  integration_method = each.value.integration_method

  connection_type        = each.value.connection_type
  connection_id          = each.value.connection_id != null ? each.value.connection_id : (each.value.connection_type == "VPC_LINK" && var.vpc_link_config != null ? aws_apigatewayv2_vpc_link.this[0].id : null)
  payload_format_version = each.value.payload_format_version
  timeout_milliseconds   = each.value.timeout_milliseconds
  request_parameters     = each.value.request_parameters
  passthrough_behavior   = each.value.passthrough_behavior
  credentials_arn        = each.value.credentials_arn
}

# Routes (HTTP APIs)
resource "aws_apigatewayv2_route" "this" {
  for_each = local.is_http_api ? var.integration_configs : {}

  api_id    = aws_apigatewayv2_api.this[0].id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"

  authorization_type = var.authorizer_config != null ? var.authorizer_config.authorizer_type : "NONE"
  authorizer_id      = var.authorizer_config != null ? aws_apigatewayv2_authorizer.this[0].id : null
  api_key_required   = var.api_key_required
}

# Custom Domain Name
resource "aws_apigatewayv2_domain_name" "this" {
  count = var.domain_name_config != null && local.is_http_api ? 1 : 0

  domain_name = var.domain_name_config.domain_name

  domain_name_configuration {
    certificate_arn = var.domain_name_config.certificate_arn
    endpoint_type   = var.domain_name_config.endpoint_type
    security_policy = var.domain_name_config.security_policy
  }

  tags = local.merged_tags
}

# API Mapping for Custom Domain
resource "aws_apigatewayv2_api_mapping" "this" {
  count = var.domain_name_config != null && local.is_http_api ? 1 : 0

  api_id          = aws_apigatewayv2_api.this[0].id
  domain_name     = aws_apigatewayv2_domain_name.this[0].id
  stage           = aws_apigatewayv2_stage.this[0].id
  api_mapping_key = var.api_mapping_config != null ? var.api_mapping_config.api_mapping_key : null
}
