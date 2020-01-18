if($null -eq $global:AzureAppInsightsTelemetryInvokePester  -or $global:AzureAppInsightsTelemetryInvokePester -eq $false) {
	Import-Module AzureAppInsightsTelemetry -Force
	Import-Module Pester
}

Describe -Tag "Integration","Public" -Name "Get-TelemetryClient" {

	BeforeAll {
	}
	
	InModuleScope "AzureAppInsightsTelemetry" {

		It "Can Create Client" {
			$wrapper = Get-TelemetryClient -ApplicationInsightsKey 8b2c1873-3e6b-4c16-abe3-240722e1ae86
			$wrapper.Client | Should -Not -Be $null
		}

	}

	AfterAll {
	}

}
