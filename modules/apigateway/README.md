# AWS API Gateway Terraform Module

This Terraform module creates and manages AWS API Gateway resources, supporting both HTTP APIs (v2) and REST APIs (v1). The module provides a comprehensive, production-ready solution for deploying secure and scalable API Gateway infrastructure.

## Features

- Support for HTTP APIs, REST APIs, and WebSocket APIs
- Configurable stages with auto-deployment
- JWT and Lambda authorizers
- VPC Link support for private backend integrations
- Custom domain names with ACM certificates
- CloudWatch logging and X-Ray tracing
- Throttling and quota management
- CORS configuration
- Multiple integrations per API (HTTP_PROXY, AWS_PROXY, MOCK, etc.)
- API mappings for custom domains
- Comprehensive tagging support

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |

### AWS Permissions Required

The following AWS permissions are required to use this module:

- `apigateway:*` - API Gateway management
- `logs:CreateLogGroup` - CloudWatch log group creation
- `logs:PutRetentionPolicy` - Set log retention
- `ec2:CreateVpcEndpoint` - VPC Link creation (if using private integrations)
- `iam:PassRole` - IAM role management (if using authorizers)

## Usage Examples

### Basic HTTP API with Lambda Integration

```hcl
module "api_gateway" {
  source = "./modules/apigateway"

  name          = "my-api"
  description   = "My API Gateway"
  protocol_type = "HTTP"
  stage_name    = "prod"

  integration_configs = {
    "GET /users" = {
      integration_type   = "AWS_PROXY"
      integration_uri    = aws_lambda_function.users.invoke_arn
      integration_method = "POST"
      payload_format_version = "2.0"
    }
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### HTTP API with JWT Authorizer

```hcl
module "api_gateway" {
  source = "./modules/apigateway"

  name          = "secure-api"
  protocol_type = "HTTP"
  stage_name    = "prod"

  authorizer_config = {
    name            = "cognito-authorizer"
    authorizer_type = "JWT"
    identity_sources = ["$request.header.Authorization"]
    jwt_configuration = {
      audience = ["api-client-id"]
      issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_EXAMPLE"
    }
  }

  integration_configs = {
    "GET /api/*" = {
      integration_type = "HTTP_PROXY"
      integration_uri  = "https://backend.example.com/{proxy}"
      integration_method = "GET"
    }
  }

  access_log_settings = {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId = "$context.requestId"
      ip        = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      httpMethod = "$context.httpMethod"
      routeKey   = "$context.routeKey"
      status     = "$context.status"
    })
  }

  stage_throttle_settings = {
    burst_limit = 500
    rate_limit  = 1000
  }

  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}
```

### API with Custom Domain and VPC Link

```hcl
module "api_gateway" {
  source = "./modules/apigateway"

  name          = "private-api"
  protocol_type = "HTTP"
  stage_name    = "prod"

  disable_execute_api_endpoint = true

  vpc_link_config = {
    name               = "private-backend-link"
    security_group_ids = [aws_security_group.api_backend.id]
    subnet_ids         = aws_subnet.private[*].id
  }

  integration_configs = {
    "GET /api/*" = {
      integration_type   = "HTTP_PROXY"
      integration_uri    = "http://internal-alb.example.local/{proxy}"
      integration_method = "GET"
      connection_type    = "VPC_LINK"
    }
  }

  domain_name_config = {
    domain_name     = "api.example.com"
    certificate_arn = aws_acm_certificate.api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  enable_xray_tracing = true

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### REST API Configuration

```hcl
module "rest_api" {
  source = "./modules/apigateway"

  name          = "legacy-api"
  protocol_type = "REST"
  stage_name    = "prod"

  rest_api_endpoint_configuration = {
    types = ["REGIONAL"]
  }

  rest_api_minimum_compression_size = 1024

  access_log_settings = {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = "$context.requestId"
  }

  enable_xray_tracing = true

  tags = {
    Environment = "production"
    Owner       = "legacy-team"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the API Gateway | `string` | n/a | yes |
| description | Description of the API Gateway | `string` | `""` | no |
| protocol_type | Protocol type (HTTP, REST, or WEBSOCKET) | `string` | `"HTTP"` | no |
| api_key_selection_expression | API key selection expression | `string` | `"$request.header.x-api-key"` | no |
| route_selection_expression | Route selection expression | `string` | `"$request.method $request.path"` | no |
| cors_configuration | CORS configuration | `object` | `null` | no |
| disable_execute_api_endpoint | Disable default execute-api endpoint | `bool` | `false` | no |
| stage_name | Name of the API Gateway stage | `string` | `"$default"` | no |
| stage_auto_deploy | Auto deploy stage on updates | `bool` | `true` | no |
| stage_throttle_settings | Throttle settings (burst_limit, rate_limit) | `object` | `null` | no |
| access_log_settings | CloudWatch log settings | `object` | `null` | no |
| route_settings | Per-route settings | `map(object)` | `{}` | no |
| authorizer_config | Authorizer configuration | `object` | `null` | no |
| integration_configs | Map of integration configurations | `map(object)` | `{}` | no |
| vpc_link_config | VPC Link configuration | `object` | `null` | no |
| domain_name_config | Custom domain configuration | `object` | `null` | no |
| api_mapping_config | API mapping configuration | `object` | `null` | no |
| tags | Resource tags | `map(string)` | `{}` | no |
| enable_xray_tracing | Enable X-Ray tracing | `bool` | `false` | no |
| api_key_required | Require API key for routes | `bool` | `false` | no |
| rest_api_minimum_compression_size | Minimum compression size for REST API | `number` | `-1` | no |
| rest_api_endpoint_configuration | REST API endpoint configuration | `object` | `{types = ["REGIONAL"]}` | no |
| rest_api_policy | REST API resource policy | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_id | The ID of the API Gateway |
| api_arn | The ARN of the API Gateway |
| api_endpoint | The URI of the API Gateway |
| api_execution_arn | The execution ARN (for IAM policies) |
| stage_id | The ID of the API Gateway stage |
| stage_arn | The ARN of the API Gateway stage |
| stage_invoke_url | The URL to invoke the API Gateway |
| vpc_link_id | The ID of the VPC Link (if created) |
| authorizer_id | The ID of the authorizer (if created) |
| domain_name | The custom domain name (if created) |
| domain_name_configuration | Domain name configuration details |
| api_mapping_id | The ID of the API mapping (if created) |
| log_group_name | CloudWatch log group name |
| log_group_arn | CloudWatch log group ARN |
| integration_ids | Map of route keys to integration IDs |
| route_ids | Map of route keys to route IDs |

## Advanced Configuration

### CORS Configuration

```hcl
cors_configuration = {
  allow_credentials = true
  allow_headers     = ["Content-Type", "Authorization"]
  allow_methods     = ["GET", "POST", "PUT", "DELETE"]
  allow_origins     = ["https://example.com"]
  expose_headers    = ["X-Request-Id"]
  max_age           = 300
}
```

### Throttling Settings

```hcl
stage_throttle_settings = {
  burst_limit = 500   # Maximum concurrent requests
  rate_limit  = 1000  # Requests per second
}

route_settings = {
  "GET /high-traffic" = {
    throttling_burst_limit = 1000
    throttling_rate_limit  = 2000
    detailed_metrics_enabled = true
    logging_level = "INFO"
  }
}
```

### Custom Log Format

```hcl
access_log_settings = {
  destination_arn = aws_cloudwatch_log_group.api_logs.arn
  format = jsonencode({
    requestId      = "$context.requestId"
    ip             = "$context.identity.sourceIp"
    requestTime    = "$context.requestTime"
    httpMethod     = "$context.httpMethod"
    routeKey       = "$context.routeKey"
    status         = "$context.status"
    protocol       = "$context.protocol"
    responseLength = "$context.responseLength"
    errorMessage   = "$context.error.message"
    integrationError = "$context.integration.error"
  })
}
```

## Notes

### API Gateway Quotas and Limits

- **Regional APIs**: 600 requests per second (default quota, can be increased)
- **Burst limit**: 10,000 requests across all APIs
- **WebSocket APIs**: 10,000 connections per second
- **Timeout**: Maximum integration timeout is 30 seconds (29 seconds for HTTP APIs)

### HTTP APIs vs REST APIs

**HTTP APIs** are recommended for:
- Lower cost requirements (~71% cheaper)
- Native AWS Lambda and HTTP backends
- Modern authentication (JWT, OIDC)
- Simple request/response patterns

**REST APIs** are recommended for:
- API key management and usage plans
- Request/response transformation
- Resource policies
- Legacy system compatibility

### Best Practices

1. Always enable CloudWatch logging for production APIs
2. Use authorizers for all public-facing APIs
3. Configure throttling to protect backend systems
4. Use custom domains instead of default execute-api endpoints
5. Enable X-Ray tracing for performance monitoring
6. Apply required tags (Environment, Owner) for resource management
7. Use VPC Links for private integrations
8. Set appropriate CORS policies (avoid wildcards in production)

## Links

- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Terraform AWS Provider - API Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/best-practices.html)
