<#
	Pester Unit Tests for Validate-ISBN function in resources\libfunctions.ps1
#>

Describe 'Validate-ISBN' {
	
	BeforeAll {
		. $PSSCRIPTROOT\..\resources\libfunctions.ps1
	}

	It 'Given $null input as ISBN, result should be false' {
		$result = Validate-ISBN $null
		$result | Should Be $false
	}
	It 'Given empty input ISBN, result should be false' {
		$result = Validate-ISBN ""
		$result | Should Be $false
	}
	It 'Given partial ISBN, result should be false' {
		$result = Validate-ISBN "928423"
		$result | Should Be $false
	}
	It 'Given 10 digit ISBN containing alpha characters, result should be false' {
		$result = Validate-ISBN "9284X23563"
		$result | Should Be $false
	}
	It 'Given 13 digit ISBN containing alpha characters, result should be false' {
		$result = Validate-ISBN "9284X23563562"
		$result | Should Be $false
	}
	It 'Given 10 digit ISBN, result should be true' {
		$result = Validate-ISBN "9284223563"
		$result | Should Be $true
	}
	It 'Given 10 digit ISBN (ending in X), result should be true' {
		$result = Validate-ISBN "928422356X"
		$result | Should Be $true
	}
	It 'Given 10 digit ISBN (ending in Z), result should be false' {
		$result = Validate-ISBN "928422356Z"
		$result | Should Be $false
	}
	It 'Given 13 digit ISBN, result should be true' {
		$result = Validate-ISBN "9284423563562"
		$result | Should Be $true
	}
}
