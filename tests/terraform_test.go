package test

import (
	"context"
	"flag"
	"fmt"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudfront"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/oozou/terraform-test-util"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Global variables for test reporting
var (
	generateReport bool
	reportFile     string
	htmlFile       string
)

// TestMain enables custom test runner with reporting
func TestMain(m *testing.M) {
	flag.BoolVar(&generateReport, "report", false, "Generate test report")
	flag.StringVar(&reportFile, "report-file", "test-report.json", "Test report JSON file")
	flag.StringVar(&htmlFile, "html-file", "test-report.html", "Test report HTML file")
	flag.Parse()

	exitCode := m.Run()
	os.Exit(exitCode)
}

func TestTerraformAWSCloudFrontModule(t *testing.T) {
	t.Parallel()

	// Record test start time
	startTime := time.Now()
	var testResults []testutil.TestResult

	// Pick a random AWS region to test in
	awsRegion := "ap-southeast-1"



	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/terraform-test",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"prefix":      "terratest",
			"environment": "test",
			"name":        "cf",
			"custom_tags": map[string]string{"test": "true"},
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer func() {
		t.Logf("Removing OAC and WAF association from CloudFront distribution")
		// Remove CloudFront OAC and WAF association before destroying resources
		if !t.Failed() {
			// Only attempt cleanup if terraform apply succeeded
			distributionArn, err := terraform.OutputE(t, terraformOptions, "cloudfront_distribution_arn")
			t.Logf("CloudFront distribution ARN: %s", distributionArn)
			if err == nil && distributionArn != "" {
				// Extract distribution ID from ARN
				arnParts := strings.Split(distributionArn, "/")
				if len(arnParts) > 0 {
					distributionId := arnParts[len(arnParts)-1]
					
					// Create AWS config for us-east-1 (CloudFront is global but API is in us-east-1)
					cfg := createAWSConfig(t, "us-east-1")
					cloudfrontClient := cloudfront.NewFromConfig(cfg)
					
					// Get current distribution configuration
					getDistributionInput := &cloudfront.GetDistributionInput{
						Id: aws.String(distributionId),
					}
					
					distribution, err := cloudfrontClient.GetDistribution(context.TODO(), getDistributionInput)

					distConfig := distribution.Distribution.DistributionConfig
					t.Logf("CloudFront distribution ID: %s", distributionId)
					if err == nil && distribution.Distribution != nil {

						// Check if OAC is associated
						// for _, origin := range distConfig.Origins.Items {
						// 	if origin.S3OriginConfig != nil && origin.OriginAccessControlId != nil {
						// 		fmt.Printf("Removing OAC from origin: %s\n", *origin.Id)
						// 		origin.OriginAccessControlId = nil
						// 	}
						// }

						for i := range distConfig.Origins.Items {
							origin := distConfig.Origins.Items[i]
							if origin.S3OriginConfig != nil && origin.OriginAccessControlId != nil {
								fmt.Printf("Removing OAC from origin: %s\n", *origin.Id)
								distConfig.Origins.Items[i].OriginAccessControlId = nil
							}
						}						
						t.Logf("distConfig: %v", distConfig)
						_, err = cloudfrontClient.UpdateDistribution(context.TODO(), &cloudfront.UpdateDistributionInput{
							Id:                 aws.String(distributionId),
							DistributionConfig: distConfig,
							IfMatch:           distribution.ETag,
						})
						if err != nil {
							t.Logf("failed to update distribution: %v", err)
						}

						// Check if WAF is associated
						distribution, err:= cloudfrontClient.GetDistribution(context.TODO(), getDistributionInput)
						if err != nil {
							t.Logf("failed to get distribution: %v", err)
						}
						if distribution.Distribution.DistributionConfig.WebACLId != nil && 
						   *distribution.Distribution.DistributionConfig.WebACLId != "" {
							
							t.Logf("Removing WAF association from CloudFront distribution %s before cleanup", distributionId)
							
							// Create a copy of the distribution config and remove WAF association
							config := distribution.Distribution.DistributionConfig
							config.WebACLId = aws.String("")
							
							// Update the distribution to remove WAF association
							t.Logf("check new config: %v", config)
							updateDistributionInput := &cloudfront.UpdateDistributionInput{
								Id:                 aws.String(distributionId),
								DistributionConfig: config,
								IfMatch:           distribution.ETag,
							}
							
							_, err := cloudfrontClient.UpdateDistribution(context.TODO(), updateDistributionInput)
							if err != nil {
								t.Logf("Warning: Failed to remove WAF association: %v", err)
							} else {
								t.Logf("Successfully removed WAF association from CloudFront distribution")
								
								// Wait for distribution to be deployed before proceeding with destroy
								t.Logf("Waiting for CloudFront distribution to be deployed...")
								time.Sleep(2 * time.Minute)
							}
						}
					}

		
					terraform.Destroy(t, terraformOptions)

					updatedDistribution, err := cloudfrontClient.GetDistribution(context.TODO(), getDistributionInput)
					if err != nil {
						t.Logf("failed to get distribution config before delete: %v", err)
					}

					_, err = cloudfrontClient.DeleteDistribution(context.TODO(), &cloudfront.DeleteDistributionInput{
						Id:      aws.String(distributionId),
						IfMatch: updatedDistribution.ETag,
					})
					if err != nil {
						t.Logf("failed to delete distribution: %v", err)
					}

					t.Logf("Deleted distribution: %s\n", distributionId)
				}
			}
		}
	}()

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// If terraform apply failed, don't run the individual tests
	if t.Failed() {
		t.Fatal("Terraform apply failed, skipping individual tests")
		return
	}

	// Define test cases with their functions
	testCases := []struct {
		name string
		fn   func(*testing.T, *terraform.Options, string)
	}{
		{"TestCloudFrontDistributionExists", testCloudFrontDistributionExists},
		{"TestWAFCreatedAndAssociated", testWAFCreatedAndAssociated},
		{"TestCloudFrontLogsCreated", testCloudFrontLogsCreated},
		{"TestS3AccessViaCloudFront", testS3AccessViaCloudFront},
	}

	// Run all test cases and collect results
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			testStart := time.Now()

			// Capture test result
			defer func() {
				testEnd := time.Now()
				duration := testEnd.Sub(testStart)

				result := testutil.TestResult{
					Name:     tc.name,
					Duration: duration.String(),
				}

				if r := recover(); r != nil {
					result.Status = "FAIL"
					result.Error = fmt.Sprintf("Panic: %v", r)
				} else if t.Failed() {
					result.Status = "FAIL"
					result.Error = "Test assertions failed"
				} else if t.Skipped() {
					result.Status = "SKIP"
				} else {
					result.Status = "PASS"
				}

				testResults = append(testResults, result)
			}()

			// Run the actual test
			tc.fn(t, terraformOptions, awsRegion)
		})
	}


	// Generate and display test report
	endTime := time.Now()
	report := testutil.GenerateTestReport(testResults, startTime, endTime)
	report.TestSuite = "Terraform AWS CloudFront Tests"
	report.PrintReport()

	// Save reports to files
	if err := report.SaveReportToFile("test-report.json"); err != nil {
		t.Errorf("failed to save report to file: %v", err)
	}

	if err := report.SaveReportToHTML("test-report.html"); err != nil {
		t.Errorf("failed to save report to HTML: %v", err)
	}	
}


// Helper function to create AWS config
func createAWSConfig(t *testing.T, region string) aws.Config {
	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(region),
	)
	require.NoError(t, err, "Failed to create AWS config")
	return cfg
}

// Test function to verify CloudFront distribution exists and is properly configured
func testCloudFrontDistributionExists(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	// Get the CloudFront distribution ARN from terraform output
	distributionArn := terraform.Output(t, terraformOptions, "cloudfront_distribution_arn")
	distributionDomainName := terraform.Output(t, terraformOptions, "cloudfront_distribution_domain_name")

	// Verify outputs are not empty
	assert.NotEmpty(t, distributionArn, "CloudFront distribution ARN should not be empty")
	assert.NotEmpty(t, distributionDomainName, "CloudFront distribution domain name should not be empty")

	// Extract distribution ID from ARN
	arnParts := strings.Split(distributionArn, "/")
	require.Greater(t, len(arnParts), 0, "Invalid CloudFront distribution ARN format")
	distributionId := arnParts[len(arnParts)-1]

	// Create AWS config for us-east-1 (CloudFront is global but API is in us-east-1)
	cfg := createAWSConfig(t, "us-east-1")
	cloudfrontClient := cloudfront.NewFromConfig(cfg)

	// Get distribution details
	getDistributionInput := &cloudfront.GetDistributionInput{
		Id: aws.String(distributionId),
	}

	distribution, err := cloudfrontClient.GetDistribution(context.TODO(), getDistributionInput)
	require.NoError(t, err, "Failed to get CloudFront distribution")
	require.NotNil(t, distribution.Distribution, "CloudFront distribution should not be nil")

	// Verify distribution is enabled
	assert.True(t, *distribution.Distribution.DistributionConfig.Enabled, "CloudFront distribution should be enabled")

	// Verify distribution has origins
	assert.Greater(t, len(distribution.Distribution.DistributionConfig.Origins.Items), 0, "CloudFront distribution should have at least one origin")

	// Verify distribution has default cache behavior
	assert.NotNil(t, distribution.Distribution.DistributionConfig.DefaultCacheBehavior, "CloudFront distribution should have default cache behavior")

	// Verify distribution status is deployed
	assert.Equal(t, "Deployed", *distribution.Distribution.Status, "CloudFront distribution should be deployed")

	t.Logf("CloudFront distribution %s is properly configured and deployed", distributionId)
}

// Test function to verify WAF is created and associated with CloudFront
func testWAFCreatedAndAssociated(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	// Get the CloudFront distribution ARN from terraform output
	distributionArn := terraform.Output(t, terraformOptions, "cloudfront_distribution_arn")

	// Extract distribution ID from ARN
	arnParts := strings.Split(distributionArn, "/")
	require.Greater(t, len(arnParts), 0, "Invalid CloudFront distribution ARN format")
	distributionId := arnParts[len(arnParts)-1]

	// Create AWS config for us-east-1 (WAF for CloudFront is in us-east-1)
	cfg := createAWSConfig(t, "us-east-1")
	cloudfrontClient := cloudfront.NewFromConfig(cfg)

	// Get distribution details
	getDistributionInput := &cloudfront.GetDistributionInput{
		Id: aws.String(distributionId),
	}

	distribution, err := cloudfrontClient.GetDistribution(context.TODO(), getDistributionInput)
	require.NoError(t, err, "Failed to get CloudFront distribution")
	require.NotNil(t, distribution.Distribution, "CloudFront distribution should not be nil")

	// Verify WAF is associated with CloudFront
	webAclId := distribution.Distribution.DistributionConfig.WebACLId
	assert.NotNil(t, webAclId, "CloudFront distribution should have WAF associated")
	assert.NotEmpty(t, *webAclId, "WAF Web ACL ID should not be empty")


	t.Logf("WAF Web ACL %s is properly created and associated with CloudFront distribution %s", *webAclId, distributionId)
}

// Test function to verify CloudFront logs are created and configured
func testCloudFrontLogsCreated(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	// Get the log bucket name from terraform output
	logBucketName := terraform.Output(t, terraformOptions, "log_bucket_name")
	distributionArn := terraform.Output(t, terraformOptions, "cloudfront_distribution_arn")

	// Verify outputs are not empty
	assert.NotEmpty(t, logBucketName, "Log bucket name should not be empty")

	// Extract distribution ID from ARN
	arnParts := strings.Split(distributionArn, "/")
	require.Greater(t, len(arnParts), 0, "Invalid CloudFront distribution ARN format")
	distributionId := arnParts[len(arnParts)-1]

	// Create AWS config
	cfg := createAWSConfig(t, awsRegion)
	s3Client := s3.NewFromConfig(cfg)

	// Verify log bucket exists
	headBucketInput := &s3.HeadBucketInput{
		Bucket: aws.String(logBucketName),
	}

	_, err := s3Client.HeadBucket(context.TODO(), headBucketInput)
	require.NoError(t, err, "Log bucket should exist")

	// Create AWS config for us-east-1 (CloudFront is global but API is in us-east-1)
	cfgCF := createAWSConfig(t, "us-east-1")
	cloudfrontClient := cloudfront.NewFromConfig(cfgCF)

	// Get distribution details to verify logging configuration
	getDistributionInput := &cloudfront.GetDistributionInput{
		Id: aws.String(distributionId),
	}

	distribution, err := cloudfrontClient.GetDistribution(context.TODO(), getDistributionInput)
	require.NoError(t, err, "Failed to get CloudFront distribution")
	require.NotNil(t, distribution.Distribution, "CloudFront distribution should not be nil")

	// Verify logging configuration
	loggingConfig := distribution.Distribution.DistributionConfig.Logging
	assert.NotNil(t, loggingConfig, "CloudFront distribution should have logging configuration")
	assert.True(t, *loggingConfig.Enabled, "CloudFront logging should be enabled")
	assert.Contains(t, *loggingConfig.Bucket, logBucketName, "CloudFront logging bucket should match the created bucket")

	t.Logf("CloudFront logging is properly configured with bucket %s", logBucketName)
}

// Test function to verify S3 access via CloudFront
func testS3AccessViaCloudFront(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	// Get outputs from terraform
	distributionDomainName := terraform.Output(t, terraformOptions, "cloudfront_distribution_domain_name")
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")

	// Verify outputs are not empty
	assert.NotEmpty(t, distributionDomainName, "CloudFront distribution domain name should not be empty")
	assert.NotEmpty(t, s3BucketName, "S3 bucket name should not be empty")

	time.Sleep(30 * time.Second)

	// Test access via CloudFront
	cloudfrontUrl := fmt.Sprintf("https://%s/%s", distributionDomainName, "test-file.txt")
	
	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	// Make request to CloudFront
	resp, err := client.Get(cloudfrontUrl)
	require.NoError(t, err, "Failed to make request to CloudFront URL")
	defer resp.Body.Close()

	// Verify response status
	assert.Equal(t, http.StatusOK, resp.StatusCode, "CloudFront should return 200 OK for valid S3 object")

	// Verify CloudFront headers are present
	assert.NotEmpty(t, resp.Header.Get("X-Cache"), "CloudFront should add X-Cache header")
	assert.NotEmpty(t, resp.Header.Get("X-Amz-Cf-Id"), "CloudFront should add X-Amz-Cf-Id header")

	t.Logf("Successfully accessed S3 content via CloudFront at %s", cloudfrontUrl)
}
