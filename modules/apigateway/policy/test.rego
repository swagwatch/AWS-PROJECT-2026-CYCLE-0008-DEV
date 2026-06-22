package terraform.aws.apigateway_test

import rego.v1

import data.terraform.aws.apigateway

# Test: Valid configuration with all required settings
test_valid_configuration_no_violations if {
	mock_input := {
		"resource_changes": [
			{
				"address": "aws_apigatewayv2_api.test",
				"type": "aws_apigatewayv2_api",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "test-api",
						"protocol_type": "HTTP",
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"address": "aws_apigatewayv2_stage.test",
				"type": "aws_apigatewayv2_stage",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "dev",
						"access_log_settings": [{
							"destination_arn": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/test",
							"format": "$context.requestId",
						}],
						"default_route_settings": [{
							"throttling_burst_limit": 500,
							"throttling_rate_limit": 1000,
						}],
					},
				},
			},
			{
				"address": "aws_apigatewayv2_route.test",
				"type": "aws_apigatewayv2_route",
				"change": {
					"actions": ["create"],
					"after": {
						"route_key": "GET /users",
						"authorization_type": "JWT",
						"authorizer_id": "auth123",
					},
				},
			},
		],
	}

	count(apigateway.deny) == 0 with input as mock_input
}

# Test: Invalid configuration with multiple violations
test_invalid_configuration_with_violations if {
	mock_input := {
		"resource_changes": [
			{
				"address": "aws_apigatewayv2_api.bad",
				"type": "aws_apigatewayv2_api",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "bad-api",
						"protocol_type": "HTTP",
						"tags": {},
					},
				},
			},
			{
				"address": "aws_apigatewayv2_stage.bad",
				"type": "aws_apigatewayv2_stage",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "dev",
					},
				},
			},
			{
				"address": "aws_apigatewayv2_route.bad",
				"type": "aws_apigatewayv2_route",
				"change": {
					"actions": ["create"],
					"after": {
						"route_key": "GET /public",
						"authorization_type": "NONE",
						"api_key_required": false,
					},
				},
			},
		],
	}

	count(apigateway.deny) > 0 with input as mock_input
}

# Test: Delete action should be ignored
test_delete_action_ignored if {
	mock_input := {
		"resource_changes": [{
			"address": "aws_apigatewayv2_api.deleted",
			"type": "aws_apigatewayv2_api",
			"change": {
				"actions": ["delete"],
				"after": null,
			},
		}],
	}

	count(apigateway.deny) == 0 with input as mock_input
}

# Test: Warning rules are triggered for suboptimal configurations
test_warn_rules_triggered if {
	mock_input := {
		"resource_changes": [
			{
				"address": "aws_apigatewayv2_api.test",
				"type": "aws_apigatewayv2_api",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "test-api",
						"disable_execute_api_endpoint": false,
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"address": "aws_apigatewayv2_domain_name.test",
				"type": "aws_apigatewayv2_domain_name",
				"change": {
					"actions": ["create"],
					"after": {
						"domain_name": "api.example.com",
					},
				},
			},
			{
				"address": "aws_apigatewayv2_stage.test",
				"type": "aws_apigatewayv2_stage",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "dev",
						"access_log_settings": [{
							"destination_arn": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/test",
							"format": "$context.requestId",
						}],
						"default_route_settings": [{
							"throttling_burst_limit": 500,
							"throttling_rate_limit": 1000,
						}],
						"route_settings": [],
					},
				},
			},
		],
	}

	count(apigateway.warn) > 0 with input as mock_input
}

# Test: CORS wildcard in production triggers deny
test_cors_wildcard_production if {
	mock_input := {
		"resource_changes": [{
			"address": "aws_apigatewayv2_api.prod",
			"type": "aws_apigatewayv2_api",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "prod-api",
					"cors_configuration": [{
						"allow_origins": ["*"],
						"allow_methods": ["GET", "POST"],
					}],
					"tags": {
						"Environment": "production",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}

	count(apigateway.deny) > 0 with input as mock_input
}

# Test: Valid configuration with all features enabled
test_valid_configuration_with_all_features if {
	mock_input := {
		"resource_changes": [
			{
				"address": "aws_apigatewayv2_api.full",
				"type": "aws_apigatewayv2_api",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "full-api",
						"protocol_type": "HTTP",
						"disable_execute_api_endpoint": true,
						"cors_configuration": [{
							"allow_origins": ["https://example.com"],
							"allow_methods": ["GET", "POST"],
						}],
						"tags": {
							"Environment": "production",
							"Owner": "security-team",
						},
					},
				},
			},
			{
				"address": "aws_apigatewayv2_stage.full",
				"type": "aws_apigatewayv2_stage",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "prod",
						"access_log_settings": [{
							"destination_arn": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/full",
							"format": "$context.requestId",
						}],
						"default_route_settings": [{
							"throttling_burst_limit": 1000,
							"throttling_rate_limit": 2000,
						}],
						"route_settings": [{
							"route_key": "GET /api/*",
							"detailed_metrics_enabled": true,
						}],
					},
				},
			},
			{
				"address": "aws_apigatewayv2_route.full",
				"type": "aws_apigatewayv2_route",
				"change": {
					"actions": ["create"],
					"after": {
						"route_key": "GET /api/*",
						"authorization_type": "JWT",
						"authorizer_id": "auth123",
						"api_key_required": true,
					},
				},
			},
		],
	}

	count(apigateway.deny) == 0 with input as mock_input
}

# Test: High throttle limit triggers warning
test_high_throttle_limit_warning if {
	mock_input := {
		"resource_changes": [{
			"address": "aws_apigatewayv2_stage.high_throttle",
			"type": "aws_apigatewayv2_stage",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "prod",
					"access_log_settings": [{
						"destination_arn": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/test",
						"format": "$context.requestId",
					}],
					"default_route_settings": [{
						"throttling_burst_limit": 10000,
						"throttling_rate_limit": 15000,
					}],
				},
			},
		}],
	}

	count(apigateway.warn) > 0 with input as mock_input
}

# Test: REST API without tags triggers violations
test_rest_api_missing_tags if {
	mock_input := {
		"resource_changes": [{
			"address": "aws_api_gateway_rest_api.bad",
			"type": "aws_api_gateway_rest_api",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "bad-rest-api",
					"tags": {},
				},
			},
		}],
	}

	count(apigateway.deny) >= 2 with input as mock_input
}
