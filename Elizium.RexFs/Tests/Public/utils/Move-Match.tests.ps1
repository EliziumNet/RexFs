using namespace System.Text.RegularExpressions;

Describe 'Move-Match' -Tag 'remy' {
  BeforeAll {
    Get-Module Elizium.RexFs | Remove-Module -Force;
    Import-Module .\Output\Elizium.RexFs\Elizium.RexFs.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;

    . .\Tests\Helpers\new-expr.ps1
  }

  Context 'given: Pattern' {
    Context 'and: Pattern matches' {
      Context 'and: vanilla move' {
        Context 'and: Anchor matches' {
          Context 'and: before' {
            It 'should: move the first match before the first anchor' {
              [string]$source = 'Judgement Day: [06-06-2626], Judgement Day: [28-02-2727], take your pick!';
              [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
              [RegEx]$anchor = new-expr('Judgement');
              [string]$relation = 'before';

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern `
                -Relation $relation -Anchor $anchor;
              $moveResult.Payload | Should -BeExactly '06-06-2626Judgement Day: [], Judgement Day: [28-02-2727], take your pick!';
            }

            It 'should: move the last match before the first anchor' {
              [string]$source = 'Judgement Day: [06-06-2626], Judgement Day: [28-02-2727], take your pick!';
              [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
              [RegEx]$anchor = new-expr('Judgement');
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern -PatternOccurrence 'L' `
                -Relation $relation -Anchor $anchor;
              $moveResult.Payload | Should -BeExactly '28-02-2727Judgement Day: [06-06-2626], Judgement Day: [], take your pick!';
            }

            It 'should: move the 2nd match before the first anchor' {
              [string]$source = 'Judgement Day: [06-06-2626], Judgement Day: [28-02-2727], take your pick!';
              [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
              [RegEx]$anchor = new-expr('Judgement');
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern -PatternOccurrence '2' `
                -Relation $relation -Anchor $anchor;
              $moveResult.Payload | Should -BeExactly '28-02-2727Judgement Day: [06-06-2626], Judgement Day: [], take your pick!';
            }

            It 'should: move the first match before the last escaped anchor' {
              [string]$source = 'Judgement+ Day: [06-06-2626], Judgement+ Day: [28-02-2727], take your pick!';
              [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
              [RegEx]$escapedAnchor = new-expr([regex]::Escape('Judgement+'));
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern `
                -Relation $relation -Anchor $escapedAnchor -AnchorOccurrence 'L';
              $moveResult.Payload | Should -BeExactly 'Judgement+ Day: [], 06-06-2626Judgement+ Day: [28-02-2727], take your pick!';
            }

            It 'should: move the last match before the last escaped anchor' {
              [string]$source = 'Judgement+ Day: [06-06-2626], Judgement+ Day: [28-02-2727], take your pick!';
              [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
              [RegEx]$escapedAnchor = new-expr([regex]::Escape('Judgement+'));
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern -PatternOccurrence 'L' `
                -Relation $relation -Anchor $escapedAnchor  -AnchorOccurrence 'L';
              $moveResult.Payload | Should -BeExactly 'Judgement+ Day: [06-06-2626], 28-02-2727Judgement+ Day: [], take your pick!';
            }

            # Pattern:
            #
            It 'should: move the first match before the first anchor' {
              [string]$source = 'fight +fire with +fire';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$anchor = new-expr('fight');
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern `
                -Relation $relation -Anchor $anchor;
              $moveResult.Payload | Should -BeExactly '+firefight  with +fire';
            }

            It 'should: move the last match before the first anchor' {
              [string]$source = 'fight +fire with +fire';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$anchor = new-expr('fight');
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -PatternOccurrence 'L' `
                -Relation $relation -Anchor $anchor;
              $moveResult.Payload | Should -BeExactly '+firefight +fire with ';
            }

            It 'should: move the first match before the last anchor' {
              [string]$source = '*fight +fire with *fight +fire';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$escapedAnchor = new-expr([regex]::Escape('*fight'));
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern `
                -Relation $relation -Anchor $escapedAnchor -AnchorOccurrence 'L';
              $moveResult.Payload | Should -BeExactly '*fight  with +fire*fight +fire';
            }

            It 'should: move the last match before the last anchor' {
              [string]$source = '*fight +fire with *fight +fire';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$escapedAnchor = new-expr([regex]::Escape('*fight'));
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -PatternOccurrence 'L' `
                -Relation $relation -Anchor $escapedAnchor -AnchorOccurrence 'L';
              $moveResult.Payload | Should -BeExactly '*fight +fire with +fire*fight ';
            }

            Context 'and: Drop' {
              It 'should: move the first match before the first anchor' {
                [string]$source = 'fight +fire with +fire';
                [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
                [RegEx]$anchor = new-expr('fight');
                [string]$relation = 'before'
                [string]$expectedPayload = '+firefight ^ with +fire';

                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern `
                  -Relation $relation -Anchor $anchor -Drop '^';

                $moveResult.Payload | Should -BeExactly $expectedPayload;
              }

              It 'should: move the last match before the last escaped anchor' {
                [string]$source = 'Judgement+ Day: [06-06-2626], Judgement+ Day: [28-02-2727], take your pick!';
                [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
                [RegEx]$escapedAnchor = new-expr([regex]::Escape('Judgement+'));
                [string]$relation = 'before';
                [string]$expectedPayload = 'Judgement+ Day: [06-06-2626], 28-02-2727Judgement+ Day: [^], take your pick!';

                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern `
                  -PatternOccurrence 'L' `
                  -Relation $relation -Anchor $escapedAnchor  -AnchorOccurrence 'L' -Drop '^';

                $moveResult.Payload | Should -BeExactly $expectedPayload;
              }
            }
          } # and: before

          Context 'and: after' {
            It 'should: move the first match after the first anchor' {
              [string]$source = 'so fight the +fire with +fire';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$anchor = new-expr('fight ');
              [string]$relation = 'after'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern `
                -Relation $relation -Anchor $anchor;
              $moveResult.Payload | Should -BeExactly 'so fight +firethe  with +fire';
            }

            It 'should: move the last match after the first anchor' {
              [string]$source = 'so fight the +fire with +fire';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$anchor = new-expr('fight ');
              [string]$relation = 'after'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -PatternOccurrence 'L' `
                -Relation $relation -Anchor $anchor;
              $moveResult.Payload | Should -BeExactly 'so fight +firethe +fire with ';
            }

            It 'should: move the first match after the last escaped anchor' {
              [string]$source = 'so *fight the +fire with +fire *fight';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$escapedAnchor = new-expr([regex]::Escape('*fight'));
              [string]$relation = 'after'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern `
                -Relation $relation -Anchor $escapedAnchor -AnchorOccurrence 'L';
              $moveResult.Payload | Should -BeExactly 'so *fight the  with +fire *fight+fire';
            }

            It 'should: move the last match after the last escaped anchor' {
              [string]$source = '*fight +fire with *fight bump +fire';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$escapedAnchor = new-expr([regex]::Escape('*fight'));
              [string]$relation = 'after'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -PatternOccurrence 'L' `
                -Relation $relation -Anchor $escapedAnchor -AnchorOccurrence 'L';
              $moveResult.Payload | Should -BeExactly '*fight +fire with *fight+fire bump ';
            }

            Context 'and: Drop' {
              It 'should: move the first match after the first anchor' {
                [string]$source = 'so fight the +fire with +fire';
                [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
                [RegEx]$anchor = new-expr('fight ');
                [string]$relation = 'after'

                [string]$expectedPayload = 'so fight +firethe ^ with +fire';
                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern `
                  -Relation $relation -Anchor $anchor -Drop '^';

                $moveResult.Payload | Should -BeExactly $expectedPayload;
              }
            }
          } # and: after
        } # and: Anchor matches

        Context 'and: Anchor NOT match' {
          Context 'and: vanilla move before' {
            It 'should: return source unmodified' {
              [string]$source = 'fight +fire with +fire';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire'));
              [RegEx]$anchor = 'blooper';
              [string]$relation = 'before'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern `
                -Relation $relation -Anchor $anchor;
              $moveResult.Payload | Should -BeExactly $source;

              $moveResult.FailedReason.Contains('Anchor') | Should -BeTrue;
            }
          }
        } # and: Anchor NOT match

        Context 'and: Start specified' {
          Context 'and Pattern is midway in source' {
            It 'should: Move Pattern to Start' {
              [string]$source = 'There is fire where you are going';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('fire '));

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -Start;
              $moveResult.Payload | Should -BeExactly 'fire There is where you are going';
            }
          } # and Pattern is midway in source

          Context 'and Pattern is already at Start in source' {
            It 'should: return source unmodified' {
              [string]$source = 'There is fire where you are going';
              [RegEx]$escapedPattern = new-expr([regex]::Escape('There'));

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -Start;
              $moveResult.Payload | Should -BeExactly $source;
            }
          } # and Pattern is already at Start in source
        } # and: Start specified

        Context 'and: End specified' {
          Context 'and Pattern is midway in source' {
            It 'should: Move Pattern to End' {
              [string]$source = 'There is fire where you are going';
              [RegEx]$escapedPattern = new-expr(' fire');

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -End;
              $moveResult.Payload | Should -BeExactly 'There is where you are going fire';
            }
          } # and Pattern is midway in source

          Context 'and Pattern is already at End in source' {
            It 'should: return source unmodified' {
              [string]$source = 'There is fire where you are going';
              [RegEx]$escapedPattern = new-expr('going');

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -End;
              $moveResult.Payload | Should -BeExactly $source;
            }
          } # and Pattern is midway in source
        } # and: End specified
      } # and: vanilla move

      Context 'and: Hybrid Anchor' {
        Context 'and: Anchor does match Pattern' {
          Context 'and: Hybrid Anchor' {
            Context 'and: Start specified' {
              It 'should: ignore Start and move to Anchor' {
                [string]$source = 'the !@£$%^ frayed ends of sanity';
                [RegEx]$pattern = new-expr('(?<gibberish>[^\w\s]+)\s');
                [RegEx]$anchor = new-expr('sanity');
                [string]$relation = 'before';
                [string]$with = '${gibberish} ${_a}';
                [string]$expectedPayload = 'the frayed ends of !@£$%^ sanity';

                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern `
                  -Relation $relation -Anchor $anchor -Start -With $with;

                $moveResult.Payload | Should -BeExactly $expectedPayload;
              }
            }

            Context 'and: End specified' {
              It 'should: ignore End and move to Anchor' {
                [string]$source = 'the !@£$%^ frayed ends of sanity';
                [RegEx]$pattern = new-expr('(?<gibberish>[^\w\s]+)\s');
                [RegEx]$anchor = new-expr('sanity');
                [string]$relation = 'before';
                [string]$with = '${gibberish} ${_a}';
                [string]$expectedPayload = 'the frayed ends of !@£$%^ sanity';

                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern `
                  -Relation $relation -Anchor $anchor -End -With $with;

                $moveResult.Payload | Should -BeExactly $expectedPayload;
              }
            }
          }
        }

        Context 'and: Anchor does NOT match Pattern' {
          Context 'and: Start specified' {
            It 'should: move to start' {
              [string]$source = 'the !@£$%^ frayed ends of sanity';
              [RegEx]$anchor = new-expr('blooper');
              [string]$relation = 'before';
              [RegEx]$pattern = new-expr('(?<gibberish>[^\w\s]+)\s');
              [string]$with = '${gibberish} ';
              [string]$expectedPayload = '!@£$%^ the frayed ends of sanity';

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern `
                -Relation $relation -Anchor $anchor -Start -With $with;

              $moveResult.Payload | Should -BeExactly $expectedPayload;
            }
          }

          Context 'and: End specified' {
            It 'should: move to end' {
              [string]$source = 'the !@£$%^ frayed ends of sanity';
              [RegEx]$anchor = new-expr('blooper');
              [string]$relation = 'before';
              [RegEx]$pattern = new-expr('(?<gibberish>[^\w\s]+)\s');
              [string]$with = '${gibberish} ';
              [string]$expectedPayload = '!@£$%^ the frayed ends of sanity';

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern `
                -Relation $relation -Anchor $anchor -Start -With $with;

              $moveResult.Payload | Should -BeExactly $expectedPayload;
            }
          }
        }
      } # and: Hybrid Anchor

      Context 'and: Vanilla' {
        Context 'and: missing With' {
          # You can't have a copy without a With; Copy is ignored
          #
          It 'should: ignore Copy, move the last match after the first anchor' {
            [string]$source = 'Judgement Day [06-06-2626], Judgement Day [28-02-2727], Day: <Friday>';
            [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
            [RegEx]$anchor = new-expr('Judgement Day ');
            [string]$relation = 'after';
            [RegEx]$copy = new-expr('\<' + '\w+' + '\>');

            [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern -PatternOccurrence 'L' `
              -Relation $relation -Anchor $anchor -Copy $copy;
            $moveResult.Payload | Should -BeExactly 'Judgement Day 28-02-2727[06-06-2626], Judgement Day [], Day: <Friday>';
          }
        }
      } # and: Vanilla

      Context 'and: Exotic' {
        Context 'and: Escaped Pattern' {
          Context 'and: before' {
            Context 'and: Whole Pattern reference' {
              It 'should: move the last match before the first anchor' {
                [string]$source = 'There is where +fire your +fire is going';
                [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire') + '\s');
                [RegEx]$anchor = new-expr('is ');
                [string]$with = '${_a}($0) ';

                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -PatternOccurrence 'l' `
                  -Anchor $anchor -With $with;

                $moveResult.Payload | Should -BeExactly 'There is (+fire ) where +fire your is going';
              }

              It 'should: move the first match before the last anchor' {
                [string]$source = 'There is where +fire your +fire is going';
                [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire') + '\s');
                [RegEx]$anchor = new-expr('is ');
                [string]$with = '${_a}($0) ';

                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -PatternOccurrence 'f' `
                  -Anchor $anchor -AnchorOccurrence 'l' -With $with;
                $moveResult.Payload | Should -BeExactly 'There is where your +fire is (+fire ) going';
              }

              Context 'and: Literal Anchor' {
                It 'should: move the first match before the first literal anchor' {
                  [string]$source = 'There is$ where +fire your +fire is$ going';
                  [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire') + '\s');
                  [RegEx]$literalAnchor = new-expr([regex]::Escape('is$'));
                  [string]$with = '${_a}($0)';

                  [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -Anchor $literalAnchor `
                    -AnchorOccurrence 'L' -With $with;
                  $moveResult.Payload | Should -BeExactly 'There is$ where your +fire is$(+fire ) going';
                }
              }

              Context 'and: With contains Anchor named capture group reference' {
                It 'should: move the last match before the first anchor' {
                  [string]$source = 'There is where +fire your +fire is going';
                  [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire') + '\s');
                  [RegEx]$anchor = new-expr('(?<x>is\s)');
                  [string]$with = '[${x}]($0) ';

                  [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -PatternOccurrence 'l' `
                    -Anchor $anchor -With $with;

                  $moveResult.Payload | Should -BeExactly 'There [is ](+fire ) where +fire your is going';
                }
              }
            } # and: Whole Pattern reference
          } # before

          Context 'and: after' {
            Context 'and: Whole Pattern reference' {
              It 'should: move the first match after the first anchor' {
                [string]$source = 'There is where +fire your +fire is going';
                [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire') + '\s');
                [RegEx]$anchor = new-expr('is ');
                [string]$with = '${_a}($0) ';

                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -Anchor $anchor `
                  -With $with;
                $moveResult.Payload | Should -BeExactly 'There is (+fire ) where your +fire is going';
              }

              It 'should: move the first match after the last anchor' {
                [string]$source = 'There is where +fire your +fire is going';
                [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire') + '\s');
                [RegEx]$anchor = new-expr('is ');
                [string]$with = '${_a}($0) ';

                [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -Anchor $anchor `
                  -AnchorOccurrence 'l' -With $with;
                $moveResult.Payload | Should -BeExactly 'There is where your +fire is (+fire ) going';
              }

              Context 'and: Literal Anchor' {
                It 'should: move the first match after the last literal anchor' {
                  [string]$source = 'There is$ where +fire your +fire is$ going';
                  [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire') + '\s');
                  [RegEx]$literalAnchor = new-expr([regex]::Escape('is$'));
                  [string]$with = '${_a}($0)';

                  [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -Anchor $literalAnchor `
                    -AnchorOccurrence 'L' -With $with;
                  $moveResult.Payload | Should -BeExactly 'There is$ where your +fire is$(+fire ) going';
                }
              }
            } # and: Whole Pattern reference
          } # after
        } # and: Escaped Pattern

        Context 'and: Drop' {
          It 'should: cut the first match and move after the first anchor' {
            [string]$source = 'There is where +fire your +fire is going';
            [RegEx]$escapedPattern = new-expr([regex]::Escape('+fire') + '\s');
            [RegEx]$anchor = new-expr('is ');
            [string]$with = '${_a}($0) ';
            [string]$expectedPayload = 'There is (+fire ) where @your +fire is going';

            [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $escapedPattern -Anchor $anchor `
              -With $with -Drop '@';

            $moveResult.Payload | Should -BeExactly $expectedPayload;
          }
        } # and: Drop

        Context 'and: named group references' {
          Context 'and: Pattern named group references' {
            It 'should: move pattern to Anchor' {
              [string]$source = 'Judgement Day [06-06-2626], Judgement Day [28-02-2727], Day: <Friday>';
              [RegEx]$pattern = new-expr('(?<d>\d{2})-(?<m>\d{2})-(?<y>\d{4})');
              [RegEx]$anchor = new-expr('Judgement Day ');
              [string]$with = '${_a}(${y}-${m}-${d}) ';

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern -PatternOccurrence 'l' `
                -Anchor $anchor -With $with;

              $moveResult.Payload | Should -BeExactly 'Judgement Day (2727-02-28) [06-06-2626], Judgement Day [], Day: <Friday>';
            }
          } # and: Pattern named group references

          Context 'and: Copy' {
            It 'should: move the last match after the first anchor' {
              [string]$source = 'Judgement Day [06-06-2626], Judgement Day [28-02-2727], Day: <Friday>';
              [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
              [RegEx]$anchor = new-expr('Judgement Day ');
              [string]$relation = 'after'
              [RegEx]$copy = new-expr('\<' + '\w+' + '\>');
              [string]$with = '${_a}${_c}'

              [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern -PatternOccurrence 'L' `
                -Relation $relation -Anchor $anchor -Copy $copy -With $with;

              $moveResult.Payload | Should -BeExactly 'Judgement Day <Friday>[06-06-2626], Judgement Day [], Day: <Friday>';
            }
          } # and: Copy
        } # and: named group references

        Context 'and: Copy does NOT match' {
          It 'should: move the last match after the first anchor' {
            [string]$source = 'Judgement Day [06-06-2626], Judgement Day [28-02-2727], Day: <Friday>';
            [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
            [RegEx]$anchor = new-expr('Judgement Day ');
            [string]$relation = 'after'
            [RegEx]$copy = new-expr('blooper');
            [string]$with = '${_a}($0))';

            [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern -PatternOccurrence 'L' `
              -Relation $relation -Anchor $anchor -Copy $copy -With $with;

            $moveResult.Payload | Should -BeExactly $source;
            $moveResult.Success | Should -BeFalse;
            $moveResult.FailedReason.Contains('Copy') | Should -BeTrue;
          }
        } # and: Copy does NOT match
      } # and: Exotic
    } # and: Pattern matches

    Context 'and: No Pattern match' {
      It 'should: return source unmodified' {
        [string]$source = 'There 23-03-1984 will be fire on where you are going';
        [RegEx]$pattern = new-expr('bomb!');
        [RegEx]$anchor = new-expr('\d{2}-\d{2}-\d{4}\s');

        [PSCustomObject]$moveResult = Move-Match -Value $source -Pattern $pattern `
          -Relation 'before' -Anchor $anchor;

        $moveResult.Payload | Should -BeExactly $source -Because "No ('$pattern') match found";
        $moveResult.Success | Should -BeFalse;
        $moveResult.FailedReason.Contains('Pattern') | Should -BeTrue;
      }
    } # and: No Pattern match
  } # given: Pattern

  Context 'given: Cut' {
    Context 'and: Cut matches' {
      It 'should: Cut the first match before the first anchor' {
        [string]$source = 'Judgement Day: [06-06-2626], Judgement Day: [28-02-2727], take your pick!';
        [RegEx]$cut = new-expr('\d{2}-\d{2}-\d{4}');

        [PSCustomObject]$cutResult = Move-Match -Value $source -Cut $cut;
        $cutResult.Payload | Should -BeExactly 'Judgement Day: [], Judgement Day: [28-02-2727], take your pick!';
      }
    }
  }

  Context 'given: Cut' {
    Context 'and: Cut does NOT match' {
      It 'should: return source unmodified' {
        [string]$source = 'Judgement Day: [06-06-2626], Judgement Day: [28-02-2727], take your pick!';
        [RegEx]$cut = new-expr('dolly');

        [PSCustomObject]$cutResult = Move-Match -Value $source -Cut $cut;
        $cutResult.Payload | Should -BeExactly $source;
      }
    }
  }
} # Move-Match
