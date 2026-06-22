package terraform.aws.apigateway

# Evaluate Terraform plan JSON (terraform show -json plan.tfplan)
# Provides:
# - deny: CRITICAL violations that must fail the pipeline
# - warn: non-blocking warnings
# - info: informational findings

# Helper: return resource changes for a given type that are created or updated
resource_changes_by_type(res_type) := array.concat(creates, updates) if {
	creates := [rc |
		rc := input.resource_changes[_]
		rc.type == res_type
		actions := rc.change.actions
		array_contains(actions, "create")
	]
	updates := [rc |
		rc := input.resource_changes[_]
		rc.type == res_type
		actions := rc.change.actions
		array_contains(actions, "update")
	]
}

# Helper: get tags from after object
get_tags(after) = tags_out if {
	tags := after.tags
	tags_out := tags
} else = tags_all_out if {
	tags_all := after.tags_all
	tags_all_out := tags_all
} else = {} if {
	true
}

# Helper: check if a list contains a value
array_contains(arr, v) if {
	some i
	arr[i] == v
}

# ------------------------
# DENY Rules (Security Best Practices - CRITICAL)
# ------------------------

# Deny: Missing required tags (Environment and Owner)
deny contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_api")
	tags := get_tags(rc.change.after)
	not tags.Environment
	msg := sprintf("CRITICAL: API Gateway '%s' is missing required tag 'Environment'", [rc.address])
}

deny contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_api")
	tags := get_tags(rc.change.after)
	not tags.Owner
	msg := sprintf("CRITICAL: API Gateway '%s' is missing required tag 'Owner'", [rc.address])
}

deny contains msg if {
	some rc in resource_changes_by_type("aws_api_gateway_rest_api")
	tags := get_tags(rc.change.after)
	not tags.Environment
	msg := sprintf("CRITICAL: REST API Gateway '%s' is missing required tag 'Environment'", [rc.address])
}

deny contains msg if {
	some rc in resource_changes_by_type("aws_api_gateway_rest_api")
	tags := get_tags(rc.change.after)
	not tags.Owner
	msg := sprintf("CRITICAL: REST API Gateway '%s' is missing required tag 'Owner'", [rc.address])
}

# Deny: Missing CloudWatch logging on stages
deny contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_stage")
	not rc.change.after.access_log_settings
	msg := sprintf("CRITICAL: API Gateway stage '%s' does not have CloudWatch logging enabled", [rc.address])
}

deny contains msg if {
	some rc in resource_changes_by_type("aws_api_gateway_stage")
	not rc.change.after.access_log_settings
	msg := sprintf("CRITICAL: REST API Gateway stage '%s' does not have CloudWatch logging enabled", [rc.address])
}

# Deny: Missing throttle settings on stages
deny contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_stage")
	not rc.change.after.default_route_settings
	msg := sprintf("CRITICAL: API Gateway stage '%s' does not have throttle settings configured", [rc.address])
}

# Deny: CORS wildcard origins in production
deny contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_api")
	cors := rc.change.after.cors_configuration[_]
	array_contains(cors.allow_origins, "*")
	tags := get_tags(rc.change.after)
	tags.Environment == "production"
	msg := sprintf("CRITICAL: API Gateway '%s' uses CORS wildcard origins (*) in production environment", [rc.address])
}

# Deny: Public endpoints without authorizer
deny contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_route")
	rc.change.after.authorization_type == "NONE"
	not rc.change.after.api_key_required
	msg := sprintf("CRITICAL: API Gateway route '%s' has no authorizer and does not require API key", [rc.address])
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# Warn: X-Ray tracing disabled
warn contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_stage")
	not rc.change.after.default_route_settings
	msg := sprintf("WARNING: X-Ray tracing is not explicitly configured for stage '%s'. Consider enabling for better observability", [rc.address])
}

warn contains msg if {
	some rc in resource_changes_by_type("aws_api_gateway_stage")
	not rc.change.after.xray_tracing_enabled
	msg := sprintf("WARNING: X-Ray tracing is disabled for REST API stage '%s'. Consider enabling for better observability", [rc.address])
}

# Warn: High throttle limits (potential cost concern)
warn contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_stage")
	settings := rc.change.after.default_route_settings[_]
	settings.throttling_rate_limit > 10000
	msg := sprintf("WARNING: API Gateway stage '%s' has very high throttle rate limit (%d). Verify this is intentional to avoid unexpected costs", [rc.address, settings.throttling_rate_limit])
}

# Warn: Default execute-api endpoint enabled when using custom domain
warn contains msg if {
	some api in resource_changes_by_type("aws_apigatewayv2_api")
	not api.change.after.disable_execute_api_endpoint
	some domain in resource_changes_by_type("aws_apigatewayv2_domain_name")
	msg := sprintf("WARNING: API Gateway '%s' has custom domain configured but default execute-api endpoint is still enabled. Consider disabling for security", [api.address])
}

# Warn: No detailed metrics enabled
warn contains msg if {
	some rc in resource_changes_by_type("aws_apigatewayv2_stage")
	count(rc.change.after.route_settings) == 0
	msg := sprintf("WARNING: API Gateway stage '%s' has no per-route settings configured. Consider enabling detailed metrics for better monitoring", [rc.address])
}
