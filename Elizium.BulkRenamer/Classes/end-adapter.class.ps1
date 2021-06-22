
class EndAdapter {
  [System.IO.FileSystemInfo]$_fsInfo;
  [boolean]$_isDirectory;
  [string]$_adjustedName;

  EndAdapter([System.IO.FileSystemInfo]$fsInfo) {
    $this._fsInfo = $fsInfo;
    $this._isDirectory = ($fsInfo.Attributes -band
      [System.IO.FileAttributes]::Directory) -eq [System.IO.FileAttributes]::Directory;

    $this._adjustedName = $this._isDirectory ? $fsInfo.Name `
      : [System.IO.Path]::GetFileNameWithoutExtension($this._fsInfo.Name);
  }

  [string] GetAdjustedName() {
    return $this._adjustedName;
  }

  [string] GetNameWithExtension([string]$newName) {
    [string]$result = ($this._isDirectory) ? $newName `
      : ($newName + [System.IO.Path]::GetExtension($this._fsInfo.Name));

    return $result;
  }

  [string] GetNameWithExtension([string]$newName, [string]$extension) {
    [string]$result = ($this._isDirectory) ? $newName `
      : ($newName + $extension);

    return $result;
  }
}

function New-EndAdapter {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions',
    '', Justification = 'Not a state changing function, its a factory')]
  param(
    [System.IO.FileSystemInfo]$fsInfo
  )
  return [EndAdapter]::new($fsInfo);
}