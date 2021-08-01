
[array]$remySignals = @(
  'ABORTED-A', 'APPEND', 'BECAUSE', 'CAPTURE', 'CLASH', 'COPY-A', 'CUT-A', 'DIAGNOSTICS',
  'DIRECTORY-A', 'EXCLUDE', 'FILE-A', 'INCLUDE', 'LOCKED', 'MULTI-SPACES', 'NOT-ACTIONED',
  'NOVICE', 'PASTE-A', 'PATTERN', 'PREPEND', 'REMY.ANCHOR', 'REMY.ANCHOR', 'REMY.DROP',
  'REMY.POST', 'REMY.UNDO', 'TRANSFORM', 'TRIM', 'WHAT-IF', 'WITH'
);

Register-CommandSignals -Alias 'remy' -UsedSet $remySignals -Silent;

New-Variable -Name Remy_EXS -Value 'REXFS.REMY' -Scope Script -Option ReadOnly -Force;

New-Variable -Name EmptyActionResult -Scope Script -Option ReadOnly -Force -Value $([PSCustomObject]@{
    FailedReason = 'Empty action result';
    Success      = $false;
  });
