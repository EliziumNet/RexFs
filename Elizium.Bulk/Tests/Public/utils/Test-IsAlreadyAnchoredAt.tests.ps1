
Describe 'Test-IsAlreadyAnchoredAt' {
  BeforeAll {
    Get-Module Elizium.Bulk | Remove-Module -Force;;
    Import-Module .\Output\Elizium.Bulk\Elizium.Bulk.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;
  }

  BeforeAll {
    [string]$script:_source = 'ABCDEA';
  }

  Context 'given: Anchored At Start' {
    Context 'and: input source contains fake match at start' {
      Context 'and: requested occurrence not already at start' {
        It 'should: return $false' {
          [regex]$expressionObj = 'A';

          Test-IsAlreadyAnchoredAt -Source $_source -Start `
            -Expression $expressionObj -Occurrence 'l' | Should -BeFalse;
        }

        It 'should: $false' {
          [string]$source = '01-09 - Airwaves';
          [regex]$expressionObj = '\d{2}';

          Test-IsAlreadyAnchoredAt -Source $source -Start `
            -Expression $expressionObj -Occurrence '2' | Should -BeFalse;
        }
      }

      Context 'and: requested occurrence IS already at start' {
        It 'should: return $true' {
          [regex]$expressionObj = 'A';

          Test-IsAlreadyAnchoredAt -Source $_source -Start `
            -Expression $expressionObj -Occurrence 'f' | Should -BeTrue;
        }

        It 'should: $true' {
          [string]$source = '01-09 - Airwaves';
          [regex]$expressionObj = '\d{2}';

          Test-IsAlreadyAnchoredAt -Source $source -Start `
            -Expression $expressionObj -Occurrence '1' | Should -BeTrue;
        }
      }
    } # and: input source contains fake match at start

    Context 'and: input source does NOT contain fake match at start' {
      Context 'and: requested occurrence not already at start' {
        It 'should: return $false' {
          [regex]$expressionObj = 'C';

          Test-IsAlreadyAnchoredAt -Source $_source -Start `
            -Expression $expressionObj -Occurrence 'f' | Should -BeFalse;
        }
      }
    } # and: input source does NOT contain fake match at start

    Context 'and: regex does not match source' {
      It 'should: return $false' {
        [string]$source = 'duff';
        [regex]$expressionObj = 'A';

        Test-IsAlreadyAnchoredAt -Source $source -Start `
          -Expression $expressionObj -Occurrence 'f' | Should -BeFalse;
      }
    }
  } # given: Anchored At Start

  Context 'given: Anchored At End' {
    Context 'and: input source contains fake match at end' {
      Context 'and: requested occurrence not already at end' {
        It 'should: return $false' {
          [regex]$expressionObj = 'A';

          Test-IsAlreadyAnchoredAt -Source $_source -End `
            -Expression $expressionObj -Occurrence 'f' | Should -BeFalse;
        }
      }

      Context 'and: requested occurrence IS already at end' {
        It 'should: return $false' {
          [regex]$expressionObj = 'A';

          Test-IsAlreadyAnchoredAt -Source $_source -End `
            -Expression $expressionObj -Occurrence 'l' | Should -BeTrue;
        }
      }
    } # and: input source contains fake match at end

    Context 'and: input source does NOT contain fake match at end' {
      Context 'and: requested occurrence not already at end' {
        It 'should: return $false' {
          [regex]$expressionObj = 'C';

          Test-IsAlreadyAnchoredAt -Source $_source -End `
            -Expression $expressionObj -Occurrence 'f' | Should -BeFalse;
        }
      }
    } # and: input source does NOT contain fake match at end

    Context 'and: regex does not match source' {
      It 'should: return $false' {
        [string]$source = 'duff';
        [regex]$expressionObj = 'A';

        Test-IsAlreadyAnchoredAt -Source $source -End `
          -Expression $expressionObj -Occurrence 'l' | Should -BeFalse;
      }
    }
  } # given: Anchored At End
} # Test-IsAlreadyAnchoredAt
