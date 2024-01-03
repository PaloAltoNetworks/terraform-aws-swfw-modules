package names_generator

import (
	"testing"

	"github.com/PaloAltoNetworks/terraform-modules-swfw-tests-skeleton/pkg/testskeleton"
)

func TestValidate(t *testing.T) {
	testskeleton.ValidateCode(t, nil)
}
