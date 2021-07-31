
function invoke-PostProcessing {
  param(
    [Parameter()]
    [string]$InputSource,

    [Parameter()]
    [PSCustomObject[]]$Rules,

    [Parameter()]
    [hashtable]$signals
  )
  [string]$transformResult = $InputSource;

  [string[]]$appliedSignals = foreach ($rule in $Rules) {
    if ($rule['IsApplicable'].InvokeReturnAsIs($transformResult)) {
      $transformResult = $rule['Transform'].InvokeReturnAsIs($transformResult);
      $rule['Signal'];
    }
  }

  [PSCustomObject]$result = if ($appliedSignals.Count -gt 0) {
    [System.Collections.Generic.List[string]]$labels = [System.Collections.Generic.List[string]]::new()

    [string]$indication = -join $(foreach ($name in $appliedSignals) {
      $labels.Add($signals[$name].Key);
      $signals[$name].Value;
    })
    $indication = "[{0}]" -f $indication;

    [PSCustomObject]@{
      TransformResult = $transformResult;
      Indication      = $indication;
      Signals         = $appliedSignals;
      Label           = 'Post ({0})' -f $($labels -join ', ');
      Modified        = $true;
    }
  }
  else {
    [PSCustomObject]@{
      TransformResult = $InputSource;
      Modified        = $false;
    }
  }

  $result;
}
