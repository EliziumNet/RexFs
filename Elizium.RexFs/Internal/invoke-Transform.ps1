
function invoke-Transform {

  param(
    [Parameter()]
    [hashtable]$Exchange,

    [Parameter()]
    [string]$Value
  )

  [PSCustomObject]$actionResult = try {
    if ($Exchange.ContainsKey("$($Remy_EXS).TRANSFORM")) {
      [scriptblock]$transform = $Exchange["$($Remy_EXS).TRANSFORM"];

      if ($transform) {
        [string]$transformed = $transform.InvokeReturnAsIs(
          $Value,
          $Exchange
        );

        if (-not([string]::IsNullOrEmpty($transformed))) {
          [PSCustomObject]@{
            Payload = $transformed;
            Success      = $true;
          } 
        }
        else {
          [PSCustomObject]@{
            FailedReason = 'Transform returned empty';
            Success      = $false;
          }
        }
      }
      else {
        [PSCustomObject]@{
          FailedReason = 'Internal error, transform missing';
          Success      = $false;
        }
      }
    }
  }
  catch {
    $errorReason = invoke-HandleError -message $_.Exception.Message -prefix 'Transform';

    [PSCustomObject]@{
      FailedReason = $errorReason;
      Success      = $false;
    }
  }

  return $actionResult;
}
