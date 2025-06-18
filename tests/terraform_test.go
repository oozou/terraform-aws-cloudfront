package test

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudfront"
	"github.com/aws/aws-sdk-go/service/s3"
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
		
		//terraform.Destroy(t, terraformOptions)
		
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


// Helper function to create AWS session
func createAWSSession(t *testing.T, region string) *session.Session {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	require.NoError(t, err, "Failed to create AWS session")
	return sess
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

	// Create AWS session for us-east-1 (CloudFront is global but API is in us-east-1)
	sess := createAWSSession(t, "us-east-1")
	cloudfrontClient := cloudfront.New(sess)

	// Get distribution details
	getDistributionInput := &cloudfront.GetDistributionInput{
		Id: aws.String(distributionId),
	}

	distribution, err := cloudfrontClient.GetDistribution(getDistributionInput)
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

	// Create AWS session for us-east-1 (WAF for CloudFront is in us-east-1)
	sess := createAWSSession(t, "us-east-1")
	cloudfrontClient := cloudfront.New(sess)

	// Get distribution details
	getDistributionInput := &cloudfront.GetDistributionInput{
		Id: aws.String(distributionId),
	}

	distribution, err := cloudfrontClient.GetDistribution(getDistributionInput)
	require.NoError(t, err, "Failed to get CloudFront distribution")
	require.NotNil(t, distribution.Distribution, "CloudFront distribution should not be nil")

	// Verify WAF is associated with CloudFront
	webAclId := distribution.Distribution.DistributionConfig.WebACLId
	assert.NotNil(t, webAclId, "CloudFront distribution should have WAF associated")
	assert.NotEmpty(t, *webAclId, "WAF Web ACL ID should not be empty")

	// Debug: Print webAclId
	t.Logf("DEBUG - webAclId: %s", *webAclId)

	// Get WAF details
	// getWebAclInput := &wafv2.GetWebACLInput{
	// 	Id:    webAclId,
	// 	Name:  aws.String("terratest-test-cf-waf"),
	// 	Scope: aws.String("CLOUDFRONT"),
	// }

	// getWebAclInput := &wafv2.GetWebACLInput{
    //     ResourceArn: aws.String(webAclId),
    // }

	// webAcl, err := wafClient.GetWebACL(getWebAclInput)
	// t.Logf("DEBUG - webAcl: %s", *webAcl)
	// if err != nil {
	// 	// Try to list WAFs to find the correct one
	// 	listWebAclsInput := &wafv2.ListWebACLsInput{
	// 		Scope: aws.String("CLOUDFRONT"),
	// 	}
	// 	webAcls, listErr := wafClient.ListWebACLs(listWebAclsInput)
	// 	require.NoError(t, listErr, "Failed to list WAF Web ACLs")

	// 	// Debug: Print all webAcl summaries
	// 	t.Logf("DEBUG - Total WebACLs found: %d", len(webAcls.WebACLs))
	// 	for i, webAclSummary := range webAcls.WebACLs {
	// 		t.Logf("DEBUG - WebACL[%d] Summary: %+v", i, webAclSummary)
	// 		t.Logf("DEBUG - WebACL[%d] ID: %s", i, *webAclSummary.Id)
	// 		t.Logf("DEBUG - WebACL[%d] Name: %s", i, *webAclSummary.Name)
	// 		t.Logf("DEBUG - WebACL[%d] ARN: %s", i, *webAclSummary.ARN)
	// 	}

	// 	// Find WAF by ID
	// 	var foundWebAcl *wafv2.WebACL
	// 	for _, webAclSummary := range webAcls.WebACLs {
	// 		t.Logf("DEBUG - Comparing WebACL ID: %s with target ID: %s", *webAclSummary.Id, *webAclId)
	// 		if strings.Contains(*webAclId, *webAclSummary.Id) {
	// 			t.Logf("DEBUG - Found matching WebACL: %+v", webAclSummary)
	// 			//webAcl, err = wafClient.GetWebACL(getWebAclInput)
	// 			//require.NoError(t, err, "Failed to get WAF Web ACL details")
	// 			foundWebAcl = webAcl.WebACL
	// 			break
	// 		}
	// 	}
	// 	require.NotNil(t, foundWebAcl, "WAF Web ACL should be found")
	// }

	// require.NotNil(t, webAcl.WebACL, "WAF Web ACL should not be nil")

	// // Verify WAF has rules
	// assert.Greater(t, len(webAcl.WebACL.Rules), 0, "WAF should have at least one rule")

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

	// Create AWS session
	sess := createAWSSession(t, awsRegion)
	s3Client := s3.New(sess)

	// Verify log bucket exists
	headBucketInput := &s3.HeadBucketInput{
		Bucket: aws.String(logBucketName),
	}

	_, err := s3Client.HeadBucket(headBucketInput)
	require.NoError(t, err, "Log bucket should exist")

	// Create AWS session for us-east-1 (CloudFront is global but API is in us-east-1)
	sessCF := createAWSSession(t, "us-east-1")
	cloudfrontClient := cloudfront.New(sessCF)

	// Get distribution details to verify logging configuration
	getDistributionInput := &cloudfront.GetDistributionInput{
		Id: aws.String(distributionId),
	}

	distribution, err := cloudfrontClient.GetDistribution(getDistributionInput)
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

	// // Create AWS session
	// sess := createAWSSession(t, awsRegion)
	// s3Client := s3.New(sess)

	// // Create a test file in S3 bucket
	// testContent := "Hello from CloudFront test!"
	// testKey := "test-file.txt"

	// putObjectInput := &s3.PutObjectInput{
	// 	Bucket: aws.String(s3BucketName),
	// 	Key:    aws.String(testKey),
	// 	Body:   strings.NewReader(testContent),
	// }

	// _, err := s3Client.PutObject(putObjectInput)
	// require.NoError(t, err, "Failed to put test object in S3 bucket")

	// Clean up the test file after the test
	// defer func() {
	// 	deleteObjectInput := &s3.DeleteObjectInput{
	// 		Bucket: aws.String(s3BucketName),
	// 		Key:    aws.String(testKey),
	// 	}
	// 	s3Client.DeleteObject(deleteObjectInput)
	// }()

	// Wait a bit for CloudFront to propagate
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
