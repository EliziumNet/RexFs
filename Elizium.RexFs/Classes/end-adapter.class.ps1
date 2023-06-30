
class EndAdapter {
  [System.IO.FileSystemInfo]$_fsInfo;
  [boolean]$_isDirectory;
  [string]$_adjustedName;
  [PSCustomObject]$_extensions

  EndAdapter([System.IO.FileSystemInfo]$fsInfo, [PSCustomObject]$Extensions) {
    $this._fsInfo = $fsInfo;
    $this._isDirectory = ($fsInfo.Attributes -band
      [System.IO.FileAttributes]::Directory) -eq [System.IO.FileAttributes]::Directory;

    $this._adjustedName = $this._isDirectory ? $fsInfo.Name `
      : [System.IO.Path]::GetFileNameWithoutExtension($this._fsInfo.Name);
    $this._extensions = $Extensions
  }

  [string] GetAdjustedName() {
    return $this._adjustedName;
  }

  [string] GetNameWithExtension([string]$newName) {
    [string]$extension = [System.IO.Path]::GetExtension($this._fsInfo.Name)
    if (-not(($this._isDirectory))) {
      $extension = $extension.Substring(1)
    }

    [string]$normalised = $this._extensions.Normalise ? $this.Normalise($extension) : $extension;
    [string]$result = ($this._isDirectory) ? $newName `
      : $("$($newName).$($normalised)")

    return $result;
  }

  [string] GetNameWithExtension([string]$newName, [string]$extension) {
    [string]$normalised = $this._extensions.Normalise ? $this.Normalise($extension) : $extension;
    [string]$result = ($this._isDirectory) ? $newName `
      : $("$($newName).$($normalised)");

    return $result;
  }

  [string] Normalise([string]$extension) {
    [string]$result = $extension

    if ($this._extensions.ToLower) {
      $result = $result.ToLower()
    }
    if ($this._extensions.Remap.ContainsKey($result)) {
      $result = $this._extensions.Remap[$result]
    }
    return $result;
  }
}

function New-EndAdapter {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions',
    '', Justification = 'Not a state changing function, its a factory')]
  param(
    [Parameter()]
    [System.IO.FileSystemInfo]$fsInfo,

    [Parameter()]
    [PSCustomObject]$Extensions
  )
  return [EndAdapter]::new($fsInfo, $Extensions);
}
