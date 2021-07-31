
function new-expr {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
  param(
    [Parameter(Position = 0, Mandatory)]
    [string]$Expression
  )
  New-Object -TypeName System.Text.RegularExpressions.RegEx -ArgumentList ($Expression);
}
