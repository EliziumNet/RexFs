
function test-RenameExpect {
  param(
    [Parameter(Position = 0)][HashTable]$Expects,
    [Parameter(Position = 1)][string]$Item,
    [Parameter(Position = 2)][string]$Actual
  )
  if ($Expects.ContainsKey($Item)) {
    Write-Debug "test-expect; EXPECT: '$($Expects[$Item])'";
    Write-Debug "test-expect; ACTUAL: '$Actual'";
    $Actual | Should -BeExactly $Expects[$Item];
  }
  else {
    $false | Should -BeTrue -Because "Bad test!!, Item: '$Item' not defined in Expects";
  }
}
