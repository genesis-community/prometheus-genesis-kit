package spec_test

import (
	"path/filepath"
	"runtime"

	. "github.com/genesis-community/testkit/v2/testing"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = BeforeSuite(func() {
	_, filename, _, _ := runtime.Caller(0)
	KitDir, _ = filepath.Abs(filepath.Join(filepath.Dir(filename), "../"))
})

var _ = Describe("Prometheus Kit", func() {

	Describe("prometheus", func() {
		Test(Environment{
			Name:        "base",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "base",
		})
		Test(Environment{
			Name:        "basecert",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "basecert",
		})
		Test(Environment{
			Name:        "monitorcf",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "monitorcf",
		})
		Test(Environment{
			Name:        "monitorcf-mismatch",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "monitorcf-mismatch",
			OutputMatchers: OutputMatchers{
				GenesisAddSecrets: ContainSubstring("legacy-firehose is not available for cf v2.x deployments"),
				GenesisCheck:      ContainSubstring("legacy-firehose is not available for cf v2.x deployments"),
				GenesisManifest:   ContainSubstring("legacy-firehose is not available for cf v2.x deployments"),
			},
		})
		Test(Environment{
			Name:        "monitorcf-v2",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "monitorcf-v2",
		})
		Test(Environment{
			Name:        "monitorch",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "monitorch",
		})
		Test(Environment{
			Name:        "resolute",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "resolute",
		})
		Test(Environment{
			Name:        "resolute-mgmt",
			CloudConfig: "aws-resolute-mgmt",
			CPI:         "aws",
		})
		Test(Environment{
			Name:        "resolute-wrong-stemcell-os",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "resolute-wrong-stemcell-os",
			OutputMatchers: OutputMatchers{
				GenesisAddSecrets: ContainSubstring("stemcell os to"),
				GenesisCheck:      ContainSubstring("stemcell os to"),
				GenesisManifest:   ContainSubstring("stemcell os to"),
			},
		})
		Test(Environment{
			Name:        "resolute-stemcell-without-feature",
			CloudConfig: "aws",
			CPI:         "aws",
			Exodus:      "resolute-stemcell-without-feature",
			OutputMatchers: OutputMatchers{
				GenesisAddSecrets: ContainSubstring("Enable the feature and remove that parameter"),
				GenesisCheck:      ContainSubstring("Enable the feature and remove that parameter"),
				GenesisManifest:   ContainSubstring("Enable the feature and remove that parameter"),
			},
		})
	})

})
