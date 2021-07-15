
Describe 'invoke-PostProcessing' {

  BeforeAll {
    Get-Module Elizium.Bulk | Remove-Module -Force;
    Import-Module .\Output\Elizium.Bulk\Elizium.Bulk.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;

    InModuleScope Elizium.Bulk {
      [hashtable]$script:_signals = @{
        'REMY.POST'       = kp(@('Post Process', '🐋'));
        'TRIM'            = kp(@('Trim', '🍀'));
        'MULTI-SPACES'    = kp(@('Spaces', '🐠'));
        'MISSING-CAPTURE' = kp(@('Missing Capture', '🐬'));
        'REMY.DASHES'     = kp(@('Dashes', '🐦'));
      }
    }
  }

  Context 'given: input source with no applicable rules' {
    It 'should: return input source un-modified' {
      InModuleScope Elizium.Bulk {
        [string]$source = 'this is a normal result';
        [PSCustomObject]$post = invoke-PostProcessing -InputSource $source -Rules $Bulk.Rules.Remy `
          -Signals $_signals;

        $post.Modified | Should -BeFalse;
        $post.TransformResult | Should -BeExactly $source;
      }
    }
  }

  Context 'given: input source with consecutive spaces' {
    It 'should: apply SPACES rule' {
      InModuleScope Elizium.Bulk {
        [string]$source = 'this      is a  messy   result';

        [PSCustomObject]$post = invoke-PostProcessing -InputSource $source -Rules $Bulk.Rules.Remy `
          -Signals $_signals;

        $post.Modified | Should -BeTrue;
        $post.TransformResult | Should -BeExactly 'this is a messy result';
        $post.Signals | Should -HaveCount 1;
        $post.Signals[0] | Should -BeExactly 'MULTI-SPACES';
        $post.Indication | Should -Not -BeNullOrEmpty;

        Write-Debug ">>> INDICATION: '$($post.Label)' > '$($post.Indication)'";
      }
    }
  }

  Context 'given: input source with leading/trailing spaces' {
    It 'should: apply TRIM rule' {
      InModuleScope Elizium.Bulk {
        [string]$source = '  this is a trim-able result  ';

        [PSCustomObject]$post = invoke-PostProcessing -InputSource $source -Rules $Bulk.Rules.Remy `
          -Signals $_signals;

        $post.Modified | Should -BeTrue;
        $post.TransformResult | Should -BeExactly 'this is a trim-able result';
        $post.Signals | Should -HaveCount 1;
        $post.Signals[0] | Should -BeExactly 'TRIM';
        $post.Indication | Should -Not -BeNullOrEmpty;

        Write-Debug ">>> INDICATION: '$($post.Label)' > '$($post.Indication)'";
      }
    }
  }

  Context 'given: input source with <Dashes>' {
    It 'should: apply DASHES rule' -TestCases @(
      @{ Dashes = '- -'; },
      @{ Dashes = '--'; },
      @{ Dashes = '- - -- -'; }
      @{ Dashes = '- -- -'; }
      @{ Dashes = '- - -'; }
      @{ Dashes = '- --- -'; }
    ) {
      InModuleScope Elizium.Bulk -Parameters @{ Dashes = $Dashes } {
        param(
          [string]$Dashes
        )
        [string]$source = "Summer Solstice$($Dashes)by Fields Of The Nephilim";

        [PSCustomObject]$post = invoke-PostProcessing -InputSource $source -Rules $Bulk.Rules.Remy `
          -Signals $_signals;

        $post.Modified | Should -BeTrue;
        $post.TransformResult | Should -BeExactly 'Summer Solstice - by Fields Of The Nephilim';
        $post.Signals.Count | Should -BeGreaterThan 0;
        $post.Signals[0] | Should -BeExactly 'REMY.DASHES';
        $post.Indication | Should -Not -BeNullOrEmpty;

        Write-Debug ">>> INDICATION: '$($post.Label)' > '$($post.Indication)'";
      }
    }
  }

  Context 'given: input source with consecutive spaces and consecutive spaces' {
    It 'should: apply SPACES & TRIM rules' {
      InModuleScope Elizium.Bulk {
        [string]$source = ' this      is a  really messy  and trim-able   result  ';

        [PSCustomObject]$post = invoke-PostProcessing -InputSource $source -Rules $Bulk.Rules.Remy `
          -Signals $_signals;

        $post.Modified | Should -BeTrue;
        $post.TransformResult | Should -BeExactly 'this is a really messy and trim-able result';
        $post.Signals | Should -HaveCount 2;
        $post.Indication | Should -Not -BeNullOrEmpty;

        Write-Debug ">>> INDICATION: '$($post.Label)' > '$($post.Indication)'";
      }
    }
  }

  Context 'given: input source with an un-resolved named capture' {
    It 'should: apply MissingCapture rule' {
      InModuleScope Elizium.Bulk {
        [string]$source = 'there are unresolved ${foo}named capture ${bar}groups here';

        [PSCustomObject]$post = invoke-PostProcessing -InputSource $source -Rules $Bulk.Rules.Remy `
          -Signals $_signals;

        $post.Modified | Should -BeTrue;
        $post.TransformResult | Should -BeExactly 'there are unresolved named capture groups here';
        $post.Signals | Should -HaveCount 1;
        $post.Signals[0] | Should -BeExactly 'MISSING-CAPTURE';
        $post.Indication | Should -Not -BeNullOrEmpty;

        Write-Debug ">>> INDICATION: '$($post.Label)' > '$($post.Indication)'";
      }
    }
  }

  Context 'given: input source with an un-resolved named capture' {
    # Application of one 1 rule requires the application of another rule, in this
    # case, SPACES rule
    #
    It 'should: apply MissingCapture and SPACES rule' {
      InModuleScope Elizium.Bulk {
        [string]$source = 'there are unresolved ${foo} named capture ${bar} groups here';

        [PSCustomObject]$post = invoke-PostProcessing -InputSource $source -Rules $Bulk.Rules.Remy `
          -Signals $_signals;

        $post.Modified | Should -BeTrue;
        $post.TransformResult | Should -BeExactly 'there are unresolved named capture groups here';
        $post.Signals | Should -HaveCount 2;
        $post.Indication | Should -Not -BeNullOrEmpty;

        Write-Debug ">>> INDICATION: '$($post.Label)' > '$($post.Indication)'";
      }
    }
  }
}
