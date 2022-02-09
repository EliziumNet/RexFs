using namespace System.Management.Automation;
using namespace System.Collections;
using namespace System.IO;
using namespace System.Text;
using module Elizium.Krayola;
using module Elizium.Loopz;

Describe 'Rename-Many' -Tag 'remy' {
  BeforeAll {

    Get-Module Elizium.RexFs | Remove-Module -Force;
    Import-Module .\Output\Elizium.RexFs\Elizium.RexFs.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force

    Import-Module Assert;
    [boolean]$global:_whatIf = $true;
    [boolean]$global:_test = $true;

    [string]$global:_directoryPath = './Tests/Data/actium/';

    Mock -ModuleName Elizium.RexFs rename-FsItem {
      param(
        [FileSystemInfo]$From,
        [string]$To,
        [object]$UndoOperant
      )
      #
      # This mock result works only because the actual returned FileSystemInfo returned
      # does not drive any control logic.

      if ($script:_expected) {
        # NOTE: Since this rename-FsItem mock is only invoked, if there is actually a rename to be
        # performed, expectations do not need (or rather should not) add expectations for scenarios
        # where the new name is the same as the original name (ie not renamed due to a non match).
        #
        test-RenameExpect -Expects $script:_expected -Item $From.Name -Actual $To;
      }
      return $To;
    }

    Mock -ModuleName Elizium.RexFs Get-IsLocked {
      return $true;
    }

    $script:_unchanged = @{
      'loopz.application.t1.log' = 't1.loopz.application.log';
      'loopz.application.t2.log' = 't2.loopz.application.log';
      'loopz.data.t1.txt'        = 't1.loopz.data.txt';
      'loopz.data.t2.txt'        = 't2.loopz.data.txt';
      'loopz.data.t3.txt'        = 't3.loopz.data.txt';
    }
  } # BeforeAll

  BeforeEach {
    InModuleScope Elizium.RexFs {
      $script:_expected = $null;
      $script:_noFiles = @{}
    }
  }

  Context 'given: UpdateInPlace' {
    Context 'and: Source matches Pattern' {
      Context 'and: Copy is non-regex literal text' {
        # It seems like this makes no sense; there's no point in testing literal -Copy text as
        # in reality, the user should use -With. However, the user might use -Copy for
        # literal text and if they do, there's no reason why it shouldn't just work, even though
        # With is designed for this scenario.
        #

        Context 'Copy does NOT match' {
          It 'should: do rename; replace First Pattern for Copy text' {
            InModuleScope Elizium.RexFs {
              $script:_expected = $script:_noFiles;

              Get-ChildItem -Path $_directoryPath | Rename-Many -File `
                -Pattern 'a', f -Copy 'bar' -Paste '${_c}' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          }
        }

        Context 'and: First Only' {
          It 'should: do rename; replace First Pattern for Copy text' -Tag 'Current' {
            InModuleScope Elizium.RexFs {
              $script:_expected = @{
                'loopz.application.t1.log' = 'loopz.tpplication.t1.log';
                'loopz.application.t2.log' = 'loopz.tpplication.t2.log';
                'loopz.data.t1.txt'        = 'loopz.dtta.t1.txt';
                'loopz.data.t2.txt'        = 'loopz.dtta.t2.txt';
                'loopz.data.t3.txt'        = 'loopz.dtta.t3.txt';
              }

              Get-ChildItem -Path $_directoryPath | Rename-Many -File `
                -Pattern 'a', f -Copy 't' -Paste '${_c}' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          }
        } # and: First Only

        Context 'and: replace 3rd match' {
          It 'should: do rename; replace 3rd Occurrence for Copy text' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'loopz.applicati0n.t1.log';
              'loopz.application.t2.log' = 'loopz.applicati0n.t2.log';
            }

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'o', 3 -Copy '0' -Paste '${_c}' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        } # and: replace 3rd match

        Context 'and: Last Only' {
          It 'should: do rename; replace Last Pattern for Copy text' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'loopz.applic(z)tion.t1.log';
              'loopz.application.t2.log' = 'loopz.applic(z)tion.t2.log';
              'loopz.data.t1.txt'        = 'loopz.dat(z).t1.txt';
              'loopz.data.t2.txt'        = 'loopz.dat(z).t2.txt';
              'loopz.data.t3.txt'        = 'loopz.dat(z).t3.txt';
            }

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'a', l -Copy 'z' -Paste '(${_c})' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        } # and: Last Only
      } # and: Copy is non-regex literal text

      Context 'and: Copy is regex' {
        Context 'and: Whole Copy' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'loopz.t1pplication.t1.log';
              'loopz.application.t2.log' = 'loopz.t2pplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.dt1ta.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.dt2ta.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.dt3ta.t3.txt';
            }

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy 't\d' -Paste '${_c}' -Whole c `
              -WhatIf:$_whatIf -Test:$_test;
          }
        } # and: Whole Copy

        Context 'and: Source matches Last Copy' {
          It 'should: do rename; replace Pattern match with Last Copy' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'loopz.(ca)-application.t1.log';
              'loopz.application.t2.log' = 'loopz.(ca)-application.t2.log';
              'loopz.data.t1.txt'        = 'loopz.(ta)-data.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.(ta)-data.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.(ta)-data.t3.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
              -Pattern 'loopz.' -Copy '\wa', l -Paste '$0(${_c})-' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        }

        Context 'Copy does NOT match' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:_expected = $_noFiles;

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy '\d{4}' -Paste '${_c}' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        }

        Context 'and: First Only' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'loopz.t1pplication.t1.log';
              'loopz.application.t2.log' = 'loopz.t2pplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.dt1ta.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.dt2ta.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.dt3ta.t3.txt';
            }

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy 't\d' -Paste '${_c}' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        } # and: First Only
      } # and: Copy is regex

      Context 'and: Copy needs escape' {
        Context 'and: First Only' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'loopz..pplpplication.t1.log';
              'loopz.application.t2.log' = 'loopz..pplpplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.d.dtata.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.d.dtata.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.d.dtata.t3.txt';
            }

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy ($(esc('.')) + '\w{3}') -Paste '${_c}' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        } # and: First Only
      } # and: Copy needs escapes

      Context 'With' -Skip { # Paste
        Context 'and: First Only' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'loopz.@pplication.t1.log';
              'loopz.application.t2.log' = 'loopz.@pplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.d@ta.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.d@ta.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.d@ta.t3.txt';
            }

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'a', f -Paste '@' `
              -WhatIf:$_whatIf -Test:$_test;
          }

          Context 'and: replace 3rd match' {
            It 'should: do rename; replace 3rd Occurrence for Copy text' {
              $script:_expected = @{
                'loopz.application.t1.log' = 'loopz.applicati0n.t1.log';
                'loopz.application.t2.log' = 'loopz.applicati0n.t2.log';
              }

              Get-ChildItem -Path $_directoryPath | Rename-Many -File `
                -Pattern 'o', 3 -Paste '0' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          } # and: replace 3rd match

          Context 'and: Last Only' {
            It 'should: do rename; replace Last Pattern for Copy text' {
              $script:_expected = @{
                'loopz.application.t1.log' = 'loopz.applic@tion.t1.log';
                'loopz.application.t2.log' = 'loopz.applic@tion.t2.log';
                'loopz.data.t1.txt'        = 'loopz.dat@.t1.txt';
                'loopz.data.t2.txt'        = 'loopz.dat@.t2.txt';
                'loopz.data.t3.txt'        = 'loopz.dat@.t3.txt';
              }

              Get-ChildItem -Path $_directoryPath | Rename-Many -File `
                -Pattern 'a', l -Paste '@' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          } # and: Last Only
        } # and: First Only
      } # With

      Context 'and: Except' {
        Context 'and: Source matches Pattern' {
          It 'should: do rename; replace Last Pattern for Copy text, Except excluded items' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'h00pz.application.t1.log';
              'loopz.application.t2.log' = 'h00pz.application.t2.log';
            }

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'loopz' -Except 'data' -Copy 'h00pz' -Paste '${_c}' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        }
      } # and: Except

      Context 'and: Include' {
        Context 'and: Source matches Pattern' {
          It 'should: do rename; replace Last Pattern for Copy text, for Include items only' {
            $script:_expected = @{
              'loopz.data.t1.txt' = 'loopz.dat@.t1.txt';
              'loopz.data.t2.txt' = 'loopz.dat@.t2.txt';
              'loopz.data.t3.txt' = 'loopz.dat@.t3.txt';
            }

            Get-ChildItem -Path $_directoryPath | Rename-Many -File `
              -Pattern 'loopz' -Include 'data' -Copy 'h00pz' -Paste '${_c}' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        }
      } # and: Except

      Context 'and: Context' {
        It 'should: show the Context' {
          $script:_expected = @{
            'loopz.application.t1.log' = 'loopz.applic@tion.t1.log';
            'loopz.application.t2.log' = 'loopz.applic@tion.t2.log';
            'loopz.data.t1.txt'        = 'loopz.dat@.t1.txt';
            'loopz.data.t2.txt'        = 'loopz.dat@.t2.txt';
            'loopz.data.t3.txt'        = 'loopz.dat@.t3.txt';
          }

          [PSCustomObject]$context = [PSCustomObject]@{
            Title             = 'TITLE';
            ItemMessage       = 'Widget *{_fileSystemItemType}';
            SummaryMessage    = '... and finally';
            Locked            = 'REXFS_REMY_LOCKED';
            UndoDisabledEnVar = 'REXFS_REMY_UNDO_DISABLED';
          }

          Get-ChildItem -Path $_directoryPath | Rename-Many -Context $context -File `
            -Pattern 'a', l -Paste '@' `
            -WhatIf:$_whatIf -Test:$_test;
        }
      }

      Context 'and: Source denotes Directories' {
        It 'should: do rename; replace First Pattern for Copy text' {
          $script:_expected = @{
            'Arkives'   = 'Arkiv3s';
            'Consumed'  = 'Consum3d';
            'EX'        = '3X';
            # 'Musik'     = 'Musik';
            'Sheet One' = 'Sh3et One';
          }
          [string]$plastikmanPath = './Tests/Data/traverse/Audio/MINIMAL/Plastikman';

          Get-ChildItem -Path $plastikmanPath | Rename-Many -Directory `
            -Pattern 'e' -Copy '3' -Paste '${_c}' `
            -WhatIf:$_whatIf -Test:$_test;
        }
      }
    } # and: Source matches Pattern
  } # UpdateInPlace

  Context 'given: Transform' {
    Context 'and: Transform returns non empty result' {
      It 'should: perform custom transform successfully' {
        $script:_expected = @{
          'loopz.application.t1.log' = 'transformed.loopz.application.t1.log';
          'loopz.application.t2.log' = 'transformed.loopz.application.t2.log';
          'loopz.data.t1.txt'        = 'transformed.loopz.data.t1.txt';
          'loopz.data.t2.txt'        = 'transformed.loopz.data.t2.txt';
          'loopz.data.t3.txt'        = 'transformed.loopz.data.t3.txt';
        }

        [scriptblock]$transformer = [scriptblock] {
          param($name, $exchange)

          return "transformed.$($name)";
        }

        Get-ChildItem -Path $_directoryPath | Rename-Many -File `
          -Transform $transformer `
          -WhatIf:$_whatIf -Test:$_test;
      }
    }

    Context 'and: Transform returns empty return' {
      It 'should: NOT perform rename' {
        [scriptblock]$transformer = [scriptblock] {
          param($name, $exchange)

          return [string]::Empty;
        }

        Get-ChildItem -Path $_directoryPath | Rename-Many -File `
          -Transform $transformer `
          -WhatIf:$_whatIf -Test:$_test;
      }
    }
  } # Transform

  Context 'given: MoveToAnchor' {
    Context 'and: TargetType is Anchor' {
      Context 'and Relation is Before' {
        Context 'and: Source matches Pattern' {
          Context 'and: Source matches Anchor' {
            It 'should: do rename; move Pattern match before Anchor' {
              $script:_expected = @{
                'loopz.data.t1.txt' = 'data.loopz.t1.txt';
                'loopz.data.t2.txt' = 'data.loopz.t2.txt';
                'loopz.data.t3.txt' = 'data.loopz.t3.txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'data.' -Anchor 'loopz' -Relation 'before' `
                -WhatIf:$_whatIf -Test:$_test;
            }

            It 'should: do rename; move Pattern match before Anchor and Drop' {
              $script:_expected = @{
                'loopz.data.t1.txt' = 'data.loopz.-t1.txt';
                'loopz.data.t2.txt' = 'data.loopz.-t2.txt';
                'loopz.data.t3.txt' = 'data.loopz.-t3.txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'data.' -Anchor 'loopz' -Relation 'before' -Drop '-' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          } # and: Source matches Anchor

          Context 'and: Whole Pattern' {
            It 'should: do rename; move Pattern match before Anchor' {
              $script:_expected = @{
                'loopz.data.t1.txt' = 'dataloopz..t1.txt';
                'loopz.data.t2.txt' = 'dataloopz..t2.txt';
                'loopz.data.t3.txt' = 'dataloopz..t3.txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'data' -Anchor 'loopz' -Relation 'before' -Whole p `
                -WhatIf:$_whatIf -Test:$_test;
            }
          }

          Context 'and: Source matches Last Anchor' {
            It 'should: do rename; move Pattern match before Last Anchor' {
              $script:_expected = @{
                'loopz.application.t1.log' = 'applicloopz.ation.t1.log';
                'loopz.application.t2.log' = 'applicloopz.ation.t2.log';
                'loopz.data.t1.txt'        = 'datloopz.a.t1.txt';
                'loopz.data.t2.txt'        = 'datloopz.a.t2.txt';
                'loopz.data.t3.txt'        = 'datloopz.a.t3.txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'loopz.' -Anchor 'a', l -Relation 'before' `
                -WhatIf:$_whatIf -Test:$_test;
            }

            Context 'and: top 2' {
              It 'should: process the first 2 items only' {
                $script:_expected = @{
                  'loopz.application.t1.log' = 'applicloopz.ation.t1.log';
                  'loopz.application.t2.log' = 'applicloopz.ation.t2.log';
                }

                Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                  -Pattern 'loopz.' -Anchor 'a', l -Relation 'before' -Top 2 `
                  -WhatIf:$_whatIf -Test:$_test;
              }
            }
          }

          Context 'and: With references $0' {
            It 'should: insert the Pattern match' {
              $script:_expected = @{
                'loopz.application.t1.log' = 'CLANGER.application.1-[loopz].log';
                'loopz.application.t2.log' = 'CLANGER.application.2-[loopz].log';
                'loopz.data.t1.txt'        = 'CLANGER.data.1-[loopz].txt';
                'loopz.data.t2.txt'        = 'CLANGER.data.2-[loopz].txt';
                'loopz.data.t3.txt'        = 'CLANGER.data.3-[loopz].txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'loopz' -Anchor 't(?<n>\d)', l -Relation 'after' -With '${n}-[$0]' `
                -Drop 'CLANGER' -WhatIf:$_whatIf -Test:$_test;
            }

            It 'should: insert the Pattern match' {
              $script:_expected = @{
                'loopz.application.t1.log' = 'CLANGER.application.1-[loopz].log';
                'loopz.application.t2.log' = 'CLANGER.application.2-[loopz].log';
                'loopz.data.t1.txt'        = 'CLANGER.data.1-[loopz].txt';
                'loopz.data.t2.txt'        = 'CLANGER.data.2-[loopz].txt';
                'loopz.data.t3.txt'        = 'CLANGER.data.3-[loopz].txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'loopz' -Anchor 't(?<n>\d)', l -With '${n}-[$0]' `
                -Drop 'CLANGER' -WhatIf:$_whatIf -Test:$_test;
            }
          }

          Context 'and: Source matches Pattern, but differs by case' {
            It 'should: do rename; move Pattern match before Anchor' {
              $script:_expected = @{
                'loopz.data.t1.txt' = 'data.loopz.t1.txt';
                'loopz.data.t2.txt' = 'data.loopz.t2.txt';
                'loopz.data.t3.txt' = 'data.loopz.t3.txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'DATA\./i' -Anchor 'loopz' -Relation 'before' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          }

          Context 'and: Source does not match Anchor' {
            It 'should: NOT do rename' {
              $script:_expected = $_unchanged;
            
              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'data.' -Anchor 'blooper' -Relation 'before' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          }
        } # and: Source matches Pattern
      } # and Relation is Before

      Context 'and Relation is After' {
        Context 'and: Source matches Pattern' {
          Context 'and: Source matches Anchor' {
            It 'should: do rename; move Pattern match after Anchor' {
              $script:_expected = @{
                'loopz.data.t1.txt' = 'data.loopz.t1.txt';
                'loopz.data.t2.txt' = 'data.loopz.t2.txt';
                'loopz.data.t3.txt' = 'data.loopz.t3.txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'loopz.' -Anchor 'data.' -Relation 'after' `
                -WhatIf:$_whatIf -Test:$_test;
            }

            Context 'and: Whole Anchor' {
              It 'should: do rename; move Pattern match after Anchor' {
                $script:_expected = @{
                  'loopz.data.t1.txt' = 'dataloopz..t1.txt';
                  'loopz.data.t2.txt' = 'dataloopz..t2.txt';
                  'loopz.data.t3.txt' = 'dataloopz..t3.txt';
                }

                Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                  -Pattern 'loopz.' -Anchor 'data' -Relation 'after' -Whole a `
                  -WhatIf:$_whatIf -Test:$_test;
              }
            }
          } # and: Source matches Anchor

          Context 'and: Source matches Last Anchor' {
            It 'should: do rename; move Pattern match after Last Anchor' {
              $script:_expected = @{
                'loopz.application.t1.log' = 'application.loopz.t1.log';
                'loopz.application.t2.log' = 'application.loopz.t2.log';
                'loopz.data.t1.txt'        = 'data.loopz.t1.txt';
                'loopz.data.t2.txt'        = 'data.loopz.t2.txt';
                'loopz.data.t3.txt'        = 'data.loopz.t3.txt';
              }

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'loopz.' -Anchor '\.', l -Relation 'after' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          }

          Context 'and: Source does not match Anchor' {
            It 'should: NOT do rename' {
              $script:_expected = $_noFiles;
              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern 'loopz.' -Anchor 'blooper' -Relation 'after' `
                -WhatIf:$_whatIf -Test:$_test;
            }
          }
        } # and: Source matches Pattern
      } # and Relation is After
    } # and: TargetType is Anchor

    Context 'and: Hybrid Anchor' -Tag 'HYBRID' {
      Context 'and: Anchor matches Pattern' {
        Context 'and: Start specified' {
          It 'should: ignore Start and move to Anchor' {
            $script:_expected = @{
              'loopz.data.t1.txt' = 'data.loopz.t1.txt';
              'loopz.data.t2.txt' = 'data.loopz.t2.txt';
              'loopz.data.t3.txt' = 'data.loopz.t3.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
              -Pattern 'data.' -AnchorStart 'loopz' -Relation 'before' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        }

        Context 'and: End specified' {
          It 'should: ignore End and move to Anchor' {
            $script:_expected = @{
              'loopz.data.t1.txt' = 'data.loopz.t1.txt';
              'loopz.data.t2.txt' = 'data.loopz.t2.txt';
              'loopz.data.t3.txt' = 'data.loopz.t3.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
              -Pattern 'data.' -AnchorEnd 'loopz' -Relation 'before' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        }
      } # and: Anchor matches Pattern

      Context 'and: Anchor does NOT match Pattern' {
        Context 'and: Start specified' {
          It 'should: move to start' {
            $script:_expected = @{
              'loopz.application.t1.log' = 't1.loopz.application.log';
              'loopz.application.t2.log' = 't2.loopz.application.log';
              'loopz.data.t1.txt'        = 't1.loopz.data.txt';
              'loopz.data.t2.txt'        = 't2.loopz.data.txt';
              'loopz.data.t3.txt'        = 't3.loopz.data.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
              -Pattern '\.(?<tail>t\d)' -AnchorStart 'blooper' -With '${tail}.' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        }

        Context 'and: End specified' {
          It 'should: move to end' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'application.t1.loopz.log';
              'loopz.application.t2.log' = 'application.t2.loopz.log';
              'loopz.data.t1.txt'        = 'data.t1.loopz.txt';
              'loopz.data.t2.txt'        = 'data.t2.loopz.txt';
              'loopz.data.t3.txt'        = 'data.t3.loopz.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
              -Pattern '(?<header>loopz)\.' -AnchorEnd 'blooper' -With '.${header}' `
              -WhatIf:$_whatIf -Test:$_test;
          }
        }
      } # and: Anchor does NOT match Pattern

      Context 'and: Drop' {
        Context 'and: Start specified' {
          It 'should: move and drop literal' {
            $script:_expected = @{
              'loopz.application.t1.log' = '_body-application_loopz.drop.ox.t1.log';
              'loopz.application.t2.log' = 'loopz.drop.ox.t2_body-application_.log';
              'loopz.data.t1.txt'        = '_body-data_loopz.drop.ox.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.drop.ox.t2_body-data_.txt';
              'loopz.data.t3.txt'        = '_body-data_loopz.drop.ox.t3.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many `
              -Pattern '\.(?<body>[^\.]+)' -AnchorStart 't2' `
              -With '${_a}_body-${body}_' -Drop '.drop.ox' -WhatIf -Test:$_test;
          }

          It 'should: move and drop capture' {
            $script:_expected = @{
              'loopz.application.t1.log' = '_body-application_loopz[application].t1.log';
              'loopz.application.t2.log' = 'loopz[application].t2_body-application_.log';
              'loopz.data.t1.txt'        = '_body-data_loopz[data].t1.txt';
              'loopz.data.t2.txt'        = 'loopz[data].t2_body-data_.txt';
              'loopz.data.t3.txt'        = '_body-data_loopz[data].t3.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many `
              -Pattern '\.(?<body>[^\.]+)' -AnchorStart 't2' `
              -With '${_a}_body-${body}_' -Drop '[${body}]' -WhatIf -Test:$_test;
          }
        }

        Context 'and: End specified' {
          It 'should: move and drop literal' {
            $script:_expected = @{
              'loopz.application.t1.log' = 'loopz.drop.t1_body-application_.log';
              'loopz.application.t2.log' = 'loopz.drop.t2_body-application_.log';
              'loopz.data.t1.txt'        = 'loopz.drop.t1_body-data_.txt';
              'loopz.data.t2.txt'        = 'loopz.drop.t2_body-data_.txt';
              'loopz.data.t3.txt'        = 'loopz.drop.t3_body-data_.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many `
              -Pattern 'loopz\.(?<body>[^\.]+)' -AnchorEnd 't1' `
              -With '${_a}_body-${body}_' -Drop 'loopz.drop' -WhatIf -Test:$_test;
          }

          It 'should: move and drop capture' {
            $script:_expected = @{
              'loopz.application.t1.log' = '[application].t1_body-application_.log';
              'loopz.application.t2.log' = '[application].t2_body-application_.log';
              'loopz.data.t1.txt'        = '[data].t1_body-data_.txt';
              'loopz.data.t2.txt'        = '[data].t2_body-data_.txt';
              'loopz.data.t3.txt'        = '[data].t3_body-data_.txt';
            }

            Get-ChildItem -File -Path $_directoryPath | Rename-Many `
              -Pattern 'loopz\.(?<body>[^\.]+)' -AnchorEnd 't1' `
              -With '${_a}_body-${body}_' -Drop '[${body}]' -WhatIf -Test:$_test;
          }
        }
      } # and: Drop
    } # and: Hybrid Anchor

    Context 'given: Diagnose enabled' {
      Context 'and: Source matches with Named Captures' {
        Context 'and: Copy matches' {
          Context 'and: Anchor matches' {
            It 'should: do rename; move Pattern match with Copy capture' -Tag 'RE-WRITE' -Skip {
              $script:_expected = @{
                'loopz.application.t1.log' = '.BEGIN-.t1-application.-loopz.-END.application.t1.log';
                'loopz.application.t2.log' = '.BEGIN-.t2-application.-loopz.-END.application.t2.log';
                'loopz.data.t1.txt'        = '.BEGIN-.t1-data.-loopz.-END.data.t1.txt';
                'loopz.data.t2.txt'        = '.BEGIN-.t2-data.-loopz.-END.data.t2.txt';
                'loopz.data.t3.txt'        = '.BEGIN-.t3-data.-loopz.-END.data.t3.txt';
              }

              [string]$pattern = '^(?<header>[\w]+)\.';
              [string]$anchor = '\.(?<tail>t\d)';
              [string]$copy = '(?<body>[\w]+)\.';
              [string]$with = '.BEGIN-${_a}-${_c}-${header}-END.';

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern $pattern -Copy $copy -Anchor $anchor -Relation 'after' -With $with `
                -WhatIf:$_whatIf -Test:$_test -Diagnose;
            }

            Context 'and: Drop' {
              It 'should: do rename; move Pattern match with Copy capture' {
                $script:_expected = @{
                  'loopz.application.t1.log' = '[loopz, application.]_application.BEGIN-.t1-application.-loopz-END.log';
                  'loopz.application.t2.log' = '[loopz, application.]_application.BEGIN-.t2-application.-loopz-END.log';
                  'loopz.data.t1.txt'        = '[loopz, data.]_data.BEGIN-.t1-data.-loopz-END.txt';
                  'loopz.data.t2.txt'        = '[loopz, data.]_data.BEGIN-.t2-data.-loopz-END.txt';
                  'loopz.data.t3.txt'        = '[loopz, data.]_data.BEGIN-.t3-data.-loopz-END.txt';
                }

                [string]$pattern = '^(?<header>[\w]+)\.';
                [string]$anchor = '\.(?<tail>t\d)';
                [string]$copy = '(?<body>[\w]+)\.';
                [string]$with = '.BEGIN-${_a}-${_c}-${header}-END';

                Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                  -Pattern $pattern -Copy $copy -Anchor $anchor -Relation 'after' -With $with `
                  -Drop '[${header}, ${_c}]_' `
                  -WhatIf:$_whatIf -Test:$_test -Diagnose;
              }
            }
          }
        }

        Context 'and: Copy match does NOT match source' {
          It 'should: show Copy match failure' {
            [string]$pattern = '^(?<header>[\w]+)\.';
            [string]$anchor = '\.(?<tail>t\d)';
            [string]$copy = 'blooper';
            [string]$with = '.BEGIN-${_a}-${_c}-${header}-END';

            Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
              -Pattern $pattern -Copy $copy -Anchor $anchor -Relation 'after' -With $with `
              -WhatIf:$_whatIf -Test:$_test -Diagnose;
          }
        } # and: Source match does NOT match Pattern
      } # and: Source matches with Named Captures

      Context 'ReplaceWith (Update)' {
        Context 'and: Source matches with Named Captures' {
          Context 'and: Copy matches' {
            It 'should: do rename; move Pattern match with Copy capture' {
              $script:_expected = @{
                'loopz.application.t1.log' = 'BEGIN-.t1-loopz-application-END.t1.log';
                'loopz.application.t2.log' = 'BEGIN-.t2-loopz-application-END.t2.log';
                'loopz.data.t1.txt'        = 'BEGIN-.t1-loopz-data-END.t1.txt';
                'loopz.data.t2.txt'        = 'BEGIN-.t2-loopz-data-END.t2.txt';
                'loopz.data.t3.txt'        = 'BEGIN-.t3-loopz-data-END.t3.txt';
              }

              [string]$pattern = '^(?<header>[\w]+)\.(?<body>[\w]+)';
              [string]$copy = '\.(?<tail>t\d)'
              [string]$paste = 'BEGIN-${_c}-${header}-${body}-END';

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern $pattern -Copy $copy -Paste $paste `
                -WhatIf:$_whatIf -Test:$_test -Diagnose;
            }

            It 'should: do rename; move Pattern match with Copy capture' {
              $script:_expected = @{
                'loopz.application.t1.log' = 'BEGIN-.t1-loopz-application-END.t1.log';
                'loopz.application.t2.log' = 'BEGIN-.t2-loopz-application-END.t2.log';
                'loopz.data.t1.txt'        = 'BEGIN-.t1-loopz-data-END.t1.txt';
                'loopz.data.t2.txt'        = 'BEGIN-.t2-loopz-data-END.t2.txt';
                'loopz.data.t3.txt'        = 'BEGIN-.t3-loopz-data-END.t3.txt';
              }

              [string]$pattern = '^(?<header>[\w]+)\.(?<body>[\w]+)';
              [string]$copy = '\.(?<tail>[\w]+)'
              [string]$paste = 'BEGIN-${_c}-${header}-${body}-END';

              Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
                -Pattern $pattern -Copy $copy -Paste $paste `
                -WhatIf:$_whatIf -Test:$_test -Diagnose;
            }
          }
        }

        Context 'and: accidental/incorrect escape' {
          Context 'and: invalid With' {
            It 'should: throw' {
              {
                Get-ChildItem -Path $_directoryPath | Rename-Many -File `
                  -Pattern 'o', 3 -With $(esc('(name)')) -Anchor 'z' `
                  -WhatIf:$_whatIf -Test:$_test;
              } | Should -Throw;
            }
          }

          Context 'and: invalid Paste' {
            It 'should: throw' {
              {
                Get-ChildItem -Path $_directoryPath | Rename-Many -File `
                  -Pattern 'o', 3 -Paste $(esc('(o)')) `
                  -WhatIf:$_whatIf -Test:$_test;
              } | Should -Throw;
            }
          }
        }
      } # ReplaceWith (Update)
    } # given: Diagnose enabled
  } # given: MoveToAnchor

  Context 'given: MoveToStart' {
    Context 'and: Source matches Pattern in middle' {
      It 'should: do rename; move Pattern match to start' {
        $script:_expected = @{
          'loopz.data.t1.txt' = 'data.loopz.t1.txt';
          'loopz.data.t2.txt' = 'data.loopz.t2.txt';
          'loopz.data.t3.txt' = 'data.loopz.t3.txt';
        }
        Get-ChildItem -Path $_directoryPath -Filter '*.txt' | Rename-Many -File `
          -Pattern 'data.' -Start `
          -WhatIf:$_whatIf -Test:$_test;
      }
    } # and: Source matches Pattern in middle

    Context 'and: Source matches Pattern already at start' {
      It 'should: NOT do rename' {
        $script:_expected = $_noFiles;
        Get-ChildItem -Path $_directoryPath -Filter '*.txt' | Rename-Many -File `
          -Pattern 'loopz.' -Start `
          -WhatIf:$_whatIf -Test:$_test;
      }
    } # and: Source matches Pattern in middle
  } # given: MoveToStart

  Context 'given: MoveToEnd' {
    Context 'and: Source matches Pattern in middle' {
      It 'should: do rename; move Pattern match to end' {
        $script:_expected = @{
          'loopz.data.t1.txt' = 'loopz.t1.data.txt';
          'loopz.data.t2.txt' = 'loopz.t2.data.txt';
          'loopz.data.t3.txt' = 'loopz.t3.data.txt';
        }
        Get-ChildItem -Path $_directoryPath -File | Rename-Many -File `
          -Pattern '.data' -End `
          -WhatIf:$_whatIf -Test:$_test;
      }
    }

    Context 'and: Source matches Pattern already at end' {
      It 'should: NOT do rename' {
        $script:_expected = $_noFiles;
        Get-ChildItem -Path $_directoryPath | Rename-Many -File `
          -Pattern 't1' -End `
          -WhatIf:$_whatIf -Test:$_test;
      }
    } # and: Source matches Pattern in middle
  } # given: MoveToEnd

  Context 'given: Prepend' {
    It 'should: prepend literal text' {
      $script:_expected = @{
        'loopz.application.t1.log' = 'PREFIX-loopz.application.t1.log';
        'loopz.application.t2.log' = 'PREFIX-loopz.application.t2.log';
        'loopz.data.t1.txt'        = 'PREFIX-loopz.data.t1.txt';
        'loopz.data.t2.txt'        = 'PREFIX-loopz.data.t2.txt';
        'loopz.data.t3.txt'        = 'PREFIX-loopz.data.t3.txt';
      }

      Get-ChildItem -Path $_directoryPath -File | Rename-Many -Prepend 'PREFIX-' `
        -WhatIf:$_whatIf -Test:$_test;
    }

    It 'should: prepend literal text' {
      $script:_expected = @{
        'loopz.application.t1.log' = 't1_PREFIX-loopz.application.t1.log';
        'loopz.application.t2.log' = 't2_PREFIX-loopz.application.t2.log';
        'loopz.data.t1.txt'        = 't1_PREFIX-loopz.data.t1.txt';
        'loopz.data.t2.txt'        = 't2_PREFIX-loopz.data.t2.txt';
        'loopz.data.t3.txt'        = 't3_PREFIX-loopz.data.t3.txt';
      }

      [string]$copy = '(?<header>[\w]+)\.(?<mid>[\w]+).(?<tail>[\w]+)';
      Get-ChildItem -Path $_directoryPath -File | Rename-Many -Prepend '${tail}_PREFIX-' `
        -Copy $copy `
        -WhatIf:$_whatIf -Test:$_test -Diagnose;
    }

    Context 'and: Copy does not match' {
      It 'should: not rename' {
        $script:_expected = $_noFiles;

        [string]$copy = 'blah';
        Get-ChildItem -Path $_directoryPath -File | Rename-Many -Prepend '${tail}_PREFIX-' `
          -Copy $copy `
          -WhatIf:$_whatIf -Test:$_test -Diagnose;
      }
    }
  }

  Context 'given: Append' {
    It 'should: append literal text' {
      $script:_expected = @{
        'loopz.application.t1.log' = 'loopz.application.t1-POSTFIX.log';
        'loopz.application.t2.log' = 'loopz.application.t2-POSTFIX.log';
        'loopz.data.t1.txt'        = 'loopz.data.t1-POSTFIX.txt';
        'loopz.data.t2.txt'        = 'loopz.data.t2-POSTFIX.txt';
        'loopz.data.t3.txt'        = 'loopz.data.t3-POSTFIX.txt';
      }

      Get-ChildItem -Path $_directoryPath -File | Rename-Many -Append '-POSTFIX' `
        -WhatIf:$_whatIf -Test:$_test;
    }

    It 'should: append literal text' {
      $script:_expected = @{
        'loopz.application.t1.log' = 'loopz.application.t1-POSTFIX_t1.log';
        'loopz.application.t2.log' = 'loopz.application.t2-POSTFIX_t2.log';
        'loopz.data.t1.txt'        = 'loopz.data.t1-POSTFIX_t1.txt';
        'loopz.data.t2.txt'        = 'loopz.data.t2-POSTFIX_t2.txt';
        'loopz.data.t3.txt'        = 'loopz.data.t3-POSTFIX_t3.txt';
      }

      [string]$copy = '(?<header>[\w]+)\.(?<mid>[\w]+).(?<tail>[\w]+)';
      Get-ChildItem -Path $_directoryPath -File | Rename-Many -Append '-POSTFIX_${tail}' `
        -Copy $copy `
        -WhatIf:$_whatIf -Test:$_test -Diagnose;
    }

    Context 'and: Copy does not match' {
      It 'should: not rename' {
        $script:_expected = $_noFiles;

        [string]$copy = 'foo';
        Get-ChildItem -Path $_directoryPath -File | Rename-Many -Append '-POSTFIX_${tail}' `
          -Copy $copy `
          -WhatIf:$_whatIf -Test:$_test -Diagnose;
      }
    }
  }

  Context 'and: NoReplacement' {
    Context 'and: Cut matches' {
      It 'should: do rename; cut the Pattern' {
        $script:_expected = @{
          'loopz.application.t1.log' = 'application.t1.log';
          'loopz.application.t2.log' = 'application.t2.log';
          'loopz.data.t1.txt'        = 'data.t1.txt';
          'loopz.data.t2.txt'        = 'data.t2.txt';
          'loopz.data.t3.txt'        = 'data.t3.txt';
        }

        Get-ChildItem -Path $_directoryPath | Rename-Many -File `
          -Cut $(esc('loopz.')) `
          -WhatIf:$_whatIf -Test:$_test -Diagnose;
      }
    }

    Context 'and: Cut with Occurrence' {
      It 'should: do rename; cut the 2nd occurrence' {
        $script:_expected = @{
          'loopz.application.t1.log' = 'loopz.appication.t1.log';
          'loopz.application.t2.log' = 'loopz.appication.t2.log';
        }

        Get-ChildItem -Path $_directoryPath | Rename-Many -File `
          -Cut 'l', 2 `
          -WhatIf:$_whatIf -Test:$_test -Diagnose;
      }
    }

    Context 'and: Cut does not match' {
      It 'should: do rename; cut the Pattern' {
        $script:_expected = $_unchanged;

        Get-ChildItem -Path $_directoryPath | Rename-Many -File `
          -Cut 'wobble' `
          -WhatIf:$_whatIf -Test:$_test -Diagnose;
      }
    }
  } # and: NoReplacement

  Context 'given: invalid Pattern expression' {
    It 'should: throw' {
      {
        [string]$badPattern = '(((';
        Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
          -Pattern $badPattern -Anchor 'loopz' -Relation 'before' `
          -WhatIf:$_whatIf -Test:$_test;
      } | Should -Throw;
    }
  } # given: invalid Pattern expression

  Context 'given: invalid Copy expression' {
    It 'should: throw' {
      {
        [string]$badWith = '(((';
        Get-ChildItem -Path $_directoryPath | Rename-Many -File `
          -Pattern 'o', 3 -Copy $badWith -Paste '${_c}' `
          -WhatIf:$_whatIf -Test:$_test;
      } | Should -Throw;
    }
  } # given: invalid Copy expression

  Context 'given: invalid Anchor expression' {
    It 'should: throw' {
      {
        [string]$badAnchor = '(((';
        Get-ChildItem -File -Path $_directoryPath | Rename-Many -File `
          -Pattern 'data.' -Anchor $badAnchor -Relation 'before' `
          -WhatIf:$_whatIf -Test:$_test;

      } | Should -Throw;
    }
  } # given: invalid Anchor expression
} # Rename-Many

Describe 'Rename-Many (Internal)' -Skip {
  BeforeAll {
    InModuleScope Elizium.RexFs { 
      Get-Module Elizium.RexFs | Remove-Module -Force;
      Import-Module .\Output\Elizium.RexFs\Elizium.RexFs.psm1 `
        -ErrorAction 'stop' -DisableNameChecking -Force;

      Import-Module Assert;

      Mock -ModuleName Elizium.RexFs Get-IsLocked {
        return $true;
      }

      Mock -ModuleName Elizium.RexFs rename-FsItem {
        param(
          [FileSystemInfo]$From,
          [string]$To,
          [UndoRename]$UndoOperant
        )
        return $To;
      }
    }
  }

  Context 'and: Host does not support emojis' {
    It 'should: render with non unicode signals' -Tag 'REWRITE' {
      Mock -ModuleName Elizium.RexFs Test-HostSupportsEmojis {
        return $false;
      }
      InModuleScope Elizium.RexFs {
        # $Loopz.Signals = $(Initialize-Signals);
        [string]$directoryPath = './Tests/Data/actium/';

        [string]$copy = '(?<header>[\w]+)\.(?<mid>[\w]+).(?<tail>[\w]+)';
        Get-ChildItem -Path $DirectoryPath -File | Rename-Many -Append '-POSTFIX_${tail}' `
          -Copy $copy `
          -WhatIf -Test -Diagnose;
      }
    }
  }
}

Describe 'Rename-Many parameter sets' -Tag 'remy' {
  BeforeAll {
    Get-Module Elizium.RexFs | Remove-Module -Force;
    Import-Module .\Output\Elizium.RexFs\Elizium.RexFs.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;

    InModuleScope Elizium.RexFs {
      [hashtable]$script:_signals = Get-Signals;
      [hashtable]$script:_theme = Get-KrayolaTheme;
    }
  }

  BeforeEach {
    InModuleScope Elizium.RexFs {
      [StringBuilder]$script:_builder = [StringBuilder]::new();
      [krayon]$script:_krayon = New-Krayon -Theme $_theme;
      [Scribbler]$_scribbler = New-Scribbler -Krayon $_krayon -Test;

      [string]$commandName = 'Rename-Many';
      [DryRunner]$script:_runner = New-DryRunner -CommandName $commandName `
        -Signals $_signals -Scribbler $_scribbler;
    }
  } # BeforeEach

  context 'given: using DryRunner' -Tag 'DRY' {
    Context 'given: Valid Parameter Set' {
      It 'should: resolve <parameters> to <paramSet>' -TestCases @(
        # MoveToAnchor
        #
        @{ Parameters = 'underscore', 'Pattern', 'Anchor';
          ParamSet    = 'MoveToAnchor' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'With';
          ParamSet    = 'MoveToAnchor' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'With', 'Copy';
          ParamSet    = 'MoveToAnchor' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'Drop';
          ParamSet    = 'MoveToAnchor' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'With', 'Relation';
          ParamSet    = 'MoveToAnchor' 
        },

        # MoveToStart
        #
        @{ Parameters = 'underscore', 'Pattern', 'Start';
          ParamSet    = 'MoveToStart' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Start', 'With';
          ParamSet    = 'MoveToStart' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Start', 'With', 'Copy';
          ParamSet    = 'MoveToStart' 
        },

        # MoveToEnd
        #
        @{ Parameters = 'underscore', 'Pattern', 'End';
          ParamSet    = 'MoveToEnd' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'End', 'With';
          ParamSet    = 'MoveToEnd' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'End', 'With', 'Copy';
          ParamSet    = 'MoveToEnd'
        },

        # HybridStart
        #
        @{ Parameters = 'underscore', 'Pattern', 'AnchorStart';
          ParamSet    = 'HybridStart'
        },
        @{ Parameters = 'underscore', 'Pattern', 'AnchorStart', 'Relation';
          ParamSet    = 'HybridStart'
        },
        @{ Parameters = 'underscore', 'Pattern', 'AnchorStart', 'With';
          ParamSet    = 'HybridStart'
        },
        @{ Parameters = 'underscore', 'Pattern', 'AnchorStart', 'With', 'Copy';
          ParamSet    = 'HybridStart'
        },
        @{ Parameters = 'underscore', 'Pattern', 'AnchorStart', 'Drop';
          ParamSet    = 'HybridStart'
        },

        # HybridEnd
        #
        @{ Parameters = 'underscore', 'Pattern', 'AnchorEnd';
          ParamSet    = 'HybridEnd'
        },
        @{ Parameters = 'underscore', 'Pattern', 'AnchorEnd', 'Relation';
          ParamSet    = 'HybridEnd'
        },
        @{ Parameters = 'underscore', 'Pattern', 'AnchorEnd', 'With';
          ParamSet    = 'HybridEnd'
        },
        @{ Parameters = 'underscore', 'Pattern', 'AnchorEnd', 'With', 'Copy';
          ParamSet    = 'HybridEnd'
        },
        @{ Parameters = 'underscore', 'Pattern', 'AnchorEnd', 'Drop';
          ParamSet    = 'HybridEnd'
        },

        # UpdateInPlace
        #
        @{ Parameters = 'underscore', 'Pattern', 'Paste';
          ParamSet    = 'UpdateInPlace' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Paste', 'Copy';
          ParamSet    = 'UpdateInPlace' 
        },

        # Prefix
        #
        @{ Parameters = 'underscore', 'Prepend';
          ParamSet    = 'Prefix'
        },
        @{ Parameters = 'underscore', 'Prepend', 'Copy';
          ParamSet    = 'Prefix' 
        },

        # Affix
        #
        @{ Parameters = 'underscore', 'Append';
          ParamSet    = 'Affix'
        },
        @{ Parameters = 'underscore', 'Append', 'Copy';
          ParamSet    = 'Affix' 
        },

        # NoReplacement
        #
        @{ Parameters = 'underscore', 'Cut';
          ParamSet    = 'NoReplacement'
        },

        # Transformer
        #
        @{ Parameters = 'underscore', 'Transform';
          ParamSet    = 'Transformer'
        }
      ) {
        InModuleScope -ModuleName Elizium.RexFs -Parameters @{ Parameters = $parameters; ParamSet = $paramSet } {
          param(
            $Parameters, $ParamSet
          )
          [CommandParameterSetInfo[]]$paramSets = $_runner.Resolve($Parameters);
          $paramSets.Count | Should -Be 1 -Because "of [$($Parameters -join ', ')]";
          $paramSets[0].Name | Should -Be $ParamSet;
        }
      }
    } # given: Valid Parameter Set

    Context 'given: Invalid set of parameters' {
      It '<parameters> should: NOT resolve to a parameter set' -TestCases @(
        @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'Paste' },
        @{ Parameters = 'underscore', 'Pattern', 'HybridStart', 'Paste' },
        @{ Parameters = 'underscore', 'Pattern', 'HybridEnd', 'Paste' },
        @{ Parameters = 'underscore', 'Pattern', 'Start', 'End' },
        @{ Parameters = 'underscore', 'Pattern', 'Start', 'Relation' },
        @{ Parameters = 'underscore', 'Pattern', 'End', 'Relation' },
        @{ Parameters = 'underscore', 'Pattern', 'HybridStart', 'Start' },
        @{ Parameters = 'underscore', 'Pattern', 'HybridEnd', 'End' },
        @{ Parameters = 'underscore', 'Pattern', 'HybridStart', 'Anchor' },
        @{ Parameters = 'underscore', 'Pattern', 'HybridEnd', 'Anchor' },
        @{ Parameters = 'underscore', 'Pattern', 'Prepend' },
        @{ Parameters = 'underscore', 'Pattern', 'Append' },
        @{ Parameters = 'underscore', 'Append', 'Anchor' },
        @{ Parameters = 'underscore', 'Prepend', 'Anchor' }
      ) {
        InModuleScope -ModuleName Elizium.RexFs -Parameters @{ Parameters = $parameters; ParamSet = $paramSet } {
          param(
            $Parameters, $ParamSet
          )
          [CommandParameterSetInfo[]]$paramSets = $_runner.Resolve($Parameters);
          $paramSets.Count | Should -Be 0 -Because "of [$($Parameters -join ', ')]";
        }
      }
    }
  } # given: using DryRunner
} # Rename-Many parameter sets
