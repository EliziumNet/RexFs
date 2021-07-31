
Describe 'Format-Escape' {
  BeforeAll {
    Get-Module Elizium.RexFs | Remove-Module -Force;
    Import-Module .\Output\Elizium.RexFs\Elizium.RexFs.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;
  }

  Context 'Format-Escape' {
    Context 'given: pattern contains no characters requiring escape' {
      It 'should: return pattern unmodified' {
        esc('one') | Should -BeExactly 'one';
      }
    } # given: pattern contains no characters requiring escape

    Context 'given: pattern contains characters requiring escape' {
      It 'should: return escaped pattern' {
        esc('^*one*$') | Should -BeExactly '\^\*one\*\$';
      }
    } # given: pattern contains no characters requiring escape
  }
}
