using namespace System.Management.Automation;
using namespace Elizium.Loopz;

Describe 'bootstrap (remy)' -Tag 'Current' {
  BeforeAll {
    Get-Module Elizium.BulkRenamer | Remove-Module -Force;
    Import-Module .\Output\Elizium.BulkRenamer\Elizium.BulkRenamer.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;

    InModuleScope Elizium.BulkRenamer {
      [hashtable]$script:_signals = Get-Signals;
      [hashtable]$script:_theme = Get-KrayolaTheme;

      Import-Module Assert;
    }
  }

  BeforeEach {
    InModuleScope Elizium.BulkRenamer {
      [Krayon]$krayon = New-Krayon($_theme);
      [Scribbler]$scribbler = New-Scribbler -Krayon $krayon -Test;

      [hashtable]$exchange = @{
        'LOOPZ.SCRIBBLER' = $scribbler;
        'LOOPZ.SIGNALS'   = $_signals;
      }
      [PSCustomObject]$script:_containers = @{
        Wide  = [line]::new();
        Props = [line]::new();
      }
      
      [PSCustomObject]$options = [PSCustomObject]@{
      }
      [bootstrap]$script:_bootStrapper = [bootstrap]::new($exchange,
        $_containers, $options);

      [string]$script:_patternExpression = '\d{2,3}';
      [PSCustomObject]$script:_patternSpec = [PSCustomObject]@{
        Activate       = $true;
        SpecType       = 'regex';
        Name           = 'Pattern';
        Value          = $($_patternExpression, 1);
        Signal         = 'PATTERN';
        WholeSpecifier = 'p';
        Force          = 'Props';
        RegExKey       = 'BULKRN.REMY.PATTERN-REGEX';
        OccurrenceKey  = 'BULKRN.REMY.PATTERN-OCC';
      }
    }
  }

  Context 'given: exchange' {
    Context 'and: formatter entity' {
      It 'should: bind formatter' {
        InModuleScope Elizium.BulkRenamer {
          [PSCustomObject]$pasteSpec = [PSCustomObject]@{
            Activate    = $true;
            SpecType    = 'formatter';
            Name        = 'Paste';
            Signal      = 'PASTE-A';
            SignalValue = '${_a}, __${name}__';
            Force       = 'Props';
            Keys        = @{
              'BULKRN.REMY.PASTE' = '${_a}, __${name}__';
            }
          }
          $_bootStrapper.Register($pasteSpec);

          [hashtable]$exchange = $_bootStrapper.Build(@());
          $exchange.ContainsKey('BULKRN.REMY.PASTE') | Should -BeTrue;
          $_containers.Props.Line.Count | Should -Be 1;
          $_containers.Wide.Line.Count | Should -Be 0;
        }
      }

      It 'should: bind formatter' {
        InModuleScope Elizium.BulkRenamer {
          [PSCustomObject]$dropSpec = [PSCustomObject]@{
            Activate    = $true;
            SpecType    = 'formatter';
            Name        = 'Drop';
            Signal      = 'REMY.DROP';
            SignalValue = 'clanger';
            Force       = 'Wide';
            Keys        = @{
              'BULKRN.REMY.DROP'   = 'clanger';
              'BULKRN.REMY.MARKER' = $Loopz.Defaults.Remy.Marker;
            }
          }
          $_bootStrapper.Register($dropSpec);

          [hashtable]$exchange = $_bootStrapper.Build(@());
          $exchange.ContainsKey('BULKRN.REMY.DROP') | Should -BeTrue;
          $exchange.ContainsKey('BULKRN.REMY.MARKER') | Should -BeTrue;

          $_containers.Props.Line.Count | Should -Be 0;
          $_containers.Wide.Line.Count | Should -Be 1;
        }
      }
    }

    Context 'and: regex entity' {
      It 'should: bind regex' {
        InModuleScope Elizium.BulkRenamer {
          $_bootStrapper.Register($_patternSpec);

          [hashtable]$exchange = $_bootStrapper.Build(@());
          $exchange.ContainsKey('BULKRN.REMY.PATTERN-REGEX') | Should -BeTrue;
          $exchange.ContainsKey('BULKRN.REMY.PATTERN-OCC') | Should -BeTrue;

          $_containers.Props.Line.Count | Should -Be 1;
          $_containers.Wide.Line.Count | Should -Be 0;
        }
      }

      Context 'and: Derived Regex' {
        It 'should: bind derived regex' -Tag 'FLAKY' {
          InModuleScope Elizium.BulkRenamer {
            # NB: Derived Regex doesn't have to have a signal defined
            #
            [PSCustomObject]$derivedSpec = [PSCustomObject]@{
              Activate      = $true;
              SpecType      = 'regex';
              Dependency    = 'Pattern'
              Name          = 'Anchored';
              Value         = '^*{_dependency}';
              RegExKey      = 'BULKRN.REMY.ANCHORED-REGEX';
              OccurrenceKey = 'BULKRN.REMY.ANCHORED-OCC';
            }
            $_bootStrapper.Register($_patternSpec);
            $_bootStrapper.Register($derivedSpec);

            [hashtable]$exchange = $_bootStrapper.Build(@());
            $exchange.ContainsKey('BULKRN.REMY.ANCHORED-REGEX') | Should -BeTrue;
            $exchange.ContainsKey('BULKRN.REMY.ANCHORED-OCC') | Should -BeTrue;

            $_containers.Props.Line.Count | Should -Be 1;
            $_containers.Wide.Line.Count | Should -Be 0;

            [RegexEntity]$derived = $_bootStrapper.Get('Anchored');
            $derived.Regex.ToString() | Should -BeExactly "^$_patternExpression";
          }
        }
      }
    } # and: regex entity

    Context 'and: signal entity' {
      It 'should: bind signal' {
        InModuleScope Elizium.BulkRenamer {
          [PSCustomObject]$signalSpec = [PSCustomObject]@{
            Activate    = $true;
            SpecType    = 'signal';
            Name        = 'Start';
            Value       = $true;
            Signal      = 'REMY.ANCHOR';
            SignalValue = $_signals['SWITCH-ON'].Value;
            CustomLabel = 'Start';
            Force       = 'Props';
            Keys        = @{
              'BULKRN.REMY.ANCHOR-TYPE' = 'START';
            }
          }
          $_bootStrapper.Register($signalSpec);

          [hashtable]$exchange = $_bootStrapper.Build(@());
          $exchange.ContainsKey('BULKRN.REMY.ANCHOR-TYPE') | Should -BeTrue;

          $_containers.Props.Line.Count | Should -Be 1;
          $_containers.Wide.Line.Count | Should -Be 0;
        }
      }
    } # and: signal entity

    Context 'and: simple entity' {
      It 'should: bind regex' {
        InModuleScope Elizium.BulkRenamer {
          [PSCustomObject]$simpleSpec = [PSCustomObject]@{
            Activate = $true;
            SpecType = 'simple';
            Name     = 'Relation';
            Value    = 'before';
            Keys     = @{
              'BULKRN.REMY.RELATION' = 'before';
            }
          }
          $_bootStrapper.Register($simpleSpec);
          [hashtable]$exchange = $_bootStrapper.Build(@());
          $exchange.ContainsKey('BULKRN.REMY.RELATION') | Should -BeTrue;

          $_containers.Props.Line.Count | Should -Be 0;
          $_containers.Wide.Line.Count | Should -Be 0;
        }
      }
    } # and: simple entity

    Context 'and: Related' {
      BeforeEach {
        InModuleScope Elizium.BulkRenamer {
          [PSCustomObject]$script:_isRelatedToPatternSpec = [PSCustomObject]@{
            Activator = [scriptblock] {
              [OutputType([boolean])]
              param(
                [hashtable]$Entities,
                [hashtable]$Relations
              )
              return $Entities.ContainsKey('Pattern');
            }
            Name      = 'IsRelated';
            SpecType  = 'simple';
          }
        }
      }

      It 'should: Register spec related to primary entity' {
        InModuleScope Elizium.BulkRenamer {
          $_bootStrapper.Register($_patternSpec);
          $_bootStrapper.Build($_isRelatedToPatternSpec);
          ($null -ne $_bootStrapper.Get('IsRelated')) | Should -BeTrue;
        }
      }

      It 'should: Register spec related to Relation entity' {
        InModuleScope Elizium.BulkRenamer {
          [PSCustomObject]$relationSpec = [PSCustomObject]@{
            Activator = [scriptblock] {
              [OutputType([boolean])]
              param(
                [hashtable]$Entities,
                [hashtable]$Relations
              )
              return $Relations.ContainsKey('IsRelated');
            }
            Name      = 'Relation';
            SpecType  = 'simple';
          }
          $_bootStrapper.Register($_patternSpec);
          $_bootStrapper.Build(@($_isRelatedToPatternSpec, $relationSpec));
          ($null -ne $_bootStrapper.Get('Relation')) | Should -BeTrue;
        }
      }
    }
  }

  Context 'given: invalid spec' {
    BeforeEach {
      InModuleScope Elizium.BulkRenamer {
        [PSCustomObject]$script:_invalidSpec = [PSCustomObject]@{
          SpecType    = 'formatter';
          Mutable     = $true;
          Shade       = 'dark';
          Shape       = 'rectangle';
          Name        = 'Invalid';
          Signal      = 'INVALID';
          SignalValue = 'computer says no';
        }
      }
    }

    Context 'and: missing single item' {
      It 'should: throw' {
        InModuleScope Elizium.BulkRenamer {
          {
            [FormatterEntity]$entity = $_bootStrapper.Create($_invalidSpec);
            $entity.Require('Widget');
          } | Assert-Throw -ExceptionType ([MethodInvocationException]);
        }
      }
    }

    Context 'and: contains more than 1 of' {
      It 'should: throw' {
        InModuleScope Elizium.BulkRenamer {
          {
            [FormatterEntity]$entity = $_bootStrapper.Create($_invalidSpec);
            $entity.RequireOnlyOne(@('Mutable', 'Shape'));
          } | Assert-Throw -ExceptionType ([MethodInvocationException]);
        }
      }
    }

    Context 'and: does not contain all' {
      It 'should: throw' {
        InModuleScope Elizium.BulkRenamer {
          {
            [FormatterEntity]$entity = $_bootStrapper.Create($_invalidSpec);
            $entity.RequireAll(@('Mutable', 'Shape', 'Widget'));
          } | Assert-Throw -ExceptionType ([MethodInvocationException]);
        }
      }
    }

    Context 'and: does not contain any of' {
      It 'should: throw' {
        InModuleScope Elizium.BulkRenamer {
          {
            [FormatterEntity]$entity = $_bootStrapper.Create($_invalidSpec);
            $entity.RequireAny(@('Type', 'Sides', 'Widget'));
          } | Assert-Throw -ExceptionType ([MethodInvocationException]);
        }
      }
    }
  }
}
