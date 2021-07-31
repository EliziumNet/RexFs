using namespace System.Text.RegularExpressions;

Describe 'Update-Match' -Tag 'remy' {
  BeforeAll {
    Get-Module Elizium.RexFs | Remove-Module -Force;
    Import-Module .\Output\Elizium.RexFs\Elizium.RexFs.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;

    . .\Tests\Helpers\new-expr.ps1;
  }
 
  Context 'FIRST' {
    Context 'given: plain pattern' {
      Context 'and: no matches' {
        It 'should: return original string unmodified' {
          [string]$source = 'We are like the dreamer who dreams and then lives inside the dream';
          [RegEx]$pattern = new-expr('blooper');
          [string]$paste = 'dandelion';

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;

          $updateResult.Payload | Should -BeExactly $source;
          $updateResult.Success | Should -BeFalse;
          $updateResult.FailedReason.Contains('Pattern') | Should -BeTrue;
        }
      }

      Context 'and: single match' {
        It 'should: replace the single match' {
          [string]$source = 'We are like the dreamer';
          [RegEx]$pattern = new-expr('dream');
          [string]$paste = 'heal';

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
          $updateResult.Payload | Should -BeExactly 'We are like the healer';
        }
      }

      Context 'and: multiple matches' {
        It 'should: replace the first match only' {
          [string]$source = 'We are like the dreamer who dreams and then lives inside the dream';
          [RegEx]$pattern = new-expr('dream');
          [string]$paste = 'heal';

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
          $updateResult.Payload | Should -BeExactly 'We are like the healer who dreams and then lives inside the dream';
        }
      }

      Context 'and: Quantity specified' {
        It 'should: replace specified match only' {
          [string]$source = 'We are like the dreamer who dreams and then lives inside the dream';
          [RegEx]$pattern = new-expr('dream');
          [string]$paste = 'heal';

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
            -PatternOccurrence '2';
          $updateResult.Payload | Should -BeExactly 'We are like the dreamer who heals and then lives inside the dream';
        }
      }

      Context 'Excess PatternOccurrence specified' {
        It 'should: return value unmodified' {
          [string]$source = 'We are like the dreamer who dreams and then lives inside the dream';
          [RegEx]$pattern = new-expr('dream');
          [string]$paste = 'heal';

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
            -PatternOccurrence '99';
          $updateResult.Payload | Should -BeExactly $source;
        }
      }

      Context 'and: Paste references Copy' {
        Context 'and: single Pattern match' {
          It 'should: replace the single match' {
            [string]$source = 'We are like the dreamer';
            [RegEx]$pattern = new-expr('dream');
            [string]$copy = 'like';
            [string]$paste = '==${_c}==';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Copy $copy -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'We are like the ==like==er';
          }
        }
      } # and: Paste references With

      Context 'and: Paste references Pattern' {
        Context 'and: single Pattern match' {
          It 'should: replace the single match' {
            [string]$source = 'We are like the dreamer';
            [RegEx]$pattern = new-expr('dream');
            [string]$paste = '==$0==';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'We are like the ==dream==er';
          }
        }
      } # and: Paste references Pattern

      Context 'and: Paste & Copy' {
        Context 'and: Copy matches' {
          It 'should: replace the single match' -Tag 'Bug' {
            [string]$source = 'We are like the dreamer 1234';
            [RegEx]$pattern = new-expr('dream');
            [string]$copy = '\d{4}';
            [string]$paste = '==${_c}==';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern `
              -Copy $copy -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'We are like the ==1234==er 1234';
          }
        }

        Context 'and: Copy does NOT match' {
          It 'should: replace the single match' {
            [string]$source = 'We are like the dreamer';
            [RegEx]$pattern = new-expr('dream');
            [string]$copy = 'blah';
            [string]$paste = '==${_c}==';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern `
              -Copy $copy -Paste $paste;

            $updateResult.Payload | Should -BeExactly $source;
            $updateResult.Success | Should -BeFalse;
            $updateResult.FailedReason.Contains('Copy') | Should -BeTrue;
          }

          Context 'and: Copy does NOT match whats been removed from Pattern match' {
            It 'should: replace the single match' {
              [string]$source = 'We are like the dreamer 1234';
              [RegEx]$pattern = new-expr('dream');
              [RegEx]$copy = new-expr('dream');
              [string]$paste = '==${_c}==';

              [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern `
                -Copy $copy -Paste $paste;
  
              $updateResult.Payload | Should -BeExactly $source;
              $updateResult.Success | Should -BeFalse;
              $updateResult.FailedReason.Contains('Copy') | Should -BeTrue;
            }
          }
        }
      } # and: Paste & Copy

      Context 'and: Paste & Copy' {
        Context 'Copy matches' {
          It 'should: replace the single match' {
            [string]$source = 'We are like the dreamer';
            [RegEx]$pattern = new-expr('dream');
            [string]$copy = '[^\s]+';
            [string]$paste = '==${_c}==';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern `
              -Copy $copy -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'We are like the ==We==er';
          }
        }
      } # and: Paste & Copy
    } # given: plain pattern

    Context 'given: regex pattern' {
      Context 'and: word boundary' {
        Context 'and: no matches' {
          It 'should: return original string unmodified' {
            [string]$source = 'We are like the dreamer who dreams and then lives inside the dream';
            [RegEx]$pattern = new-expr('\bscream\b');
            [string]$paste = 'heal';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
            $updateResult.Payload | Should -BeExactly $source;

            $updateResult.FailedReason.Contains('Pattern') | Should -BeTrue;
          }
        }

        Context 'and: single match' {
          It 'should: replace the single match' {
            [string]$source = 'We are like the dreamer who dreams and then lives inside the dream';
            [RegEx]$pattern = new-expr('\bdream\b');
            [string]$paste = 'healer';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'We are like the dreamer who dreams and then lives inside the healer';
          }
        }

        Context 'and: multiple matches' {
          It 'should: replace the first single match only' {
            [string]$source = 'We are like the dreamer who has a dream and then lives inside the dream';
            [RegEx]$pattern = new-expr('\bdream\b');
            [string]$paste = 'healer';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'We are like the dreamer who has a healer and then lives inside the dream';
          }
        }
      } # and: word boundary

      Context 'and: date' {
        Context 'and: single match' {
          It 'should: replace the single match' {
            [string]$source = 'Party like its 31-12-1999';
            [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
            [string]$paste = 'Nineteen Ninety Nine';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'Party like its Nineteen Ninety Nine';
          }
        }

        Context 'and: multiple matches' {
          It 'should: replace the first match only' {
            [string]$source = '01-01-2000 Party like its 31-12-1999';
            [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
            [string]$paste = 'New Years Eve 1999';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
              -PatternOccurrence 'f';
            $updateResult.Payload | Should -BeExactly 'New Years Eve 1999 Party like its 31-12-1999';
          }

          It 'should: replace identified match only' {
            [string]$source = '01-01-2000 Party like its 31-12-1999, today is 24-09-2020';
            [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
            [string]$paste = '[DATE]';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
              -PatternOccurrence '2';
            $updateResult.Payload | Should -BeExactly '01-01-2000 Party like its [DATE], today is 24-09-2020';
          }
        } # and: multiple matches
      } # and: date

      Context 'and: Pattern defines named captures' {
        It 'should: rename accessing Pattern defined capture' {
          [string]$source = '21-04-2000, Party like its 31-12-1999, today is 24-09-2020';
          [RegEx]$pattern = new-expr('(?<day>\d{2})-(?<mon>\d{2})-(?<year>\d{4})');

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -PatternOccurrence 'f' `
            -Paste 'Americanised: ${mon}-${day}-${year}';

          $updateResult.Payload | Should -BeExactly 'Americanised: 04-21-2000, Party like its 31-12-1999, today is 24-09-2020';
        }
      }

      Context 'and: Copy does not MATCH' {
        It 'should: rename accessing Pattern defined capture' {
          [string]$source = '21-04-2000, Party like its 31-12-1999, today is 24-09-2020';
          [RegEx]$copy = new-expr('blooper');
          [RegEx]$pattern = new-expr('(?<day>\d{2})-(?<mon>\d{2})-(?<year>\d{4})');

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern `
            -Copy $copy -Paste 'Americanised: ${mon}-${day}-${year}';

          $updateResult.Payload | Should -BeExactly $source;
          $updateResult.Success | Should -BeFalse;
          $updateResult.FailedReason.Contains('Copy') | Should -BeTrue;
        }
      }
    } # given: regex pattern
  } # FIRST

  Context 'LAST' {
    Context 'given: plain pattern' {
      Context 'and: no matches' {
        It 'should: return original string unmodified' {
          [string]$source = 'The sound the wind makes in the pines';
          [RegEx]$pattern = new-expr('bear');
          [string]$paste = 'woods';

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
          $updateResult.Payload | Should -BeExactly 'The sound the wind makes in the pines';
        }
      }

      Context 'and: single match' {
        It 'should: replace the single match' {
          [string]$source = 'The sound the wind makes in the pines';
          [RegEx]$pattern = new-expr('wind');
          [string]$paste = 'owl';

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
          $updateResult.Payload | Should -BeExactly 'The sound the owl makes in the pines';
        }
      }

      Context 'and: multiple matches' {
        It 'should: replace the last single match only' {
          [string]$source = 'The sound the wind makes in the pines';
          [RegEx]$pattern = new-expr('in');
          [string]$paste = '==';

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
            -PatternOccurrence 'l';
          $updateResult.Payload | Should -BeExactly 'The sound the wind makes in the p==es';
        }
      }
    } # given: plain pattern

    Context 'given: regex pattern' {
      Context 'and: word boundary' {
        Context 'and: no matches' {
          It 'should: return original string unmodified' {
            [string]$source = 'The sound the wind makes in the pines';
            [RegEx]$pattern = new-expr('\bbear\b');
            [string]$paste = 'woods';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;

            $updateResult.Payload | Should -BeExactly $source;
            $updateResult.Success | Should -BeFalse;
            $updateResult.FailedReason.Contains('Pattern') | Should -BeTrue;
          }
        }

        Context 'and: single match' {
          It 'should: replace the single match' {
            [string]$source = 'The sound the wind makes in the pines';
            [RegEx]$pattern = new-expr('\bin\b');
            [string]$paste = 'under';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'The sound the wind makes under the pines';
          }
        }

        Context 'and: multiple matches' {
          It 'should: replace the last single match only' {
            [string]$source = 'The sound the wind makes in the pines or in the woods';
            [RegEx]$pattern = new-expr('in');
            [string]$paste = 'under';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
              -PatternOccurrence 'l';
            $updateResult.Payload | Should -BeExactly 'The sound the wind makes in the pines or under the woods';
          }
        }
      } # and: word boundary

      Context 'and: date' {
        Context 'and: single match' {
          It 'should: replace the single match' {
            [string]$source = 'Party like its 31-12-1999';
            [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
            [string]$paste = 'Nineteen Ninety Nine';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste;
            $updateResult.Payload | Should -BeExactly 'Party like its Nineteen Ninety Nine';
          }
        }

        Context 'and: multiple matches' {
          It 'should: replace the last match only' {
            [string]$source = '01-01-2000 Party like its 31-12-1999';
            [RegEx]$pattern = new-expr('\d{2}-\d{2}-\d{4}');
            [string]$paste = 'New Years Eve 1999';

            [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
              -PatternOccurrence 'l';
            $updateResult.Payload | Should -BeExactly '01-01-2000 Party like its New Years Eve 1999';
          }
        }
      } # and: date

      Context 'and: Pattern defines named captures' {
        It 'should: rename accessing Pattern defined capture' {
          [string]$source = '21-04-2000, Party like its 31-12-1999, today is 24-09-2020';
          [RegEx]$pattern = new-expr('(?<day>\d{2})-(?<mon>\d{2})-(?<year>\d{4})');

          [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -PatternOccurrence 'l' `
            -Paste 'Americanised: ${mon}-${day}-${year}';

          $updateResult.Payload | Should -BeExactly '21-04-2000, Party like its 31-12-1999, today is Americanised: 09-24-2020';
        }
      }
    } # given: regex pattern
  } # LAST

  Context 'NTH' {
    Context 'given: plain pattern' {
      It 'should: replace all matches' {
        [string]$source = 'Cyanopsia: blue, Cataract: blue, Moody: blues, Azora: blue, Azul: blue, Hinto: blue';
        [RegEx]$pattern = new-expr('blue');
        [string]$paste = 'red';

        [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
          -PatternOccurrence '2';
        $updateResult.Payload | Should -BeExactly 'Cyanopsia: blue, Cataract: red, Moody: blues, Azora: blue, Azul: blue, Hinto: blue';
      }

      It 'should: replace all whole word matches' {
        [string]$source = 'Cyanopsia: blue, Cataract: blue, Moody: blues, Azora: blue, Azul: blue, Hinto: blue';
        [RegEx]$pattern = new-expr('\bblue\b');
        [string]$paste = 'red';

        [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
          -PatternOccurrence '3';
        $updateResult.Payload | Should -BeExactly 'Cyanopsia: blue, Cataract: blue, Moody: blues, Azora: red, Azul: blue, Hinto: blue';
      }
    }

    Context 'given: regex pattern' {
      It 'should: replace all matches' {
        [string]$source = 'Currencies: [GBP], [CHF], [CUC], [CZK], [GHS]';
        [RegEx]$pattern = new-expr('\[(?<ccy>[A-Z]{3})\]');
        [string]$paste = '(***)';

        [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -Paste $paste `
          -PatternOccurrence '4';
        $updateResult.Payload | Should -BeExactly 'Currencies: [GBP], [CHF], [CUC], (***), [GHS]';
      }
    }

    Context 'and: Pattern defines named captures' {
      It 'should: rename accessing Pattern defined capture' {
        [string]$source = '21-04-2000, Party like its 31-12-1999, today is 24-09-2020';
        [RegEx]$pattern = new-expr('(?<day>\d{2})-(?<mon>\d{2})-(?<year>\d{4})');

        [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -PatternOccurrence '1' `
          -Paste 'Americanised: ${mon}-${day}-${year}';

        $updateResult.Payload | Should -BeExactly 'Americanised: 04-21-2000, Party like its 31-12-1999, today is 24-09-2020';
      }

      It 'should: rename accessing Pattern defined capture' {
        [string]$source = '21-04-2000, Party like its 31-12-1999, today is 24-09-2020';
        [RegEx]$pattern = new-expr('(?<day>\d{2})-(?<mon>\d{2})-(?<year>\d{4})');

        [PSCustomObject]$updateResult = Update-Match -Value $source -Pattern $pattern -PatternOccurrence '2' `
          -Paste 'Americanised: ${mon}-${day}-${year}';

        $updateResult.Payload | Should -BeExactly '21-04-2000, Party like its Americanised: 12-31-1999, today is 24-09-2020';
      }
    }
  } # NTH
} # Update-Match
