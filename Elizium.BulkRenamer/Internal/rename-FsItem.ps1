
function rename-FsItem {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter()]
    [System.IO.FileSystemInfo]$From,

    [Parameter()]
    [string]$To,

    [Parameter()]
    [AllowNull()]
    [UndoRename]$UndoOperant
  )
  [boolean]$itemIsDirectory = ($From.Attributes -band
    [System.IO.FileAttributes]::Directory) -eq [System.IO.FileAttributes]::Directory;

  [string]$parentPath = $itemIsDirectory ? $From.Parent.FullName : $From.Directory.FullName;
  [string]$destinationPath = Join-Path -Path $parentPath -ChildPath $To;

  if (-not($PSBoundParameters.ContainsKey('WhatIf') -and $PSBoundParameters['WhatIf'])) {
    try {
      [boolean]$differByCaseOnly = $From.Name.ToLower() -eq $To.ToLower();

      if ($differByCaseOnly) {
        # Just doing a double rename to get around the problem of not being able to rename
        # an item unless the case is different
        #
        [string]$tempName = $From.Name + "_";

        Rename-Item -LiteralPath $From.FullName -NewName $tempName -PassThru | `
          Rename-Item -NewName $To;
      }
      else {
        Rename-Item -LiteralPath $From.FullName -NewName $To;
      }

      if ($UndoOperant) {
        [PSCustomObject]$operation = [PSCustomObject]@{
          Directory = $parentPath;
          From      = $From.Name;
          To        = $To;
        }
        Write-Debug "rename-FsItem (Undo Rename) => alert: From: '$($operation.From.Name)', To: '$($operation.To)'";
        $UndoOperant.alert($operation);
      }

      $result = Get-Item -LiteralPath $destinationPath;
    }
    catch [System.IO.IOException] {
      $result = $null;
    }
  }
  else {
    $result = $To;
  }

  return $result;
} # rename-FsItem
