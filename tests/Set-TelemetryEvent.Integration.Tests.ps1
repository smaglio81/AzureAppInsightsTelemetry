if($null -eq $global:AzureAppInsightsTelemetryInvokePester  -or $global:AzureAppInsightsTelemetryInvokePester -eq $false) {
	Import-Module AzureAppInsightsTelemetry -Force
	Import-Module Pester
}

Describe -Tag "Integration","Public" -Name "Set-TelemetryEvent" {

	BeforeAll {
	}
	
	InModuleScope "AzureAppInsightsTelemetry" {

		It "Send Event Data" {
			$wrapper = Get-TelemetryClient -ApplicationInsightsKey 8b2c1873-3e6b-4c16-abe3-240722e1ae86
			$wrapper.Client | Should -Not -Be $null -Because "client was not created successfully"

			Set-TelemetryEvent `
				-ClientWrapper $wrapper `
				-EventName "UnitTest.Set-TelemetryEvent" `
				-Properties @{ Environment = "Local"; TestName = "Send Event Data" } `
				-Metrics @{ 'TestDuration' = 0 }
				
			# no exceptions is a successful test
		}

	}

	AfterAll {
	}

}
