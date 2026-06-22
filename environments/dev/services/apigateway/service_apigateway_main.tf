resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = local.log_group_name
  retention_in_days = 30
  tags              = local.service_tags
}

module "apigateway_app" {
  source = "../../modules/apigateway"

  name                = local.api_name_prefix
  description         = "API Gateway for ${var.environment} environment"
  protocol_type       = var.api_protocol_type
  stage_name          = var.api_stage_name
  stage_auto_deploy   = true
  enable_xray_tracing = var.enable_xray

  stage_throttle_settings = var.enable_throttling ? {
    burst_limit = var.throttle_burst_limit
    rate_limit  = var.throttle_rate_limit
  } : null

  access_log_settings = var.enable_access_logging ? {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = local.access_log_format
  } : null

  authorizer_config   = local.authorizer_config
  integration_configs = var.integration_configs

  tags = local.service_tags
}
