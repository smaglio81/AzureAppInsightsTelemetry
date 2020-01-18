if($null -eq $global:AzureAppInsightsTelemetryInvokePester  -or $global:AzureAppInsightsTelemetryInvokePester -eq $false) {
	Import-Module AzureAppInsightsTelemetry -Force
	Import-Module Pester
}

Describe -Tag "Integration","Public" -Name "Set-TelemetryException" {

	BeforeAll {
	}
	
	InModuleScope "AzureAppInsightsTelemetry" {

		It "Send Exception Data" {
			$wrapper = Get-TelemetryClient -ApplicationInsightsKey 8b2c1873-3e6b-4c16-abe3-240722e1ae86
			$wrapper.Client | Should -Not -Be $null -Because "client was not created successfully"

			$e = $null
			try {
				throw "Unit Test Exception"
			} catch {
				$e = $_
				if($null -ne $Error[0]) {
					$Error.RemoveAt(0)
				}
			}

			Set-TelemetryException `
				-ClientWrapper $wrapper `
				-Exception $e.Exception `
				-Properties @{ Environment = "Local"; TestName = "Send Exception Data" }
				
			# no exceptions is a successful test
		}

	}

	AfterAll {
	}

}
