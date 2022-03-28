# VERSION 1.0.0
using namespace System.Text.RegularExpressions;
using namespace System.IO;

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

class BuildEngine {

  # Initialise with a skeleton, all value names should appear in the skeleton
  # so we don't have to use that tedious Add-Member function. The properties
  # object passed into the constructor does not have to calculate the value
  # of the fields, that is the responsibility of the engine constructor. Non
  # customisable values can also be set in the skeleton
  #
  [PSCustomObject]$Data;
  [hashtable]$_map = @{};

  BuildEngine([PSCustomObject]$injection) {
    [PSCustomObject]$skeleton = [PSCustomObject]@{
      Label      = [PSCustomObject]@{
        Admin    = "Admin";
        FileList = "FileList";
        Final    = "Final";
        Helpers  = "Helpers";
        Init     = "Init";
        Public   = "Public";
        Output   = "Output";
        Language = "en-GB";
        Tests    = "Tests";
      }
    
      Module     = [PSCustomObject]@{
        Name = [string]::Empty;
        Out  = [string]::Empty; # ModuleOut
      }
    
      Directory  = [PSCustomObject]@{
        Admin                      = [string]::Empty;
        CustomModuleNameExclusions = [string]::Empty; # CustomModuleNameExclusionsPath
        ExternalHelp               = [string]::Empty;
        FileList                   = [string]::Empty; # FileListDirectory
        Final                      = [string]::Empty; # FinalDirectory
        Import                     = @("Public", "Internal", "Classes");
        Output                     = [string]::Empty;
        ModuleOut                  = [string]::Empty;
        Public                     = [string]::Empty;
        Root                       = [string]::Empty;
        Tests                      = [string]::Empty;
        TestHelpers                = [string]::Empty;
      }
    
      File       = [PSCustomObject]@{
        Psm               = [string]::Empty; # OutPsmPath
        Psd               = [string]::Empty; # OutPsdPath
        SourcePsd         = [string]::Empty; # SourceOutPsdPath
        AdditionalExports = [string]::Empty; # AdditionExportsPath
        Stats             = [string]::Empty; # StatsFile
      }

      StaticFile = [PSCustomObject]@{
        AdditionalExports          = "additional-exports.ps1";
        CustomModuleNameExclusions = "module-name-check-exclusions.csv";
        Stats                      = "stats.json";
      }

      Rexo       = [PSCustomObject]@{
        ModuleNameExclusions = $null; # ModuleNameExclusionsRexo
        RepairUsing          = $null;
      }
    }
    $this.Data = $skeleton;

    # Module
    #
    $this.Data.Module.Name = Split-Path -Path $($injection.Directory.Root) -Leaf;

    $this.Data.Module.Out = $([Path]::Join(
        $injection.Directory.Root,
        $this.Data.Label.Output,
        $this.Data.Module.Name,
        $this.Data.Module.Name
      ));

    # Directory
    #
    $this.Data.Directory.Admin = $([Path]::Join(
        $injection.Directory.Root, $this.Data.Label.Admin
      ));

    $this.Data.Directory.CustomModuleNameExclusions = $([Path]::Join(
        $this.Data.Directory.Admin,
        $this.Data.StaticFile.CustomModuleNameExclusions
      ));

    $this.Data.Directory.Final = $this.Data.Label.Final;

    $this.Data.Directory.FileList = $([Path]::Join(
        $injection.Directory.Root, $this.Data.Label.FileList
      ));

    $this.Data.Directory.Public = $this.Data.Label.Public;

    $this.Data.Directory.Root = $injection.Directory.Root;
    $this.Data.Directory.Output = $([Path]::Join(
        $injection.Directory.Root, $this.Data.Label.Output)
    );

    $this.Data.Directory.ModuleOut = $([Path]::Join(
        $injection.Directory.Root,
        $this.Data.Label.Output,
        $this.Data.Module.Name
      )
    );

    $this.Data.Directory.ExternalHelp = $([Path]::Join(
        $this.Data.Directory.Output,
        $this.Data.Module.Name,
        $this.Data.Label.Language
      ));

    $this.Data.Directory.TestHelpers = $([Path]::Join(
        $this.Data.Directory.Root,
        $this.Data.Label.Tests,
        $this.Data.Label.Helpers
      ));

    $this.Data.Directory.Tests = $([Path]::Join(
        $this.Data.Directory.Root,
        $this.Data.Label.Tests,
        "*"
      ));

    # File
    #
    $this.Data.File.Psm = "$($this.Data.Module.Out).psm1";
    $this.Data.File.Psd = "$($this.Data.Module.Out).psd1"; # OutPsdPath/SourceOutPsdPath
    $this.Data.File.SourcePsd = $([Path]::Join(
        "$($this.Data.Directory.Root)",
        "$($this.Data.Module.Name).psd1"
      ));

    $this.Data.File.AdditionalExports = $([Path]::Join(
        $this.Data.Directory.Root,
        $this.Data.Label.Init,
        $this.Data.StaticFile.AdditionalExports
      ));

    $this.Data.File.Stats = $([Path]::Join(
        $this.Data.Directory.Output,
        $this.Data.StaticFile.Stats
      ));

    # Rexo
    #
    $this.Data.Rexo.ModuleNameExclusions = [regex]::new(
      "(?:.class.ps1$|globals.ps1)", "IgnoreCase"
    );

    $this.Data.Rexo.RepairUsing = [regex]::new(
      "\s*using (?<syntax>namespace|module)\s+(?<name>(?:[\w\.]+)|(?:(?<quote>[\'])[\w\.\s]+\k<quote>));?",
      "IgnoreCase"
    )

    # ========================

    $this._map["Module.Name"] = $this.Data.Module.Name;
    $this._map["Module.Out"] = $this.Data.Module.Out;
    $this._map["Directory.Root"] = $this.Data.Directory.Root;
    $this._map["Directory.Output"] = $this.Data.Directory.Output;
    $this._map["Directory.ModuleOut"] = $this.Data.Directory.ModuleOut;
    $this._map["Directory.ExternalHelp"] = $this.Data.Directory.ExternalHelp;
    $this._map["Directory.TestHelpers"] = $this.Data.Directory.TestHelpers;
    $this._map["Directory.FileList"] = $this.Data.Directory.FileList;
    $this._map["Directory.CustomModuleNameExclusions"] = $this.Data.Directory.CustomModuleNameExclusions;
    $this._map["Directory.Import"] = $this.Data.Directory.Import;
    $this._map["File.Psm"] = $this.Data.File.Psm;
    $this._map["File.Psd"] = $this.Data.File.Psd;
    $this._map["File.SourcePsd"] = $this.Data.File.SourcePsd;
    $this._map["File.AdditionalExports"] = $this.Data.File.AdditionalExports;
    $this._map["File.Stats"] = $this.Data.File.Stats;
  }

  [void] Initialise() {
    $this._sourceFiles();
  }

  [void] Check([string]$name, [object]$original) {
    $internal = $this._map[$name];
    $indicator = if ($original -is [string]) {
      $($original -eq $internal) ? "💚" : "🔥";
    }
    elseif ($original -is [array]) {
      $null -eq $(
        Compare-Object -ReferenceObject $original -DifferenceObject $internal
      ) ? "💚" : "🔥"
    }
    else {
      "🤡"
    }
    
    Write-Host "$indicator name: '$name', original: '$original', new: '$($internal)'";
  }

  hidden [void] _sourceFiles() {
    # source helpers
    #
    if (Test-Path -Path $this.Data.Directory.TestHelpers) {
      $helpers = Get-ChildItem -Path $this.Data.Directory.TestHelpers `
        -Recurse -File -Filter '*.ps1';

      $helpers | ForEach-Object {
        Write-Verbose "sourcing helper $_"; . $_;
      }
    }

    # source additional
    #
    if (Test-Path -Path $this.Data.File.AdditionalExports) {
      . $this.Data.File.AdditionalExports;
    }
  }

  [string[]] GetAdditionalFnExports() {
    # Get-AdditionalFnExports
    #
    [string []]$additional = @()

    try {
      # don't like $global:AdditionalFnExports, re-write this. Perhaps, the client
      # sets this in the properties passed into the engine
      # 
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

  [string[]] GetAdditionalAliasExports() {
    # Get-AdditionalAliasExports
    #
    [string []]$additionalAliases = @();

    try {
      # again, this is rubbish, redesign it
      #
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

  [string[]] GetFunctionExportList() {
    # Get-FunctionExportList
    #
    [string[]]$fnExports = $(
      Get-ChildItem -Path $this.Data.Directory.Public -Recurse | Where-Object {
        $_.Name -like '*-*' } | Select-Object -ExpandProperty BaseName
    );
  
    $fnExports += $this.GetAdditionalFnExports();
    return $fnExports;
  }

  [string[]] GetPublicFunctionAliasesToExport() {
    # Get-PublicFunctionAliasesToExport
    #
    [string]$expression = 'Alias\((?<aliases>((?<quote>[''"])[\w-]+\k<quote>\s*,?\s*)+)\)';
    [System.Text.RegularExpressions.RegexOptions]$options = 'IgnoreCase, SingleLine';
    
    [System.Text.RegularExpressions.RegEx]$aliasesRegEx = [regex]::new(
      $expression, $options
    );
  
    [string[]]$aliases = @();
  
    Get-ChildItem -Path $this.Data.Directory.Public -Recurse -File -Filter '*.ps1' | Foreach-Object {
      [string]$content = Get-Content $_;
  
      [System.Text.RegularExpressions.Match]$contentMatch = $aliasesRegEx.Match($content);
  
      if ($contentMatch.Success) {
        $al = $contentMatch.Groups['aliases'];
        $al = $($al -split ',' | ForEach-Object { $_.Trim().replace('"', '').replace("'", "") });
        $aliases += $al;
      }
    };
  
    $aliases += Get-AdditionalAliasExports
  
    return $aliases;
  }

  [boolean] DoesFileNameMatchFunctionName([string]$Name, [string]$Content) {
    # Test-DoesFileNameMatchFunctionName
    #
    [System.Text.RegularExpressions.RegexOptions]$options = "IgnoreCase";
    [string]$escaped = [regex]::Escape($Name);
    [regex]$rexo = [regex]::new("function\s+$($escaped)", $options);
  
    return $rexo.IsMatch($Content);
  }

  [boolean] TestShouldFileNameBeChecked([string]$FileName) {
    # Test-ShouldFileNameBeChecked
    #
    [boolean]$result = if ($this.Data.Rexo.ModuleNameExclusions.IsMatch($FileName)) {
      $false;
    }
    elseif (Test-Path -Path $this.Data.Directory.CustomModuleNameExclusions -PathType Leaf) {
      [string]$content = Get-Content -Path $this.Data.Directory.CustomModuleNameExclusions;
  
      [string[]]$exclusions = $((if (-not([string]::IsNullOrEmpty($content))) {
            $($content -split ',') 
          } | ForEach-Object { $_.Trim() }));
  
      $exclusions ? $($exclusions -notContains $FileName) : $true;
      else {
        $true
      }
    }
  
    return $result;
  }

  [PSCustomObject] GetUsingParseInfo([string]$Path) {
    [array]$records = Invoke-ScriptAnalyzer -Path $Path | Where-Object {
      $_.RuleName -eq "UsingMustBeAtStartOfScript"
    };
  
    [PSCustomObject]$result = [PSCustomObject]@{
      Records = $records;
      IsOk    = $records.Count -eq 0;
      Rexo    = $this.Data.Rexo.RepairUsing;
    }
  
    $result | Add-Member -MemberType NoteProperty -Name "Content" -Value $(
      Get-Content -LiteralPath $Path -Raw;
    )

    return $result;
  }

  [PSCustomObject] RepairUsing([PSCustomObject]$ParseInfo) {
    # Repair-Using
    #
    [System.Text.RegularExpressions.MatchCollection]$mc = $ParseInfo.Rexo.Matches(
      $ParseInfo.Content
    );
  
    $withoutUsingStatements = $ParseInfo.Rexo.Replace($ParseInfo.Content, [string]::Empty);
  
    [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new();
  
    [string[]]$statements = $(foreach ($m in $mc) {
        [System.Text.RegularExpressions.GroupCollection]$groups = $m.Groups;
        [string]$syntax = $groups["syntax"];
        [string]$name = $groups["name"];
  
        "using $syntax $name;";
      }) | Select-Object -unique;
  
    $statements | ForEach-Object {
      $builder.AppendLine($_);
    }
    $builder.AppendLine([string]::Empty);
    $builder.Append($withoutUsingStatements);
  
    return [PSCustomObject]@{
      Content = $builder.ToString();
    }
  }

  # Task methods
  #

  [void] CleanTask() {
    if (-not(Test-Path $this.Data.Directory.Output)) {
      New-Item -ItemType Directory -Path $this.Data.Directory.Output > $null
    }
    else {
      $resolvedOutputContents = Resolve-Path $this.Data.Directory.Output;
      if ($resolvedOutputContents) {
        Remove-Item -Path (Resolve-Path $resolvedOutputContents) -Force -Recurse;
      }
    }
  } # CleanTask

  [void] CompileTask() {
    if (Test-Path -Path $this.Data.File.Psm) {
      Remove-Item -Path (Resolve-Path $this.Data.File.Psm) -Recurse -Force;
    }
    New-Item -Path $this.Data.File.Psm -Force > $null;
  
    # Insert custom module using statements (./Init/using.ps1)
    # THIS IS NOW DEFUNCT; replaced by Repair-Using facility
    #
    $initFolder = Join-Path -Path $this.Data.Directory.Root -ChildPath 'Init'
    if (Test-Path -Path $initFolder) {
      Write-Verbose "Injecting module using statements";
  
      $usingPath = Join-Path -Path $initFolder -ChildPath 'using.ps1';
  
      if (Test-Path -Path $usingPath) {
        $moduleUsingContent = Get-Content -LiteralPath $usingPath;
        $moduleUsingContent >> $this.Data.File.Psm;
      }
    }
  
    "Set-StrictMode -Version 1.0" >> $this.Data.File.Psm
  
    foreach ($folder in $this.Data.Directory.Import) {
      $currentFolder = Join-Path -Path $this.Data.Directory.Root -ChildPath $folder
      Write-Verbose -Message "Checking folder [$currentFolder]"
  
      if (Test-Path -Path $currentFolder) {
  
        $files = Get-ChildItem -Path $currentFolder -File -Recurse -Filter '*.ps1'
        foreach ($file in $files) {
          Write-Verbose -Message "Adding $($file.FullName)"
          [string]$content = Get-Content -Path (Resolve-Path $file.FullName)
          Get-Content -Path (Resolve-Path $file.FullName) >> $this.Data.File.Psm
  
          if (Test-ShouldFileNameBeChecked -FileName $file.Name) {
            if (-not(Test-DoesFileNameMatchFunctionName -Name $File.BaseName -Content $content)) {
              Write-Host "*** Beware, file: '$($file.Name)' does not contain matching function definition" `
                -ForegroundColor Red;
            }
          }
        }
      }
    }
  
    # Finally
    #
    if (Test-Path -Path $this.Data.Directory.Final) {
      [array]$items = $(Get-ChildItem -Path $this.Data.Directory.Final -File -Filter '*.ps1') ?? @();
  
      foreach ($file in $items) {
        Write-Host "DEBUG(final): '$($file.FullName)'";
        Get-Content -Path $file.FullName >> $this.Data.File.Psm;
      }
    }
  
    [hashtable]$sourceDefinition = Import-PowerShellDataFile -Path $this.Data.File.SourcePsd
  
    if ($sourceDefinition) {
      if ($sourceDefinition.ContainsKey('VariablesToExport')) {
        [string[]]$exportVariables = $sourceDefinition['VariablesToExport'];
        Write-Verbose "Found VariablesToExport: $exportVariables in source Psd file: $($this.Data.File.SourcePsd)";
  
        if (-not([string]::IsNullOrEmpty($exportVariables))) {
          [string]$variablesArgument = $($exportVariables -join ", ") + [System.Environment]::NewLine;
          [string]$contentToAdd = "Export-ModuleMember -Variable $variablesArgument";
          Write-Verbose "Adding Psm content: $contentToAdd";
  
          Add-Content $this.Data.File.Psm "Export-ModuleMember -Variable $variablesArgument";
        }
      }
  
      if ($sourceDefinition.ContainsKey('AliasesToExport')) {
        [string[]]$functionAliases = Get-PublicFunctionAliasesToExport;
  
        if ($functionAliases.Count -gt 0) {
          [string]$aliasesArgument = $($functionAliases -join ", ") + [System.Environment]::NewLine;
  
          Write-Verbose "Found AliasesToExport: $aliasesArgument in source Psd file: $($this.Data.File.SourcePsd)";
          [string]$contentToAdd = "Export-ModuleMember -Alias $aliasesArgument";
  
          Add-Content $this.Data.File.Psm "Export-ModuleMember -Alias $aliasesArgument";
        }
      }
    }
  
    $publicFunctions = Get-FunctionExportList;
  
    if ($publicFunctions.Length -gt 0) {
      Add-Content $this.Data.File.Psm "Export-ModuleMember -Function $($publicFunctions -join ', ')";
    }
  
    # Insert custom module initialisation (./Init/module.ps1)
    #
    $initFolder = Join-Path -Path $this.Data.Directory.Root -ChildPath 'Init'
    if (Test-Path -Path $initFolder) {
      $moduleInitPath = Join-Path -Path $initFolder -ChildPath 'module.ps1';
  
      if (Test-Path -Path $moduleInitPath) {
        Write-Verbose "Injecting custom module initialisation code";
        "" >> $($this.Data.File.Psm);
        "# Custom Module Initialisation" >> $this.Data.File.Psm;
        "#" >> $this.Data.File.Psm;
  
        $moduleInitContent = Get-Content -LiteralPath $moduleInitPath;
        $moduleInitContent >> $this.Data.File.Psm;
      }
    }    
  } # CompileTask

  [void] CopyPSDTask() {
    if (-not(Test-Path (Split-Path $this.Data.File.Psd))) {
      New-Item -Path (Split-Path $this.Data.File.Psd) -ItemType Directory -ErrorAction 0
    }
    $copy = @{
      Path        = "$($this.Data.Module.Name).psd1"
      Destination = $this.Data.File.Psd
      Force       = $true
      Verbose     = $true
    }
    Copy-Item @copy
  }

  [void] UpdatePublicFunctionsToExportTask() {
    if (Test-Path -Path $this.Data.Directory.Public) {
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
        (Get-Content -Path $this.Data.File.Psd) -replace "FunctionsToExport = ''", $publicFunctions |
        Set-Content -Path $this.Data.File.Psd
      }

      [hashtable]$sourceDefinition = Import-PowerShellDataFile -Path $this.Data.File.SourcePsd
      if ($sourceDefinition.ContainsKey('AliasesToExport')) {
        [string[]]$aliases = Get-PublicFunctionAliasesToExport;

        if ($aliases.Count -gt 0) {
          [string]$aliasesArgument = $($aliases -join "', '");
          $aliasesStatement = "AliasesToExport = @('{0}')" -f $aliasesArgument
          Write-Verbose "AliasesToExport (psd) statement: $aliasesStatement"

      (Get-Content -Path $this.Data.File.Psd) -replace "AliasesToExport\s*=\s*''", $aliasesStatement |
          Set-Content -Path $this.Data.File.Psd
        }
      }
    }
  } # UpdatePublicFunctionsToExportTask

  [void] CopyFileListTask() {
    if (Test-Path $this.Data.Directory.FileList) {
      Get-ChildItem -File -LiteralPath $this.Data.Directory.FileList | ForEach-Object {
        $copy = @{
          LiteralPath = $_.FullName
          Destination = $($this.Data.Directory.ModuleOut)
          Force       = $true
          Verbose     = $true
        }
        Copy-Item @copy -Verbose
      }
    }    
  } # CopyFileListTask

  [void] ImportCompiledModuleTask() {
    if (Test-Path -Path $this.Data.File.Psm) {
      Get-Module -Name $this.Data.Module.Name | Remove-Module -Force
      Import-Module -Name $this.Data.File.Psd -Force -DisableNameChecking
    }
  } # ImportCompiledModuleTask

  [void] PesterTask() {
    $resultFile = "{0}$($([System.IO.Path]::DirectorySeparatorChar))testResults{1}.xml" `
      -f $this.Data.Directory.Output, (Get-date -Format 'yyyyMMdd_hhmmss')

    $configuration = [PesterConfiguration]::Default
    $configuration.Run.Path = $this.Data.Directory.Tests
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
  } # PesterTask

  [void] WriteStatsTask() {
    $folders = Get-ChildItem -Directory | Where-Object { $PSItem.Name -ne 'Output' }
  
    $stats = foreach ($folder in $folders) {
      $files = Get-ChildItem -File $(Join-Path -Path $folder.FullName -ChildPath '*');
      if ($files) {
        Get-Content -Path (Resolve-Path $files) |
        Measure-Object -Word -Line -Character |
        Select-Object -Property @{N = "FolderName"; E = { $folder.Name } }, Words, Lines, Characters
      }
    }
    $stats | ConvertTo-Json > "$($this.Data.File.Stats)"
  } # WriteStatsTask

  [void] AnalyseTask() {
    # OutputFolder?
    if (Test-Path -Path $this.Data.Directory.Output) {
      Invoke-ScriptAnalyzer -Path $this.Data.Directory.Output -Recurse
    }
  } # AnalyseTask

  [void] ApplyFixTask() {
    Invoke-ScriptAnalyzer -Path $(Get-Location) -Recurse -Fix;
  } # ApplyFixTask

  [void] RepairUsingStatementsTask() {
    [PSCustomObject]$usingInfo = $this.GetUsingParseInfo($this.Data.File.Psm);
  
    if (-not($usingInfo.IsOk)) {
      [PSCustomObject]$repaired = $this.RepairUsing($usingInfo);
  
      Set-Content -LiteralPath $this.Data.File.Psm -Value $repaired.Content;
    }
  } # RepairUsingStatementsTask

  [void] DocsTask() {
    Write-Host "Writing to: '$($this.Data.Directory.ExternalHelp)'"
    $null = New-ExternalHelp $(Join-Path -Path $this.Data.Directory.Root -ChildPath 'docs') `
      -OutputPath "$($this.Data.Directory.ExternalHelp)"    
  }
} # BuildEngine


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
$script:AdminDirectory = "Admin";
$script:AdminPath = $(Join-Path -Path $PSScriptRoot -ChildPath $script:AdminDirectory);
$script:CustomModuleNameExclusions = "module-name-check-exclusions.csv";

$script:Properties = [PSCustomObject]@{
  ModuleName                     = $($script:Core.ModuleName);
  ModuleRoot                     = $PSScriptRoot;
  OutputFolder                   = $($script:Core.Output);
  ExternalHelpPath               = $(Join-Path -Path $script:Core.Output -ChildPath $script:ModuleName -AdditionalChildPath 'en-GB');

  ImportFolders                  = @('Public', 'Internal', 'Classes');
  OutPsmPath                     = "$($Core.ModuleOut).psm1";
  OutPsdPath                     = "$($Core.ModuleOut).psd1";
  ModuleOutPath                  = $(Join-Path -Path $PSScriptRoot -ChildPath "Output" -AdditionalChildPath $(
      "$($script:ModuleName)"
    ));

  FinalDirectory                 = 'Final';
  PublicFolder                   = 'Public';
  DSCResourceFolder              = 'DSCResources'; # NOT-USED

  SourceOutPsdPath               = $(Join-Path -Path $PSScriptRoot -ChildPath "$($script:Core.ModuleName).psd1");
  TestHelpers                    = $(Join-Path -Path $PSScriptRoot -ChildPath 'Tests' -AdditionalChildPath 'Helpers');

  AdditionExportsPath            = $(Join-Path -Path $PSScriptRoot -ChildPath 'Init' -AdditionalChildPath 'additional-exports.ps1');

  StatsFile                      = $(Join-Path -Path $script:Core.Output -ChildPath 'stats.json');
  FileListDirectory              = $(Join-Path -Path $PSScriptRoot -ChildPath 'FileList');

  ModuleNameExclusionsRexo       = [regex]::new("(?:.class.ps1$|globals.ps1)", "IgnoreCase");

  CustomModuleNameExclusionsPath = $(
    Join-Path -Path $script:AdminPath -ChildPath $script:CustomModuleNameExclusions);
}

if (Test-Path -Path $script:Properties.TestHelpers) {
  $helpers = Get-ChildItem -Path $script:Properties.TestHelpers -Recurse -File -Filter '*.ps1';
  $helpers | ForEach-Object { Write-Verbose "sourcing helper $_"; . $_; }
}

if (Test-Path -Path $script:Properties.AdditionExportsPath) {
  . $script:Properties.AdditionExportsPath;
}

[BuildEngine]$script:_Engine = [BuildEngine]::new([PSCustomObject]@{
    Directory = [PSCustomObject]@{
      Root = $PSScriptRoot;
    }
  });

$script:_Engine.Check("Module.Name", $script:Properties.ModuleName);
$script:_Engine.Check("Directory.Root", $script:Properties.ModuleRoot);
$script:_Engine.Check("Directory.Output", $script:Properties.OutputFolder);
$script:_Engine.Check("Directory.ModuleOut", $script:Properties.ModuleOutPath);
$script:_Engine.Check("Directory.ExternalHelp", $script:Properties.ExternalHelpPath);
$script:_Engine.Check("Directory.TestHelpers", $script:Properties.TestHelpers);
$script:_Engine.Check("Directory.FileList", $script:Properties.FileListDirectory);
$script:_Engine.Check("Directory.CustomModuleNameExclusions", $script:Properties.CustomModuleNameExclusionsPath);
$script:_Engine.Check("Directory.Import", $script:Properties.ImportFolders);
$script:_Engine.Check("File.Psm", $script:Properties.OutPsmPath);
$script:_Engine.Check("File.Psd", $script:Properties.OutPsdPath);
$script:_Engine.Check("File.SourcePsd", $script:Properties.SourceOutPsdPath);
$script:_Engine.Check("File.AdditionalExports", $script:Properties.AdditionExportsPath);
$script:_Engine.Check("File.Stats", $script:Properties.StatsFile);

# Task Definitions
#
task . Clean, Build, Tests, Stats
task Tests ImportCompiledModule, Pester
task CreateManifest CopyPSD, UpdatePublicFunctionsToExport, CopyFileList
task Build Compile, CreateManifest, Repair
task Stats RemoveStats, WriteStats
task Ana Analyse
task Fix ApplyFix
task Repair RepairUsingStatements
task BuildHelp Docs

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

function Test-DoesFileNameMatchFunctionName {
  [OutputType([boolean])]
  param(
    [Parameter()]
    [string]$Name,

    [Parameter()]
    [string]$Content
  )
  [System.Text.RegularExpressions.RegexOptions]$options = "IgnoreCase";
  [string]$escaped = [regex]::Escape($Name);
  [regex]$rexo = New-Object -TypeName System.Text.RegularExpressions.RegEx -ArgumentList (
    @("function\s+$($escaped)", $options));

  return $rexo.IsMatch($Content);
}

function Test-ShouldFileNameBeChecked {
  [OutputType([boolean])]
  param(
    [Parameter(Mandatory)]
    [string]$FileName
  )
  [boolean]$result = if ($script:Properties.ModuleNameExclusionsRexo.IsMatch($FileName)) {
    $false;
  }
  elseif (Test-Path -Path $script:CustomModuleNameExclusions -PathType Leaf) {
    [string]$content = Get-Content -Path $script:CustomModuleNameExclusionsPath;

    [string[]]$exclusions = $((if (-not([string]::IsNullOrEmpty($content))) {
          $($content -split ',') 
        } | ForEach-Object { $_.Trim() }));

    $exclusions ? $($exclusions -notContains $FileName) : $true;
    else {
      $true
    }
  }

  return $result;
}

function Repair-Using {
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [PSCustomObject]$ParseInfo
  )
  [System.Text.RegularExpressions.MatchCollection]$mc = $ParseInfo.Rexo.Matches(
    $ParseInfo.Content
  );

  $withoutUsingStatements = $ParseInfo.Rexo.Replace($ParseInfo.Content, [string]::Empty);

  [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new();

  [string[]]$statements = $(foreach ($m in $mc) {
      [System.Text.RegularExpressions.GroupCollection]$groups = $m.Groups;
      [string]$syntax = $groups["syntax"];
      [string]$name = $groups["name"];

      "using $syntax $name;";
    }) | Select-Object -unique;

  $statements | ForEach-Object {
    $builder.AppendLine($_);
  }
  $builder.AppendLine([string]::Empty);
  $builder.Append($withoutUsingStatements);

  return [PSCustomObject]@{
    Content = $builder.ToString();
  }
}

function Get-UsingParseInfo {
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [string]$Path,

    [Parameter()]
    [string]$Pattern = $("\s*using (?<syntax>namespace|module)\s+(?<name>[\w\.]+);?"),

    [Parameter()]
    [switch]$WithContent
  )
  [regex]$rexo = [regex]::new($Pattern, "IgnoreCase, MultiLine");
  [array]$records = Invoke-ScriptAnalyzer -Path $Path | Where-Object {
    $_.RuleName -eq "UsingMustBeAtStartOfScript"
  };

  [PSCustomObject]$result = [PSCustomObject]@{
    Records = $records;
    IsOk    = $records.Count -eq 0;
    Rexo    = $rexo;
  }

  if ($WithContent.IsPresent) {
    $result | Add-Member -MemberType NoteProperty -Name "Content" -Value $(
      Get-Content -LiteralPath $Path -Raw;
    )
  }

  return $result;
}

task Clean {

  if ($script:_Engine) {
    $script:_Engine.CleanTask();
  }
  else {
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
}

task Compile {
  if ($script:_Engine) {
    $script:_Engine.CompileTask();
  }
  else {
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
  
    foreach ($folder in $script:Properties.ImportFolders) {
      $currentFolder = Join-Path -Path $script:Properties.ModuleRoot -ChildPath $folder
      Write-Verbose -Message "Checking folder [$currentFolder]"
  
      if (Test-Path -Path $currentFolder) {
  
        $files = Get-ChildItem -Path $currentFolder -File -Recurse -Filter '*.ps1'
        foreach ($file in $files) {
          Write-Verbose -Message "Adding $($file.FullName)"
          [string]$content = Get-Content -Path (Resolve-Path $file.FullName)
          Get-Content -Path (Resolve-Path $file.FullName) >> $script:Properties.OutPsmPath
  
          if (Test-ShouldFileNameBeChecked -FileName $file.Name) {
            if (-not(Test-DoesFileNameMatchFunctionName -Name $File.BaseName -Content $content)) {
              Write-Host "*** Beware, file: '$($file.Name)' does not contain matching function definition" `
                -ForegroundColor Red;
            }
          }
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
}

task CopyPSD {

  if ($script:_Engine) {
    $script:_Engine.CopyPSDTask();
  }
  else {
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
}

task UpdatePublicFunctionsToExport -if (Test-Path -Path $script:Properties.PublicFolder) {

  if ($script:_Engine) {
    $script:_Engine.UpdatePublicFunctionsToExportTask();
  }
  else {
    # update the above if condition to:
    # Test-Path -Path $engine.Properties.Directory.Public
    #
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
}

task CopyFileList {
  if ($script:_Engine) {
    $script:_Engine.CopyFileListTask();
  }
  else {
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
}

task ImportCompiledModule -if (Test-Path -Path $script:Properties.OutPsmPath) {

  if ($script:_Engine) {
    $script:_Engine.ImportCompiledModuleTask();
  }
  else {
    Get-Module -Name $script:Properties.ModuleName | Remove-Module -Force
    Import-Module -Name $script:Properties.OutPsdPath -Force -DisableNameChecking
  }
}

task Pester {
  if ($script:_Engine) {
    $script:_Engine.PesterTask();
  }
  else {
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
}

task RemoveStats -if (Test-Path -Path "$($script:Properties.StatsFile)") {
  # Remove-Item -Force -Verbose -Path (Resolve-Path "$($script:Properties.StatsFile)")
}

task WriteStats {
  if ($script:_Engine) {
    $script:_Engine.WriteStatsTask();
  }
  else {
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
}

task Analyse {
  if ($script:_Engine) {
    $script:_Engine.AnalyseTask();
  }
  else {
    if (Test-Path -Path $Properties.OutputFolder) {
      Invoke-ScriptAnalyzer -Path $Properties.OutputFolder -Recurse
    }
  }
}

task ApplyFix {
  if ($script:_Engine) {
    $script:_Engine.ApplyFixTask();
  }
  else {
    Invoke-ScriptAnalyzer -Path $(Get-Location) -Recurse -Fix;
  }
}

task RepairUsingStatements {
  if ($script:_Engine) {
    $script:_Engine.RepairUsingStatementsTask();
  }
  else {
    [PSCustomObject]$usingInfo = Get-UsingParseInfo -Path $script:Properties.OutPsmPath -WithContent;
  
    if (-not($usingInfo.IsOk)) {
      [PSCustomObject]$repaired = Repair-Using -ParseInfo $usingInfo;
  
      Set-Content -LiteralPath $script:Properties.OutPsmPath -Value $repaired.Content;
    }
  }
}
# Before this can be run, this must be run first
# New-MarkdownHelp -Module <Module> -OutputFolder .\docs
# (run from the module root, not the repo root)
# Then update the {{ ... }} place holders in the md files.
# the docs task generates the external help from the md files
#
task Docs {
  if ($script:_Engine) {
    $script:_Engine.DocsTask();
  }
  else {
    Write-host "Writing to: '$($script:Properties.ExternalHelpPath)'"
    $null = New-ExternalHelp $(Join-Path -Path $script:Properties.ModuleRoot -ChildPath 'docs') `
      -OutputPath "$($script:Properties.ExternalHelpPath)"  
  }
}
