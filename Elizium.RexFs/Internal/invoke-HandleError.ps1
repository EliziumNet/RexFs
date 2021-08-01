
function invoke-HandleError {
  param(
    [Parameter()]
    [string]$message,

    [Parameter()]
    [string]$prefix,

    [Parameter()]
    [string]$reThrowIfMatch = 'Expected strings to be the same, but they were different'
  )

  [string]$errorReason = $(
    "$prefix`: " +
    ($message -split '\n')[0]
  );
  # We need Pester to throw pester specific errors. In the lack of, we have to
  # guess that its a Pester assertion failure and let the exception through so
  # the test fails.
  #
  if ($errorReason -match $reThrowIfMatch) {
    throw $_;
  }

  return $errorReason;
}
