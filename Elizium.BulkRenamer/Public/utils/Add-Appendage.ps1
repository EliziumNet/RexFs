
function Add-Appendage {
  <#
  .NAME
    Add-Appendage

  .SYNOPSIS
    The core appendage action function principally used by Rename-Many. Adds either
  a prefix or suffix to the Value.

  .DESCRIPTION
    Returns a new string that reflects the addition of an appendage, which can be Prepend
  or Append. The appendage itself can be static text, or can act like a formatter supporting
  Copy named group reference s, if present. The user can decide to reference the whole Copy
  match with ${_c}, or if it contains named captures, these can be referenced inside the
  appendage as ${<group-name-ref>}

  .LINK
    https://eliziumnet.github.io/Loopz/

  .PARAMETER Value
    The source value against which regular expressions are applied.

  .PARAMETER Appendage
    String to either prepend or append to Value. Supports named captures inside Copy regex
  parameter.

  .PARAMETER Type
    Denotes the appendage type, can be 'Prepend' or 'Append'.

  .PARAMETER Copy
    Regular expression string applied to $Value, indicating a portion which should be copied and
  inserted into the Appendage. The match defined by $Copy is stored in special variable ${_c} and
  can be referenced as such from $Appendage.

  .PARAMETER CopyOccurrence
    Can be a number or the letters f, l
  * f: first occurrence
  * l: last occurrence
  * <number>: the nth occurrence

  .PARAMETER Diagnose
    switch parameter that indicates the command should be run in WhatIf mode. When enabled
  it presents additional information that assists the user in correcting the un-expected
  results caused by an incorrect/un-intended regular expression. The current diagnosis
  will show the contents of named capture groups that they may have specified. When an item
  is not renamed (usually because of an incorrect regular expression), the user can use the
  diagnostics along side the 'Not Renamed' reason to track down errors.

  #>
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [string]$Value,

    [Parameter(Mandatory)]
    [string]$Appendage,

    [Parameter(Mandatory)]
    [ValidateSet('Prepend', 'Append')]
    [string]$Type,

    [Parameter()]
    [System.Text.RegularExpressions.RegEx]$Copy,

    [Parameter()]
    [ValidateScript( { ($_ -ne '*') -and ($_ -ne '0') })]
    [string]$CopyOccurrence = 'f',

    [Parameter()]
    [switch]$Diagnose
  )

  [string]$failedReason = [string]::Empty;
  [string]$result = [string]::Empty;
  [PSCustomObject]$groups = [PSCustomObject]@{
    Named = @{}
  }

  if ($PSBoundParameters.ContainsKey('Copy')) {
    if ($Value -match $Copy) {
      [string]$appendageContent = $Appendage;
      [hashtable]$parameters = @{
        'Source'       = $Value
        'PatternRegEx' = $Copy
        'Occurrence'   = ($PSBoundParameters.ContainsKey('CopyOccurrence') ? $CopyOccurrence : 'f')
      }

      # With this implementation, it is up to the user to supply a regex proof
      # pattern, so if the Copy contains regex chars which must be treated literally, they
      # must pass in the string pre-escaped: -Copy $(esc('some-pattern') + 'other stuff').
      #
      [string]$capturedCopy, $null, `
        [System.Text.RegularExpressions.Match]$copyMatch = Split-Match @parameters;

      [Hashtable]$copyCaptures = get-Captures -MatchObject $copyMatch;

      if ($Diagnose.ToBool()) {
        $groups.Named['Copy'] = $copyCaptures;
      }
      $appendageContent = $appendageContent.Replace('${_c}', $capturedCopy);

      # Now cross reference the Copy group references
      #
      $appendageContent = Update-GroupRefs -Source $appendageContent -Captures $copyCaptures;

      $result = if ($Type -eq 'Prepend') {
        $($appendageContent + $Value);
      }
      elseif ($Type -eq 'Append') {
        $($Value + $appendageContent);
      }
    }
    else {
      # Copy doesn't match so abort and return unmodified source
      #
      $failedReason = 'Copy Match';
    }
  }
  else {
    $result = if ($Type -eq 'Prepend') {
      $($Appendage + $Value);
    }
    elseif ($Type -eq 'Append') {
      $($Value + $Appendage);
    }
    else {
      throw [System.Management.Automation.MethodInvocationException]::new(
        "Add-Appendage: Invalid Appendage Type: '$Type', Appendage: '$Appendage'");
    }
  }

  [boolean]$success = $([string]::IsNullOrEmpty($failedReason));
  if (-not($success)) {
    $result = $Value;
  }

  [PSCustomObject]$appendageResult = [PSCustomObject]@{
    Payload = $result;
    Success = $success;
  }

  if (-not([string]::IsNullOrEmpty($failedReason))) {
    $appendageResult | Add-Member -MemberType NoteProperty -Name 'FailedReason' -Value $failedReason;
  }

  if ($Diagnose.ToBool() -and ($groups.Named.Count -gt 0)) {
    $appendageResult | Add-Member -MemberType NoteProperty -Name 'Diagnostics' -Value $groups;
  }

  return $appendageResult;
}
