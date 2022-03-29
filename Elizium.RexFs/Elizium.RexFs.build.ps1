# VERSION 1.0.0
using namespace System.Text.RegularExpressions;
using namespace System.Text;
using namespace System.IO;

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

class BuildEngine {

  static [string]$TestHelpers = "Tests\Helpers";
  static [string]$AdditionExports = "Init\additional-exports.ps1";

  # Initialise with a skeleton, all value names should appear in the skeleton
  # so we don't have to use that tedious Add-Member function. The properties
  # object passed into the constructor does not have to calculate the value
  # of the fields, that is the responsibility of the engine constructor. Non
  # customisable values can also be set in the skeleton
  #
  [PSCustomObject]$Data;

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
        Docs     = "docs";
        Tests    = "Tests";
      }
    
      Module     = [PSCustomObject]@{
        Name = [string]::Empty;
        Out  = [string]::Empty;
      }
    
      Directory  = [PSCustomObject]@{
        Admin                      = [string]::Empty;
        CustomModuleNameExclusions = [string]::Empty;
        ExternalHelp               = [string]::Empty;
        FileList                   = [string]::Empty;
        Final                      = [string]::Empty;
        Import                     = @("Public", "Internal", "Classes");
        Output                     = [string]::Empty;
        ModuleOut                  = [string]::Empty;
        Public                     = [string]::Empty;
        Root                       = [string]::Empty;
        Docs                       = [string]::Empty;
        Tests                      = [string]::Empty;
        TestHelpers                = [string]::Empty;
      }
    
      File       = [PSCustomObject]@{
        Psm               = [string]::Empty;
        Psd               = [string]::Empty;
        SourcePsd         = [string]::Empty;
        AdditionalExports = [string]::Empty;
        Stats             = [string]::Empty;
      }

      StaticFile = [PSCustomObject]@{
        AdditionalExports          = "additional-exports.ps1";
        CustomModuleNameExclusions = "module-name-check-exclusions.csv";
        Stats                      = "stats.json";
      }

      Rexo       = [PSCustomObject]@{
        ModuleNameExclusions = $null;
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
        $injection.Directory.Root,
        $this.Data.Label.FileList
      ));

    $this.Data.Directory.Public = $this.Data.Label.Public;

    $this.Data.Directory.Root = $injection.Directory.Root;
    $this.Data.Directory.Output = $([Path]::Join(
        $injection.Directory.Root,
        $this.Data.Label.Output)
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

    $this.Data.Directory.Docs = $([Path]::Join(
        $this.Data.Directory.Root,
        $this.Data.Label.Docs
      ));

    $this.Data.Directory.Tests = $([Path]::Join(
        $this.Data.Directory.Root,
        $this.Data.Label.Tests,
        "*"
      ));

    # File
    #
    $this.Data.File.Psm = "$($this.Data.Module.Out).psm1";
    $this.Data.File.Psd = "$($this.Data.Module.Out).psd1";
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

    [string]$syntax = "(?<syntax>namespace|module|assembly)";
    [string]$unquoted = "(?:[\w\.]+)";
    [string]$quoted = "(?:(?<quote>[\'])[\w\.\s]+\k<quote>)";
    $this.Data.Rexo.RepairUsing = [regex]::new(
      "\s*using $($syntax)\s+(?<name>$($unquoted)|$($quoted));?",
      "IgnoreCase"
    )
  }

  [void] Initialise() {
    $this._sourceFiles();
  }

  hidden [void] _sourceFiles() {
    # NOT WORKING
    Write-Host ">>> sourcing '$($this.Data.Directory.TestHelpers)'"

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

  [string[]] GetAdditionalAliasExports() {
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

  [string[]] GetFunctionExportList() {
    [string[]]$fnExports = $(
      Get-ChildItem -Path $this.Data.Directory.Public -Recurse | Where-Object {
        $_.Name -like '*-*' } | Select-Object -ExpandProperty BaseName
    );
  
    $fnExports += $this.GetAdditionalFnExports();
    return $fnExports;
  }

  [string[]] GetPublicFunctionAliasesToExport() {
    [string]$expression = 'Alias\((?<aliases>((?<quote>[''"])[\w-]+\k<quote>\s*,?\s*)+)\)';
    [RegexOptions]$options = 'IgnoreCase, SingleLine';
    
    [regex]$aliasesRegEx = [regex]::new(
      $expression, $options
    );
  
    [string[]]$aliases = @();
  
    Get-ChildItem -Path $this.Data.Directory.Public -Recurse -File -Filter '*.ps1' | Foreach-Object {
      [string]$content = Get-Content $_;
  
      [Match]$contentMatch = $aliasesRegEx.Match($content);
  
      if ($contentMatch.Success) {
        $al = $contentMatch.Groups['aliases'];
        $al = $($al -split ',' | ForEach-Object { $_.Trim().replace('"', '').replace("'", "") });
        $aliases += $al;
      }
    };
  
    $aliases += $this.GetAdditionalAliasExports();
  
    return $aliases;
  }

  [boolean] DoesFileNameMatchFunctionName([string]$Name, [string]$Content) {
    [RegexOptions]$options = "IgnoreCase";
    [string]$escaped = [regex]::Escape($Name);
    [regex]$rexo = [regex]::new("function\s+$($escaped)", $options);
  
    return $rexo.IsMatch($Content);
  }

  [boolean] TestShouldFileNameBeChecked([string]$FileName) {
    [boolean]$result = if ($this.Data.Rexo.ModuleNameExclusions.IsMatch($FileName)) {
      $false;
    }
    elseif ($(Test-Path -Path $this.Data.Directory.CustomModuleNameExclusions -PathType Leaf)) {
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
    [array]$records = @();
    [PSCustomObject]$result = [PSCustomObject]@{};

    try {
      $records = $(Invoke-ScriptAnalyzer -Path $Path | Where-Object {
          $_.RuleName -eq "UsingMustBeAtStartOfScript"
        });

      $result = [PSCustomObject]@{
        Records = $records;
        IsOk    = $records.Count -eq 0;
        Rexo    = $this.Data.Rexo.RepairUsing;
      }
    
      $result | Add-Member -MemberType NoteProperty -Name "Content" -Value $(
        Get-Content -LiteralPath $Path -Raw;
      )
    }
    catch {
      Write-Host "---> ♨️ path: '$($Path)'";
      Write-Host "---> STACK TRACE:";
      Write-Host $_.ScriptStackTrace;

      Write-Host "---> MESSAGE:";
      Write-Host "$($_.Exception.Message)";

     
      Write-Error $("🔥 Null object reference error on Script Analyzer is known issue," +
        " please just re-run the command.");
    }
  
    return $result;
  }

  [PSCustomObject] RepairUsing([PSCustomObject]$ParseInfo) {
    [MatchCollection]$mc = $ParseInfo.Rexo.Matches(
      $ParseInfo.Content
    );
  
    $withoutUsingStatements = $ParseInfo.Rexo.Replace($ParseInfo.Content, [string]::Empty);
  
    [StringBuilder]$builder = [StringBuilder]::new();
  
    [string[]]$statements = $(foreach ($m in $mc) {
        [GroupCollection]$groups = $m.Groups;
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
  
          if ($this.TestShouldFileNameBeChecked($file.Name)) {
            if (-not($this.DoesFileNameMatchFunctionName($File.BaseName, $content))) {
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
        [string[]]$functionAliases = $this.GetPublicFunctionAliasesToExport();
  
        if ($functionAliases.Count -gt 0) {
          [string]$aliasesArgument = $($functionAliases -join ", ") + [System.Environment]::NewLine;
  
          Write-Verbose "Found AliasesToExport: $aliasesArgument in source Psd file: $($this.Data.File.SourcePsd)";
          [string]$contentToAdd = "Export-ModuleMember -Alias $aliasesArgument";
  
          Add-Content $this.Data.File.Psm "Export-ModuleMember -Alias $aliasesArgument";
        }
      }
    }
  
    $publicFunctions = $this.GetFunctionExportList();
  
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
      $publicFunctions = ($this.GetFunctionExportList()) -join "', '"

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
        [string[]]$aliases = $this.GetPublicFunctionAliasesToExport();

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
    $resultFile = "{0}$($([Path]::DirectorySeparatorChar))testResults{1}.xml" `
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
    if (Test-Path -LiteralPath $this.Data.Directory.Docs) {
      Write-Host "Writing to: '$($this.Data.Directory.ExternalHelp)'";
      $null = New-ExternalHelp $this.Data.Directory.Docs `
        -OutputPath "$($this.Data.Directory.ExternalHelp)"
    }
    else {
      Write-Warning "No docs to build from path: '$($this.Data.Directory.Docs)'"
    }
  }
} # BuildEngine

Enter-build {
  Write-Build Green "entering build ... Build-Root: '$($BuildRoot)'";

  [BuildEngine]$script:_Engine = [BuildEngine]::new([PSCustomObject]@{
      Directory = [PSCustomObject]@{
        Root = $PSScriptRoot;
      }
    });

  # $script:_Engine.Initialise();

  if (Test-Path -Path "Tests\Helpers") {
    $helpers = Get-ChildItem -Path "Tests\Helpers" -Recurse -File -Filter '*.ps1';
    $helpers | ForEach-Object { Write-Verbose "sourcing helper $_"; . $_; }
  }

  if (Test-Path -Path "Init\additional-exports.ps1") {
    . Init\additional-exports.ps1;
  }
}

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

task Clean {
  $script:_Engine.CleanTask();
}

task Compile {
  $script:_Engine.CompileTask();
}

task CopyPSD {
  $script:_Engine.CopyPSDTask();
}

task UpdatePublicFunctionsToExport {
  $script:_Engine.UpdatePublicFunctionsToExportTask();
}

task CopyFileList {
  $script:_Engine.CopyFileListTask();
}

task ImportCompiledModule {
  $script:_Engine.ImportCompiledModuleTask();
}

task Pester {
  $script:_Engine.PesterTask();
}

task RemoveStats {
  # Remove-Item -Force -Verbose -Path (Resolve-Path "$($script:Properties.StatsFile)")
}

task WriteStats {
  $script:_Engine.WriteStatsTask();
}

task Analyse {
  $script:_Engine.AnalyseTask();
}

task ApplyFix {
  $script:_Engine.ApplyFixTask();
}

task RepairUsingStatements {
  $script:_Engine.RepairUsingStatementsTask();
}
# Before this can be run, this must be run first
# New-MarkdownHelp -Module <Module> -OutputFolder .\docs
# (run from the module root, not the repo root)
# Then update the {{ ... }} place holders in the md files.
# the docs task generates the external help from the md files
#
task Docs {
  $script:_Engine.DocsTask();
}
