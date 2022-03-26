using namespace System.Management.Automation;
using namespace System.Collections;
using namespace System.IO;
using namespace System.Text;
using module Elizium.Krayola;
using module Elizium.Loopz;

Describe "Rename-ByNo" -Tag "reno" {
  BeforeAll {

    Get-Module Elizium.RexFs | Remove-Module -Force;
    Import-Module .\Output\Elizium.RexFs\Elizium.RexFs.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force

    Import-Module Assert;
    [boolean]$global:_whatIf = $true;
    [boolean]$global:_test = $true;

    [string]$global:_directoryPath = './Tests/Data/times/';

    Mock -ModuleName Elizium.RexFs rename-FsItem {
      param(
        [FileSystemInfo]$From,
        [string]$To,
        [object]$UndoOperant
      )
      #
      # This mock result works only because the actual returned FileSystemInfo returned
      # does not drive any control logic.

      if ($global:_expected) {
        # NOTE: Since this rename-FsItem mock is only invoked, if there is actually a rename to be
        # performed, expectations do not need (or rather should not) add expectations for scenarios
        # where the new name is the same as the original name (ie not renamed due to a non match).
        #
        test-RenameExpect -Expects $global:_expected -Item $From.Name -Actual $To;
      }
      return $To;
    }

    Mock -ModuleName Elizium.RexFs Get-IsLocked {
      return $true;
    }
  } # BeforeAll

  BeforeEach {
    InModuleScope Elizium.RexFs {
      $global:_expected = $null;
    }
  }

  Context "given: file sorted in <Order> order, formatted as <Format>" {
    It "should: renumber as <Expected>" -TestCases @(
      # ASCENDING
      #
      @{
        Format   = "foo-bar_<i>";
        Order    = "asc";
        Expected = @{
          "01 - (B) Akoustik.txt"          = "foo-bar_0001.txt";
          "02 - (C) Lodgikal Nonsense.txt" = "foo-bar_0002.txt";
          "03 - (A) Mind In Rewind.txt"    = "foo-bar_0003.txt";
        }
      },

      @{
        Format   = "foo-bar-<i:2,_>";
        Order    = "asc";
        Expected = @{
          "01 - (B) Akoustik.txt"          = "foo-bar-_1.txt";
          "02 - (C) Lodgikal Nonsense.txt" = "foo-bar-_2.txt";
          "03 - (A) Mind In Rewind.txt"    = "foo-bar-_3.txt";
        }
      }

      @{
        Format   = "foo-bar-<i:6,0>";
        Order    = "asc";
        Expected = @{
          "01 - (B) Akoustik.txt"          = "foo-bar-000001.txt";
          "02 - (C) Lodgikal Nonsense.txt" = "foo-bar-000002.txt";
          "03 - (A) Mind In Rewind.txt"    = "foo-bar-000003.txt";
        }
      },

      # DESCENDING
      #
      @{
        Format   = "foo-bar_<i>";
        Order    = "desc";
        Expected = @{
          "03 - (A) Mind In Rewind.txt"    = "foo-bar_0003.txt";
          "02 - (C) Lodgikal Nonsense.txt" = "foo-bar_0002.txt";
          "01 - (B) Akoustik.txt"          = "foo-bar_0001.txt";
        }
      },

      @{
        Format   = "foo-bar-<i:2,_>";
        Order    = "desc";
        Expected = @{
          "03 - (A) Mind In Rewind.txt"    = "foo-bar-_3.txt";
          "02 - (C) Lodgikal Nonsense.txt" = "foo-bar-_2.txt";
          "01 - (B) Akoustik.txt"          = "foo-bar-_1.txt";
        }
      }

      @{
        Format   = "foo-bar-<i:6,0>";
        Order    = "desc";
        Expected = @{
          "03 - (A) Mind In Rewind.txt"    = "foo-bar-000003.txt";
          "02 - (C) Lodgikal Nonsense.txt" = "foo-bar-000002.txt";
          "01 - (B) Akoustik.txt"          = "foo-bar-000001.txt";
        }
      }
    ) {
      InModuleScope Elizium.RexFs -Parameters @{
        Format   = $Format;
        Order    = $Order;
        Expected = $Expected
      } {
        [array]$unsorted = Get-ChildItem $_directoryPath;
        $global:_expected = $Expected;

        # can't invoke an expression in middle of pipeline, hence ugly if statement
        #
        if ($Order -eq "asc") {
          $unsorted | asc | Rename-ByNo -Format $format -WhatIf:$_whatIf -Test:$_test;
        }
        elseif ($Order -eq "desc") {
          $unsorted | desc | Rename-ByNo -Format $format -WhatIf:$_whatIf -Test:$_test;
        }
        else {
          throw "bad test definition, Order is mis-defined: '$Order'";
        }          
      }
    }

    Context "given: custom compute" {
      It "should: rename according to custom script-block" {
        [array]$unsorted = Get-ChildItem $_directoryPath;
        [string]$format = "foo-bar_<i>";
        [scriptblock]$increment = [scriptblock] {
          [OutputType([int])]
          param(
            [int]$number
          )
          return $number + 1;
        }

        $unsorted | asc | Rename-ByNo -Format $format -Compute $increment -WhatIf:$_whatIf -Test:$_test;

        $expected = @{
          "01 - (B) Akoustik.txt"          = "foo-bar_0002.txt";
          "02 - (C) Lodgikal Nonsense.txt" = "foo-bar_0003.txt";
          "03 - (A) Mind In Rewind.txt"    = "foo-bar_0004.txt";
        }

        $global:_expected = $expected;
      }
    }
  }
}