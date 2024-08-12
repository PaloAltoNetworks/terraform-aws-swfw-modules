package vmseries_standalone

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-modules-swfw-tests-skeleton/pkg/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func CreateTerraformOptions(t *testing.T, varFiles []string) *terraform.Options {
	// prepare random prefix
	randomNames, _ := testskeleton.GenerateTerraformVarsInfo("aws")

	// define options for Terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"name_prefix":  randomNames.NamePrefix,
			"ssh_key_name": "test-ssh-key",
		},
		Logger:               logger.Default,
		Lock:                 true,
		Upgrade:              true,
		SetVarsAfterVarFiles: true,
		RetryableTerraformErrors: map[string]string{
			"The specified key does not exist": "Temporary solution for problem with listing tags for S3 (Simple Storage) Object - operation error S3: GetObjectTagging, https response error StatusCode: 404, api error NoSuchKey: The specified key does not exist",
		},
	})

	return terraformOptions
}

func TestValidate(t *testing.T) {
	testskeleton.ValidateCode(t, nil)
}

func TestPlan(t *testing.T) {
	// IPv4
	// define options for Terraform
	terraformOptionsIpv4 := CreateTerraformOptions(t, []string{"example.tfvars"})
	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{}
	// plan test infrastructure and verify outputs
	testskeleton.PlanInfraCheckErrors(t, terraformOptionsIpv4, assertList, "No errors are expected")

	// IPv6
	terraformOptionsIpv6 := CreateTerraformOptions(t, []string{"example_ipv6.tfvars"})
	testskeleton.PlanInfraCheckErrors(t, terraformOptionsIpv6, assertList, "No errors are expected")
}

func TestApply(t *testing.T) {
	// IPv4
	// define options for Terraform
	terraformOptionsIpv4 := CreateTerraformOptions(t, []string{"example.tfvars"})
	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{}
	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputs(t, terraformOptionsIpv4, assertList)

	// IPv6
	terraformOptionsIpv6 := CreateTerraformOptions(t, []string{"example_ipv6.tfvars"})
	testskeleton.DeployInfraCheckOutputs(t, terraformOptionsIpv6, assertList)
}

func TestIdempotence(t *testing.T) {
	// IPv4
	// define options for Terraform
	terraformOptionsIpv4 := CreateTerraformOptions(t, []string{"example.tfvars"})
	// prepare list of items to check
	assertList := []testskeleton.AssertExpression{}
	// deploy test infrastructure and verify outputs and check if there are no planned changes after deployment
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptionsIpv4, assertList)

	//IPv6
	terraformOptionsIpv6 := CreateTerraformOptions(t, []string{"example_ipv6.tfvars"})
	testskeleton.DeployInfraCheckOutputsVerifyChanges(t, terraformOptionsIpv6, assertList)
}
