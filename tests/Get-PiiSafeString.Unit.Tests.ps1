if($null -eq $global:AzureAppInsightsTelemetryInvokePester  -or $global:AzureAppInsightsTelemetryInvokePester -eq $false) {
	Import-Module AzureAppInsightsTelemetry -Force
	Import-Module Pester
}

Describe -Tag "Unit","Public" -Name "Get-PiiSafeString" {

	BeforeAll {
	}
	
	InModuleScope "AzureAppInsightsTelemetry" {

		It "Obfuscate" {
			$safeString = Get-PiiSafeString -PlainText "something"
			$safeString | Should -Be "983D43DDFF6DA90F6A5D3B6172446A1FFE228B803FE64FDD5DCFAB5646078A896851FE82F623C9D6E5654B3D2F363A04EC17CFB62B607437A9C7C132D511E522"
		}

		It "No Obfuscation" {
			$wrapper = @{ DisablePiiProtection = $true }
			$safeString = Get-PiiSafeString -PlainText "something" -ClientWrapper $wrapper
			$safeString | Should -Be "something"
		}

	}

	AfterAll {
	}

}
