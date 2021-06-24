# VERSION 0.0.1
using namespace System.Text.RegularExpressions;

task . Clean, Build, Tests, Stats
task Tests ImportCompiledModule, Pester
task CreateManifest CopyPSD, UpdatePublicFunctionsToExport, CopyFileList
task Build Compile, CreateManifest
task Stats RemoveStats, WriteStats
task Ana Analyse
task Fix ApplyFix
task BuildHelp Docs

$script:ModuleName = Split-Path -Path $PSScriptRoot -Leaf;
$script:Core = [PSCustomObject]@{
  ModuleName = $(Split-Path -Path $PSScriptRoot -Leaf);

  # ModuleOut: this represents a module file in the output directory 
  #
  ModuleOut  = Join-Path -Path $PSScriptRoot -ChildPath "Output" -AdditionalChildPath $(
    "$($script:ModuleName)$([System.IO.Path]::DirectorySeparatorChar)$($script:ModuleName)"
  );
  Output     = $(Join-Path -Path $PSScriptRoot -ChildPath 'Output');
}

$script:Properties = [PSCustomObject]@{
  ModuleName          = $($script:Core.ModuleName);
  ModuleRoot          = $PSScriptRoot;
  OutputFolder        = $($script:Core.Output);
  ExternalHelpPath    = $(Join-Path -Path $script:Core.ModuleOut -ChildPath $script:ModuleName -AdditionalChildPath 'en-GB');

  ImportFolders       = @('Public', 'Internal', 'Classes');
  OutPsmPath          = "$($Core.ModuleOut).psm1";
  OutPsdPath          = "$($Core.ModuleOut).psd1";
  ModuleOutPath       = $(Join-Path -Path $PSScriptRoot -ChildPath "Output" -AdditionalChildPath $(
      "$($script:ModuleName)"
    ));

  FinalDirectory      = 'Final';
  PublicFolder        = 'Public';
  DSCResourceFolder   = 'DSCResources';

  SourceOutPsdPath    = $(Join-Path -Path $PSScriptRoot -ChildPath "$($script:Core.ModuleName).psd1");
  TestHelpers         = $(Join-Path -Path $PSScriptRoot -ChildPath 'Tests' -AdditionalChildPath 'Helpers');

  AdditionExportsPath = $(Join-Path -Path $PSScriptRoot -ChildPath 'Init' -AdditionalChildPath 'additional-exports.ps1');

  StatsFile           = $(Join-Path -Path $script:Core.Output -ChildPath 'stats.json');
  FileListDirectory   = $(Join-Path -Path $PSScriptRoot -ChildPath 'FileList');
}

if (Test-Path -Path $script:Properties.TestHelpers) {
  $helpers = Get-ChildItem -Path $script:Properties.TestHelpers -Recurse -File -Filter '*.ps1';
  $helpers | ForEach-Object { Write-Verbose "sourcing helper $_"; . $_; }
}

if (Test-Path -Path $script:Properties.AdditionExportsPath) {
  . $script:Properties.AdditionExportsPath;
}

function Get-AdditionalFnExports {
  [string []]$additional = @()

  try {
    if ($global:AdditionalFnExports -and ($global:AdditionalFnExports -is [array])) {
      $additional = $global:AdditionalFnExports;
    }

    Write-Verbose "---> Get-AdditionalFnExports: $($additional -join ', ')";
  }
  catch {
    Write-Verbose "===> Get-AdditionalFnExports: no 'AdditionalFnExports' found";
  }

  return $additional;
}

function Get-AdditionalAliasExports {
  [string []]$additionalAliases = @();

  try {
    if ($global:AdditionalAliasExports -and ($global:AdditionalAliasExports -is [array])) {
      $additionalAliases = $global:AdditionalAliasExports;
    }
    Write-Verbose "===> Get-AdditionalAliasExports: $($additionalAliases -join ', ')";
  }
  catch {
    Write-Verbose "===> Get-AdditionalAliasExports: no 'AdditionalAliasExports' found";
  }

  return $additionalAliases;
}

function Get-FunctionExportList {
  [string[]]$fnExports = $(
    Get-ChildItem -Path $script:Properties.PublicFolder -Recurse | Where-Object {
      $_.Name -like '*-*' } | Select-Object -ExpandProperty BaseName
  );

  $fnExports += Get-AdditionalFnExports;
  return $fnExports;
}

function Get-PublicFunctionAliasesToExport {
  [string]$expression = 'Alias\((?<aliases>((?<quote>[''"])[\w-]+\k<quote>\s*,?\s*)+)\)';
  [System.Text.RegularExpressions.RegexOptions]$options = 'IgnoreCase, SingleLine';

  [System.Text.RegularExpressions.RegEx]$aliasesRegEx = `
    New-Object -TypeName System.Text.RegularExpressions.RegEx -ArgumentList ($expression, $options);

  [string]$publicPath = $script:Properties.Public;

  [string[]]$aliases = @();

  Get-ChildItem -Recurse -File -Filter '*.ps1' -Path $publicPath | Foreach-Object {
    [string]$content = Get-Content $_;

    [System.Text.RegularExpressions.Match]$contentMatch = $aliasesRegEx.Match($content);

    if ($contentMatch.Success) {
      $al = $contentMatch.Groups['aliases'];
      $al = $($al -split ',' | ForEach-Object { $_.Trim().replace('"', '').replace("'", "") });
      $aliases += $al;
    }
  };

  $aliases += Get-AdditionalAliasExports

  $aliases;
}

task Clean {
  if (-not(Test-Path $script:Properties.OutputFolder)) {
    New-Item -ItemType Directory -Path $script:Properties.OutputFolder > $null
  }
  else {
    $resolvedOutputContents = Resolve-Path $script:Properties.OutputFolder;
    if ($resolvedOutputContents) {
      Remove-Item -Path (Resolve-Path $resolvedOutputContents) -Force -Recurse
    }
  }
}

$compileParams = @{
  Inputs = {
    foreach ($folder in $script:Properties.ImportFolders) {
      Get-ChildItem -Path $folder -Recurse -File -Filter '*.ps1'
    }
  }

  Output = {
    $script:Properties.OutPsmPath
  }
}

task Compile @compileParams {
  if (Test-Path -Path $script:Properties.OutPsmPath) {
    Remove-Item -Path (Resolve-Path $script:Properties.OutPsmPath) -Recurse -Force
  }
  New-Item -Path $script:Properties.OutPsmPath -Force > $null

  # Insert custom module using statements (./Init/using.ps1)
  #
  $initFolder = Join-Path -Path $script:Properties.ModuleRoot -ChildPath 'Init'
  if (Test-Path -Path $initFolder) {
    Write-Verbose "Injecting module using statements";

    $usingPath = Join-Path -Path $initFolder -ChildPath 'using.ps1';

    if (Test-Path -Path $usingPath) {
      $moduleUsingContent = Get-Content -LiteralPath $usingPath;
      $moduleUsingContent >> $script:Properties.OutPsmPath;
    }
  }

  "Set-StrictMode -Version 1.0" >> $script:Properties.OutPsmPath

  # !!!BUG: This should be using whatever is yielded by @compileParams
  #
  foreach ($folder in $script:Properties.ImportFolders) {
    $currentFolder = Join-Path -Path $script:Properties.ModuleRoot -ChildPath $folder
    Write-Verbose -Message "Checking folder [$currentFolder]"

    if (Test-Path -Path $currentFolder) {

      $files = Get-ChildItem -Path $currentFolder -File -Recurse -Filter '*.ps1'
      foreach ($file in $files) {
        Write-Verbose -Message "Adding $($file.FullName)"
        Get-Content -Path (Resolve-Path $file.FullName) >> $script:Properties.OutPsmPath
      }
    }
  }

  # Finally
  #
  if (Test-Path -Path $script:Properties.FinalDirectory) {
    [array]$items = $(Get-ChildItem -Path $script:Properties.FinalDirectory -File -Filter '*.ps1') ?? @();

    foreach ($file in $items) {
      Write-Host "DEBUG(final): '$($file.FullName)'"
      Get-Content -Path $file.FullName >> $script:Properties.OutPsmPath
    }
  }

  [hashtable]$sourceDefinition = Import-PowerShellDataFile -Path $script:Properties.SourceOutPsdPath

  if ($sourceDefinition) {
    if ($sourceDefinition.ContainsKey('VariablesToExport')) {
      [string[]]$exportVariables = $sourceDefinition['VariablesToExport'];
      Write-Verbose "Found VariablesToExport: $exportVariables in source Psd file: $($script:Properties.SourceOutPsdPath)";

      if (-not([string]::IsNullOrEmpty($exportVariables))) {
        [string]$variablesArgument = $($exportVariables -join ", ") + [System.Environment]::NewLine;
        [string]$contentToAdd = "Export-ModuleMember -Variable $variablesArgument";
        Write-Verbose "Adding Psm content: $contentToAdd";

        Add-Content $script:Properties.OutPsmPath "Export-ModuleMember -Variable $variablesArgument";
      }
    }

    if ($sourceDefinition.ContainsKey('AliasesToExport')) {
      [string[]]$functionAliases = Get-PublicFunctionAliasesToExport;

      if ($functionAliases.Count -gt 0) {
        [string]$aliasesArgument = $($functionAliases -join ", ") + [System.Environment]::NewLine;

        Write-Verbose "Found AliasesToExport: $aliasesArgument in source Psd file: $($script:Properties.SourceOutPsdPath)";
        [string]$contentToAdd = "Export-ModuleMember -Alias $aliasesArgument";

        Add-Content $script:Properties.OutPsmPath "Export-ModuleMember -Alias $aliasesArgument";
      }
    }
  }

  $publicFunctions = Get-FunctionExportList;

  if ($publicFunctions.Length -gt 0) {
    Add-Content $script:Properties.OutPsmPath "Export-ModuleMember -Function $($publicFunctions -join ', ')";
  }

  # Insert custom module initialisation (./Init/module.ps1)
  #
  $initFolder = Join-Path -Path $script:Properties.ModuleRoot -ChildPath 'Init'
  if (Test-Path -Path $initFolder) {
    $moduleInitPath = Join-Path -Path $initFolder -ChildPath 'module.ps1';

    if (Test-Path -Path $moduleInitPath) {
      Write-Verbose "Injecting custom module initialisation code";
      "" >> $($script:Properties.OutPsmPath);
      "# Custom Module Initialisation" >> $script:Properties.OutPsmPath;
      "#" >> $script:Properties.OutPsmPath;

      $moduleInitContent = Get-Content -LiteralPath $moduleInitPath;
      $moduleInitContent >> $script:Properties.OutPsmPath;
    }
  }
}

task CopyPSD {
  if (-not(Test-Path (Split-Path $script:Properties.OutPsdPath))) {
    New-Item -Path (Split-Path $script:Properties.OutPsdPath) -ItemType Directory -ErrorAction 0
  }
  $copy = @{
    Path        = "$($script:Properties.ModuleName).psd1"
    Destination = $script:Properties.OutPsdPath
    Force       = $true
    Verbose     = $true
  }
  Copy-Item @copy
}

task UpdatePublicFunctionsToExport -if (Test-Path -Path $script:Properties.PublicFolder) {
  # This task only updates the psd file. The compile task updates the psm file
  #
  $publicFunctions = (Get-FunctionExportList) -join "', '"

  if (-not([string]::IsNullOrEmpty($publicFunctions))) {
    Write-Verbose "Functions to export (psd): $publicFunctions"

    $publicFunctions = "FunctionsToExport = @('{0}')" -f $publicFunctions

    # Make sure in your source psd1 file, FunctionsToExport  is set to ''.
    # PowerShell has a problem with trying to replace (), so @() does not
    # work without jumping through hoops. (Same goes for AliasesToExport)
    #
    (Get-Content -Path $script:Properties.OutPsdPath) -replace "FunctionsToExport = ''", $publicFunctions |
    Set-Content -Path $script:Properties.OutPsdPath
  }

  [hashtable]$sourceDefinition = Import-PowerShellDataFile -Path $script:Properties.SourceOutPsdPath
  if ($sourceDefinition.ContainsKey('AliasesToExport')) {
    [string[]]$aliases = Get-PublicFunctionAliasesToExport;

    if ($aliases.Count -gt 0) {
      [string]$aliasesArgument = $($aliases -join "', '");
      $aliasesStatement = "AliasesToExport = @('{0}')" -f $aliasesArgument
      Write-Verbose "AliasesToExport (psd) statement: $aliasesStatement"

      (Get-Content -Path $script:Properties.OutPsdPath) -replace "AliasesToExport\s*=\s*''", $aliasesStatement |
      Set-Content -Path $script:Properties.OutPsdPath
    }
  }
}

task CopyFileList {
  if (Test-Path $script:Properties.FileListDirectory) {
    Get-ChildItem -File -LiteralPath $script:Properties.FileListDirectory | ForEach-Object {
      $copy = @{
        LiteralPath = $_.FullName
        Destination = $($script:Properties.ModuleOutPath)
        Force       = $true
        Verbose     = $true
      }
      Copy-Item @copy -Verbose
    }
  }
}

task ImportCompiledModule -if (Test-Path -Path $script:Properties.OutPsmPath) {
  Get-Module -Name $script:Properties.ModuleName | Remove-Module -Force
  Import-Module -Name $script:Properties.OutPsdPath -Force -DisableNameChecking
}

task Pester {
  $resultFile = "{0}$($([System.IO.Path]::DirectorySeparatorChar))testResults{1}.xml" `
    -f $script:Properties.OutputFolder, (Get-date -Format 'yyyyMMdd_hhmmss')
  $testFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Tests' -AdditionalChildPath '*'

  $configuration = [PesterConfiguration]::Default
  $configuration.Run.Path = $testFolder
  $configuration.TestResult.Enabled = $true
  $configuration.TestResult.OutputFormat = 'NUnitxml'
  $configuration.TestResult.OutputPath = $resultFile;

  if (-not([string]::IsNullOrEmpty($env:tag))) {
    Write-Host "Running tests tagged '$env:tag'"
    $configuration.Filter.Tag = $env:tag
  }
  else {
    Write-Host "Running all tests"
  }

  Invoke-Pester -Configuration $configuration
}

task RemoveStats -if (Test-Path -Path "$($script:Properties.StatsFile)") {
  # Remove-Item -Force -Verbose -Path (Resolve-Path "$($script:Properties.StatsFile)")
}

task WriteStats {
  $folders = Get-ChildItem -Directory |
  Where-Object { $PSItem.Name -ne 'Output' }

  $stats = foreach ($folder in $folders) {
    $files = Get-ChildItem -File $(Join-Path -Path $folder.FullName -ChildPath '*');
    if ($files) {
      Get-Content -Path (Resolve-Path $files) |
      Measure-Object -Word -Line -Character |
      Select-Object -Property @{N = "FolderName"; E = { $folder.Name } }, Words, Lines, Characters
    }
  }
  $stats | ConvertTo-Json > "$($script:Properties.StatsFile)"
}

task Analyse {
  if (Test-Path -Path $Properties.OutputFolder) {
    Invoke-ScriptAnalyzer -Path $Properties.OutputFolder -Recurse
  }
}

task ApplyFix {
  Invoke-ScriptAnalyzer -Path $(Get-Location) -Recurse -Fix;
}

# Before this can be run, this must be run first
# New-MarkdownHelp -Module <Module> -OutputFolder .\docs
# (run from the module root, not the repo root)
# Then update the {{ ... }} place holders in the md files.
# the docs task generates the external help from the md files
#
task Docs {
  New-ExternalHelp $(Join-Path -Path $script:Properties.ModuleRoot -ChildPath 'docs') `
    -OutputPath "$($script:Properties.ExternalHelpPath)"
}
