package vpc

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-modules-swfw-tests-skeleton/pkg/testskeleton"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"gotest.tools/v3/assert"
)

func checkIfTerraformVersionIsSupported(t *testing.T) bool {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: ".",
		Logger:       logger.Discard,
		Lock:         true,
	})
	_, err := terraform.InitE(t, terraformOptions)
	if err != nil {
		assert.ErrorContains(t, err, "Unsupported Terraform Core version")
		return false
	}
	return true
}

func TestValidate(t *testing.T) {
	if checkIfTerraformVersionIsSupported(t) {
		testskeleton.ValidateCode(t, nil)
	}
}
