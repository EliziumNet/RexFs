
Describe 'convert-ActionResult' {
  BeforeAll {
    Get-Module Elizium.RexFs | Remove-Module -Force;
    Import-Module .\Output\Elizium.RexFs\Elizium.RexFs.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;
  }

  Context 'given: <Scenario> <Result>' {
    It 'should: return result with Success = <ExpectedSuccess>' -TestCases @(
      # string results
      #
      @{
        Scenario        = 'Positive string result';
        Result          = 'affirmative';
        ExpectedSuccess = $true;
      }

      , @{
        Scenario        = 'Negative empty string result';
        Result          = [string]::Empty;
        ExpectedSuccess = $false;
      }

      # PSCustomObject results
      #
      , @{
        Scenario        = 'Positive PSCustomObject result (missing Success)';
        Result          = [PSCustomObject]@{ Payload = 'affirmative'; }
        ExpectedSuccess = $true;
      }

      , @{
        Scenario        = 'Positive PSCustomObject result (WITH Success)';
        Result          = [PSCustomObject]@{ Payload = 'affirmative'; Success = $true; }
        ExpectedSuccess = $true;
      }

      , @{
        Scenario        = 'Negative PSCustomObject result (WITH FailedReason, Success)';
        Result          = [PSCustomObject]@{ FailedReason = 'Sky is falling'; Success = $false }
        ExpectedSuccess = $false;
      }

      , @{
        Scenario        = 'Negative PSCustomObject result (WITH FailedReason, missing Success)';
        Result          = [PSCustomObject]@{ FailedReason = 'Sky is falling'; }
        ExpectedSuccess = $false;
      }

      , @{
        Scenario        = 'Faked success (missing Payload)';
        Result          = [PSCustomObject]@{ Success = $true }
        ExpectedSuccess = $false;
      }

      # invalid results
      #
      , @{
        Scenario        = 'Unsupported return type (hashtable)';
        Result          = @{ Success = $true }
        ExpectedSuccess = $false;
      }
    ) {
      InModuleScope Elizium.RexFs -Parameters @{ Scenario = $Scenario; Result = $Result; ExpectedSuccess = $ExpectedSuccess; } {
        param(
          [string]$Scenario,
          [object]$Result,
          [boolean]$ExpectedSuccess
        )

        [PSCustomObject]$actionResult = convert-ActionResult -Result $Result;
        $($null -ne ${actionResult}.Success) | Should -BeTrue -Because $Scenario;
        $actionResult.Success | Should -Be $ExpectedSuccess;

        $($null -ne ${actionResult}.Payload) -xor $(
          $null -ne ${actionResult}.FailedReason
        ) | Should -BeTrue -Because $Scenario;
      }
    }
  }
}
