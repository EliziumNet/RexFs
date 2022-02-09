
function Rename-ByNo {
  [CmdletBinding(SupportsShouldProcess)]
  [Alias("reno")]
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)]
    [System.IO.FileSystemInfo]$InputObject,

    [Parameter()]
    [Alias('fm')]
    [string]$Format,

    [Parameter()]
    [scriptblock]$Compute = ({
        [OutputType([int])]
        param(
          [int]$number
        )
        return $number;
      }),

    [Parameter()]
    [Alias('x')]
    [string]$Except,

    [Parameter()]
    [Alias('i')]
    [string]$Include,

    [Parameter()]
    [Alias('t')]
    [ValidateScript( { $_ -gt 0 } )]
    [int]$Top,

    [Parameter()]
    [Alias("dg")]
    [switch]$Diagnose,

    [Parameter()]
    [switch]$Test
  )

  begin {
    [string]$pattern = $global:RexFs.Defaults.Reno.Pattern;

    if ($Format -notMatch $pattern) {
      # PS: can't use $global:RexFs.Defaults.Reno.Pattern as parameter validator, so
      # validate manually
      #  
      throw "bad format defined for As, which does't match '$pattern'"
    }

    [regex]$rexo = New-RegularExpression -Expression $pattern;
    Write-Debug ">>> Rename-Many [ParameterSet: '$($PSCmdlet.ParameterSetName)]' >>>";

    [System.Collections.Generic.List[System.IO.FileSystemInfo]]$collection = @();
  }

  process {
    $collection.Add($_);
  }

  end {
    function get-PaddedValue {
      <#
      .NAME
        get-PaddedValue

      .SYNOPSIS
        Controls and standardises the way that signals are displayed.

      .DESCRIPTION
        Pads out a string with leading or trailing spaces depending on
      alignment.

      .PARAMETER Align
        Left or right alignment of the label.

      .PARAMETER Label
        The string to be padded

      .PARAMETER Width
        Size of the field into which the label is to be placed.
      #>
      [OutputType([string])]
      param(
        [Parameter()]
        [string]$Label,

        [Parameter()]
        [string]$Align = "right",

        [Parameter()]
        [int]$Width,

        [Parameter()]
        [char]$with = " "
      )
      [int]$length = $Label.Length;

      [string]$result = if ($length -lt $Width) {
        [string]$padding = [string]::new($with, $($Width - $length));
        ($Align -eq "right") ? $($padding + $Label) : $($Label + $padding);
      }
      else {
        $Label;
      }

      $result;
    }

    [PSCustomObject]$context = [PSCustomObject]@{
      Title             = "Renumber";
      ItemMessage       = "Renumber Item";
      SummaryMessage    = "Renumber Summary";
      Locked            = "REXFS_REMY_LOCKED";
      UndoDisabledEnVar = "REXFS_REMY_UNDO_DISABLED";
      OperantShortCode  = "reno";
    }

    [scriptblock]$transform = {
      param(
        [Parameter()]
        [string]$name,

        [Parameter()]
        [hashtable]$exchange
      )

      [string]$capturedPattern, $removed, [System.Text.RegularExpressions.Match]$patternMatch = `
        Split-Match -Source $Format -PatternRegEx $rexo;

      [string]$result = if (-not([string]::IsNullOrEmpty($capturedPattern))) {
        [Hashtable]$captures = Get-Captures -MatchObject $patternMatch;
        $nCapture = $captures["n"];
        $padCapture = $captures["pad"];

        [string]$pad = $(
          $padCapture.Success ? $padCapture.Value : $global:RexFs.Defaults.Reno.Pad 
        )

        [int]$fieldWidth = $(
          $nCapture.Success ? $($nCapture.Value -as [int]) : $($global:RexFs.Defaults.Reno.Width)
        );

        [int]$sequenceNo = $exchange["LOOPZ.FOREACH.INDEX"] + 1;
        [int]$computed = $Compute.InvokeReturnAsIs($sequenceNo);
        [string]$padded = get-PaddedValue -Label $computed.ToString() -Width $fieldWidth -With $pad;

        $rexo.Replace($Format, $padded);
      }
      else {
        $name;
      }

      return $result;
    }

    [hashtable]$parameters = @{
      "Context"   = $context;
      "Transform" = $transform;
    }
    if ($PSBoundParameters["WhatIf"]) {
      $parameters["WhatIf"] = $true;
    }
    if ($PSBoundParameters["Diagnose"]) {
      $parameters["Diagnose"] = $true;
    }
    if ($Test.IsPresent) {
      $parameters["Test"] = $true;
    }
    if ($PSBoundParameters["Except"]) {
      $parameters["Except"] = $Except;
    }
    if ($PSBoundParameters["Include"]) {
      $parameters["Include"] = $Include;
    }
    if ($PSBoundParameters["Top"]) {
      $parameters["Top"] = $Top;
    }

    $collection | Rename-Many @parameters;
  }
}
