# Terraform AWS CloudFront Module Tests

This directory contains comprehensive tests for the Terraform AWS CloudFront module using the `terraform-test-util` framework.

## Overview

The tests validate the functionality of the AWS CloudFront module by:
- Verifying CloudFront distribution creation and configuration
- Testing WAF creation and association with CloudFront
- Validating CloudFront logging configuration
- Testing S3 access via CloudFront distribution
- Checking Origin Access Control (OAC) configuration

## Test Framework

The tests use the [terraform-test-util](https://github.com/oozou/terraform-test-util) framework which provides:
- Comprehensive test reporting with JSON and HTML outputs
- Beautiful console output with emojis and clear formatting
- Pass rate calculation and test statistics
- GitHub-friendly summary generation

## Prerequisites

- Go 1.21 or later
- Terraform 1.6.0 or later
- AWS credentials configured
- Access to AWS CloudFront, S3, WAF, and IAM services

## Running Tests

### Using Make (Recommended)

```bash
# Run all tests with report generation
make test

# Generate test reports (if tests were already run)
make generate-report

# Clean up test artifacts
make clean

# Run tests in verbose mode
make test-verbose

# Run a specific test
make test-specific TEST=TestCloudFrontDistributionExists
```

### Using Go Test Directly

```bash
# Run all tests
go test -v -timeout 45m

# Run tests with report generation
go test -v -timeout 45m -args -report=true -report-file=test-report.json -html-file=test-report.html

# Run a specific test
go test -v -timeout 45m -run TestCloudFrontDistributionExists
```

## Test Structure

The test suite includes the following test cases:

1. **TestCloudFrontDistributionExists** - Verifies CloudFront distribution creation and configuration
2. **TestWAFCreatedAndAssociated** - Tests WAF creation and association with CloudFront
3. **TestCloudFrontLogsCreated** - Validates CloudFront logging configuration
4. **TestS3AccessViaCloudFront** - Tests S3 access through CloudFront distribution

## Test Configuration

The tests use the `examples/terraform-test` configuration which includes:
- CloudFront distribution with S3 origin
- WAF with managed rules for security
- S3 buckets for content and logging
- Origin Access Control (OAC) for secure S3 access
- Custom cache behaviors and error responses
- Proper tagging and naming conventions

## Test Details

### TestCloudFrontDistributionExists
- Verifies CloudFront distribution is created and deployed
- Checks distribution configuration (enabled, origins, cache behaviors)
- Validates distribution status and domain name

### TestWAFCreatedAndAssociated
- Confirms WAF Web ACL is created with managed rules
- Verifies WAF is properly associated with CloudFront distribution
- Checks WAF rules configuration

### TestCloudFrontLogsCreated
- Validates S3 bucket for CloudFront logs exists
- Confirms logging is enabled in CloudFront distribution
- Checks logging configuration matches expected bucket

### TestS3AccessViaCloudFront
- Creates test content in S3 bucket
- Accesses content via CloudFront distribution URL
- Verifies CloudFront headers and response status
- Cleans up test content after verification

## Test Reports

The framework generates multiple types of reports:

### JSON Report (`test-report.json`)
Contains detailed test results in JSON format for programmatic processing.

### HTML Report (`test-report.html`)
A beautiful, interactive HTML report with:
- Test statistics and pass rates
- Detailed test results with status indicators
- Error details for failed tests
- Progress bars and visual indicators

### Console Output
Formatted console output with:
- Test execution progress
- Detailed statistics
- Pass/fail indicators with emojis
- Summary and recommendations

## CI/CD Integration

The tests are integrated with GitHub Actions workflow that:
- Runs tests automatically on pull requests
- Generates and uploads test reports
- Posts test results as PR comments
- Includes "@claude fix build error:" prefix for failed tests
- Provides direct links to workflow runs and detailed logs

## Environment Variables

The following environment variables can be used to configure the tests:

- `AWS_DEFAULT_REGION` - AWS region for testing (default: ap-southeast-1)
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_SESSION_TOKEN` - AWS session token (if using temporary credentials)

## Troubleshooting

### Common Issues

1. **AWS Permissions**: Ensure your AWS credentials have permissions for CloudFront, S3, WAF, and IAM
2. **CloudFront Propagation**: CloudFront distributions take time to deploy (15-20 minutes)
3. **WAF Region**: WAF for CloudFront must be created in us-east-1 region
4. **Timeout Issues**: Tests have a 45-minute timeout to accommodate CloudFront deployment time
5. **Resource Cleanup**: The `terraform destroy` is called automatically in defer blocks

### Debug Mode

For debugging failed tests:

```bash
# Run with verbose output
go test -v -timeout 45m -run TestSpecificTest

# Check terraform logs
export TF_LOG=DEBUG
go test -v -timeout 45m
```

## Contributing

When adding new tests:

1. Follow the existing test structure and naming conventions
2. Add proper error handling and cleanup
3. Include meaningful assertions and error messages
4. Update this README with new test descriptions
5. Ensure tests are idempotent and don't interfere with each other
6. Consider CloudFront propagation delays in test timing

## Dependencies

The tests depend on:

- `github.com/gruntwork-io/terratest` - Terraform testing framework
- `github.com/stretchr/testify` - Test assertions and utilities
- `github.com/aws/aws-sdk-go` - AWS SDK for Go
- `github.com/oozou/terraform-test-util` - Test reporting utilities

## License

This test suite is part of the terraform-aws-cloudfront module and follows the same license terms.
