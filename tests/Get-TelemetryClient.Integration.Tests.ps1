# http://stackoverflow.com/questions/1183183/path-of-currently-executing-powershell-script
$root = Split-Path $MyInvocation.MyCommand.Path -Parent;

if($global:AzureAppInsightsTelemetryInvokePester -eq $null -or $global:AzureAppInsightsTelemetryInvokePester -eq $false) {
	Import-Module AzureAppInsightsTelemetry -Force
	Import-Module Pester
}

Describe -Tag "Unit","Public" -Name "Get-TelemetryClient" {

	BeforeAll {
	}
	
	InModuleScope "AzureAppInsightsTelemetry" {

		It "Can Create Client" {
			$client = Get-TelemetryClient -ApplicationInsightsKey 8b2c1873-3e6b-4c16-abe3-240722e1ae86
			$client.Client | Should -Not -Be $null
		}

	}

	AfterAll {
		$global:AzureAppInsightsTelemetry.Variable1 = $originalVariable1;
	}

}
