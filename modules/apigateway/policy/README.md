# AWS API Gateway OPA Policy

This directory contains Open Policy Agent (OPA) Rego policies for validating AWS API Gateway Terraform configurations. The policies enforce security best practices, cost optimization guidelines, and compliance requirements.

## Policy Rules

### CRITICAL (Deny) Rules

These violations will fail the pipeline and block deployments:

1. **Missing Required Tags (Environment and Owner)**
   - **Rule**: All API Gateway and REST API resources must have `Environment` and `Owner` tags
   - **Rationale**: Required for cost allocation, resource ownership tracking, and compliance
   - **Fix**: Add both tags to your API Gateway resources
   ```hcl
   tags = {
     Environment = "production"
     Owner       = "platform-team"
   }
   ```

2. **Missing CloudWatch Logging**
   - **Rule**: All API Gateway stages must have CloudWatch access logging enabled
   - **Rationale**: Essential for debugging, monitoring, security auditing, and compliance
   - **Fix**: Configure `access_log_settings` on your stage
   ```hcl
   access_log_settings = {
     destination_arn = aws_cloudwatch_log_group.api_logs.arn
     format          = "$context.requestId"
   }
   ```

3. **Missing Throttle Settings**
   - **Rule**: HTTP/WebSocket API stages must have throttle settings configured
   - **Rationale**: Protects backend systems from overload and manages costs
   - **Fix**: Configure `stage_throttle_settings`
   ```hcl
   stage_throttle_settings = {
     burst_limit = 500
     rate_limit  = 1000
   }
   ```

4. **CORS Wildcard Origins in Production**
   - **Rule**: Production APIs cannot use CORS wildcard origins (`["*"]`)
   - **Rationale**: Security risk - allows any domain to access your API
   - **Fix**: Specify explicit allowed origins
   ```hcl
   cors_configuration = {
     allow_origins = ["https://example.com", "https://app.example.com"]
   }
   ```

5. **Public Endpoints Without Authorizer**
   - **Rule**: Routes with `authorization_type = "NONE"` must require API key
   - **Rationale**: Prevents unauthorized access to API endpoints
   - **Fix**: Add authorizer or require API key
   ```hcl
   authorizer_config = {
     authorizer_type = "JWT"
     identity_sources = ["$request.header.Authorization"]
     jwt_configuration = {
       audience = ["api-client-id"]
       issuer   = "https://cognito-idp.region.amazonaws.com/pool-id"
     }
   }
   # OR
   api_key_required = true
   ```

### WARNING Rules

These are recommendations that don't block deployments:

1. **X-Ray Tracing Disabled**
   - **Recommendation**: Enable X-Ray tracing for better observability
   - **Fix**: Set `enable_xray_tracing = true`

2. **High Throttle Limits**
   - **Recommendation**: Very high rate limits (>10,000 req/sec) may lead to unexpected costs
   - **Fix**: Verify limits are intentional and adjust if needed

3. **Default Execute-API Endpoint Enabled with Custom Domain**
   - **Recommendation**: Disable default endpoint when using custom domain for security
   - **Fix**: Set `disable_execute_api_endpoint = true`

4. **No Per-Route Settings**
   - **Recommendation**: Configure per-route settings for better monitoring
   - **Fix**: Add route-specific configurations for detailed metrics

## Usage Instructions

### Validate Policy Syntax

Check that the Rego code is syntactically correct:

```bash
opa check modules/apigateway/policy/main.rego modules/apigateway/policy/test.rego
```

### Run Unit Tests

Execute the policy unit tests:

```bash
opa test modules/apigateway/policy/ -v
```

Expected output:
```
PASS: 9/9
```

### Generate Terraform Plan JSON

Create a Terraform plan and convert it to JSON for policy evaluation:

```bash
cd environments/dev
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
```

### Evaluate Policies Against Plan

Check for CRITICAL violations (will fail if any found):

```bash
opa eval -d opa-policies/service_apigateway_policies.rego -i tfplan.json \
  --fail "count(data.terraform.aws.apigateway.deny) > 0"
```

View all deny violations:

```bash
opa eval -d opa-policies/service_apigateway_policies.rego -i tfplan.json \
  "data.terraform.aws.apigateway.deny"
```

View all warnings:

```bash
opa eval -d opa-policies/service_apigateway_policies.rego -i tfplan.json \
  "data.terraform.aws.apigateway.warn"
```

## Integration with CI/CD

### Pre-Commit Hook

The repository includes a pre-commit hook that automatically:
1. Validates Terraform formatting and syntax
2. Runs OPA policy checks
3. Blocks commits if CRITICAL violations are found

The hook executes these policies automatically on every commit.

### GitHub Actions / CI Pipeline

Include these steps in your CI pipeline:

```yaml
- name: Terraform Plan
  run: terraform plan -out=tfplan.binary

- name: Convert Plan to JSON
  run: terraform show -json tfplan.binary > tfplan.json

- name: Run OPA Policy Check
  run: |
    opa eval -d policies/ -i tfplan.json \
      --fail "count(data.terraform.aws.apigateway.deny) > 0"
```

Violations will fail the CI pipeline with exit code 1.

## Policy Violation Examples and Fixes

### Example 1: Missing Required Tags

**Violation:**
```
CRITICAL: API Gateway 'aws_apigatewayv2_api.app' is missing required tag 'Environment'
CRITICAL: API Gateway 'aws_apigatewayv2_api.app' is missing required tag 'Owner'
```

**Fix:**
```hcl
module "apigateway" {
  source = "./modules/apigateway"
  name   = "my-api"

  tags = {
    Environment = "production"   # Add this
    Owner       = "platform-team" # Add this
  }
}
```

### Example 2: Missing CloudWatch Logging

**Violation:**
```
CRITICAL: API Gateway stage 'aws_apigatewayv2_stage.app' does not have CloudWatch logging enabled
```

**Fix:**
```hcl
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/my-api"
  retention_in_days = 30
}

module "apigateway" {
  source = "./modules/apigateway"
  name   = "my-api"

  access_log_settings = {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId = "$context.requestId"
      ip        = "$context.identity.sourceIp"
      status    = "$context.status"
    })
  }
}
```

### Example 3: Public Route Without Authorizer

**Violation:**
```
CRITICAL: API Gateway route 'aws_apigatewayv2_route.public' has no authorizer and does not require API key
```

**Fix Option 1 - Add JWT Authorizer:**
```hcl
module "apigateway" {
  source = "./modules/apigateway"
  name   = "my-api"

  authorizer_config = {
    name             = "cognito-auth"
    authorizer_type  = "JWT"
    identity_sources = ["$request.header.Authorization"]
    jwt_configuration = {
      audience = ["api-client-id"]
      issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_ABC123"
    }
  }
}
```

**Fix Option 2 - Require API Key:**
```hcl
module "apigateway" {
  source = "./modules/apigateway"
  name   = "my-api"

  api_key_required = true
}
```

## Policy Customization

To customize policies for your organization:

1. **Modify Tag Requirements**: Edit the deny rules in `main.rego` to require different tags
2. **Adjust Throttle Thresholds**: Change the 10,000 threshold in the high throttle warning
3. **Add New Rules**: Follow the existing pattern to add organization-specific rules
4. **Environment-Specific Rules**: Use the `Environment` tag to apply different rules per environment

Example custom rule:
```rego
# Deny: Production APIs must enable X-Ray tracing
deny contains msg if {
    some rc in resource_changes_by_type("aws_api_gateway_stage")
    tags := get_tags(rc.change.after)
    tags.Environment == "production"
    not rc.change.after.xray_tracing_enabled
    msg := sprintf("CRITICAL: Production stage '%s' must have X-Ray tracing enabled", [rc.address])
}
```

## Testing Your Policies

After modifying policies, always:

1. Run syntax validation: `opa check modules/apigateway/policy/main.rego`
2. Run unit tests: `opa test modules/apigateway/policy/ -v`
3. Test against a real plan: `opa eval -d main.rego -i tfplan.json "data.terraform.aws.apigateway.deny"`
4. Verify both passing and failing scenarios

## References

- [OPA Policy Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Terraform JSON Output Format](https://www.terraform.io/docs/internals/json-format.html)
- [AWS API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/best-practices.html)
