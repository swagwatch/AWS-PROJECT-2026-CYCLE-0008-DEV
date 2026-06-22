output "api_id" {
  description = "The ID of the API Gateway"
  value       = local.api_id
}

output "api_arn" {
  description = "The ARN of the API Gateway"
  value       = local.is_http_api ? try(aws_apigatewayv2_api.this[0].arn, null) : try(aws_api_gateway_rest_api.this[0].arn, null)
}

output "api_endpoint" {
  description = "The URI of the API Gateway"
  value       = local.is_http_api ? try(aws_apigatewayv2_api.this[0].api_endpoint, null) : try(aws_api_gateway_rest_api.this[0].execution_arn, null)
}

output "api_execution_arn" {
  description = "The execution ARN of the API Gateway (for use in IAM policies)"
  value       = local.is_http_api ? try(aws_apigatewayv2_api.this[0].execution_arn, null) : try(aws_api_gateway_rest_api.this[0].execution_arn, null)
}

output "stage_id" {
  description = "The ID of the API Gateway stage"
  value       = local.is_http_api ? try(aws_apigatewayv2_stage.this[0].id, null) : try(aws_api_gateway_stage.this[0].id, null)
}

output "stage_arn" {
  description = "The ARN of the API Gateway stage"
  value       = local.is_http_api ? try(aws_apigatewayv2_stage.this[0].arn, null) : try(aws_api_gateway_stage.this[0].arn, null)
}

output "stage_invoke_url" {
  description = "The URL to invoke the API Gateway stage"
  value       = local.is_http_api ? try(aws_apigatewayv2_stage.this[0].invoke_url, null) : try("https://${aws_api_gateway_rest_api.this[0].id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.this[0].stage_name}", null)
}

output "vpc_link_id" {
  description = "The ID of the VPC Link (if created)"
  value       = try(aws_apigatewayv2_vpc_link.this[0].id, null)
}

output "authorizer_id" {
  description = "The ID of the API Gateway authorizer (if created)"
  value       = try(aws_apigatewayv2_authorizer.this[0].id, null)
}

output "domain_name" {
  description = "The custom domain name (if created)"
  value       = try(aws_apigatewayv2_domain_name.this[0].domain_name, null)
}

output "domain_name_configuration" {
  description = "The domain name configuration details (if created)"
  value       = try(aws_apigatewayv2_domain_name.this[0].domain_name_configuration, null)
}

output "api_mapping_id" {
  description = "The ID of the API mapping (if created)"
  value       = try(aws_apigatewayv2_api_mapping.this[0].id, null)
}

output "log_group_name" {
  description = "The name of the CloudWatch log group for API Gateway logs"
  value       = try(aws_cloudwatch_log_group.api_gateway[0].name, null)
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group for API Gateway logs"
  value       = try(aws_cloudwatch_log_group.api_gateway[0].arn, null)
}

output "integration_ids" {
  description = "Map of route keys to integration IDs"
  value       = { for k, v in aws_apigatewayv2_integration.this : k => v.id }
}

output "route_ids" {
  description = "Map of route keys to route IDs"
  value       = { for k, v in aws_apigatewayv2_route.this : k => v.id }
}

data "aws_region" "current" {}
