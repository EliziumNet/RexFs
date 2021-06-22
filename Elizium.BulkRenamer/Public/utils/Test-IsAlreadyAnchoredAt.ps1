
function Test-IsAlreadyAnchoredAt {
  <#
  .NAME
    Test-IsAlreadyAnchoredAt

  .SYNOPSIS
    Checks to see if a given pattern is matched at the start or end of an input string.

  .DESCRIPTION
    When Rename-Many uses the Start or End switches to move a match to the corresponding location,
  it needs to filter out those entries where the specified occurrence of the Pattern is already
  at the desire location. We can't do this using a synthetic anchored regex using ^ and $, rather
  we must use the origin regex, perform the match and then see where that match resides, by consulting
  the index and length of that match instance.

  .LINK
    https://eliziumnet.github.io/Loopz/

  .PARAMETER Source
    The input source

  .PARAMETER Expression
    A regex instance to match against

  .PARAMETER Occurrence
    Which match occurrence in Expression do we want to check

  .PARAMETER Start
    Check match is at the start of the input source

  .PARAMETER End
    Check match is at the end of the input source
  #>
  [OutputType([boolean])]
  param(
    [Parameter()]
    [string]$Source,

    [Parameter()]
    [regex]$Expression,

    [Parameter()]
    [string]$Occurrence,

    [Parameter()]
    [switch]$Start,

    [Parameter()]
    [switch]$End
  )

  [hashtable]$parameters = @{
    'Source'       = $Source;
    'PatternRegEx' = $Expression;
    'Occurrence'   = $Occurrence;
  }

  [string]$capturedExpression, $null, `
    [System.Text.RegularExpressions.Match]$expressionMatch = Split-Match @parameters;

  [boolean]$result = if (-not([string]::IsNullOrEmpty($capturedExpression))) {
    if ($Start.IsPresent) {
      # For the Start, its easy to see if the match is already at the start,
      # we just check the match's index being 0.
      #
      $expressionMatch.Index -eq 0;
    }
    elseif ($End.IsPresent) {
      #          012345
      # source = ABCDEA
      # PATTERN = 'A'
      # OCC = 1
      #
      # In the above example, if we wanted to move the first A to the end, we need
      # to see if that occurrence is at the end, NOT does that pattern appear at the
      # end. The old logic, using a synthesized Anchored regex, performed the latter
      # logic and that's why it failed.  What we want, is to check that our specific
      # Occurrence is not already at the end, which of course it isn't. We do this,
      # by checking the location of our match.
      #
      $($expressionMatch.Index + $expressionMatch.Length) -eq $Source.Length;
    }
    else {
      $false;
    }
  }
  else {
    $false;
  }

  return $result;
}
