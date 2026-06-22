output "api_gateway_id" {
  description = "The ID of the API Gateway"
  value       = module.apigateway_app.api_id
}

output "api_gateway_arn" {
  description = "The ARN of the API Gateway"
  value       = module.apigateway_app.api_arn
}

output "api_gateway_endpoint" {
  description = "The URI of the API Gateway"
  value       = module.apigateway_app.api_endpoint
}

output "api_gateway_stage_invoke_url" {
  description = "The URL to invoke the API Gateway stage"
  value       = module.apigateway_app.stage_invoke_url
}

output "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway"
  value       = module.apigateway_app.api_execution_arn
}

output "authorizer_id" {
  description = "The ID of the API Gateway authorizer"
  value       = module.apigateway_app.authorizer_id
}

output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.apigateway_app.log_group_name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = module.apigateway_app.log_group_arn
}
