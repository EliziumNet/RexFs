
function convert-ActionResult {
  param(
    [Parameter()]
    [object]$Result
  )

  [PSCustomObject]$actionResult = if ($Result -is [PSCustomObject]) {
    if (($null -ne ${Result}.Success) -and $Result.Success) {
      if (($null -ne ${Result}.Payload)) {
        [string]::IsNullOrEmpty($Result.Payload) ? $(
          $EmptyActionResult;
        ) : $($Result);
      }
      else {
        $EmptyActionResult;
      }
    }
    else {
      if (($null -ne ${Result}.Payload)) {
        [string]::IsNullOrEmpty($Result.Payload) ? $(
          $EmptyActionResult;
        ) : $(
          [PSCustomObject]@{
            PayLoad = $Result.Payload;
            Success = $true;
          }
        );
      }
      else {
        if (($null -ne ${Result}.FailedReason)) {
          [string]::IsNullOrEmpty($Result.FailedReason) ? $(
            $EmptyActionResult;
          ) : $(
            [PSCustomObject]@{
              FailedReason = $Result.FailedReason;
              Success = $false
            }
          ); #
        }
        else {
          $EmptyActionResult;
        }
      }
    }
  }
  elseif ($Result -is [string]) {
    [string]::IsNullOrEmpty($Result) ? $(
      $EmptyActionResult;
    ) : $(
      [PSCustomObject]@{
        Payload = $Result;
        Success = $true;
      }
    );
  }
  else {
    [PSCustomObject]@{
      FailedReason = "Unsupported action result type (type: '$($Result.GetType())')";
      Success      = $false;
    }
  }

  return $actionResult;
}
