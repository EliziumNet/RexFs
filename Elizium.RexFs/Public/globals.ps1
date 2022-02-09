
$global:RexFs = [PSCustomObject]@{
  Defaults = [PSCustomObject]@{
    Remy = [PSCustomObject]@{
      Marker  = [char]0x2BC1;

      Context = [PSCustomObject]@{
        Title             = 'Rename';
        ItemMessage       = 'Rename Item';
        SummaryMessage    = 'Rename Summary';
        Locked            = 'REXFS_REMY_LOCKED';
        UndoDisabledEnVar = 'REXFS_REMY_UNDO_DISABLED';
        OperantShortCode  = 'remy';
      }
    }

    Reno = [PSCustomObject]@{
      Pattern = "\<[iI](?:\:(?<n>\d{1,2})(?:\,(?<pad>[0\s_]))?)?\>";
      Pad     = "0";
      Width   = 4;
    }
  }

  Rules    = [PSCustomObject]@{
    Remy = @(
      @{
        ID             = 'MissingCapture';
        'IsApplicable' = [scriptblock] {
          param([string]$_Input)
          $_Input -match '\$\{\w+\}';
        };

        'Transform'    = [scriptblock] {
          param([string]$_Input)
          $_Input -replace "\$\{\w+\}", ''
        };
        'Signal'       = 'MISSING-CAPTURE'
      },

      @{
        ID             = 'Trim';
        'IsApplicable' = [scriptblock] {
          param([string]$_Input)
          $($_Input.StartsWith(' ') -or $_Input.EndsWith(' '));
        };

        'Transform'    = [scriptblock] {
          param([string]$_Input)
          $_Input.Trim();
        };
        'Signal'       = 'TRIM'
      },

      @{
        ID             = 'Dashes';
        'IsApplicable' = [scriptblock] {
          param([string]$_Input)
          $_Input -match '(?:\s{,2})?(?:-\s+-)|(?:--)(?:\s{,2})?';
        };

        'Transform'    = [scriptblock] {
          param([string]$_Input)

          [regex]$regex = [regex]::new('(?:\s{,2})?(?:-\s+-)|(?:--)(?:\s{,2})?');
          [string]$result = $_Input;

          while ($regex.IsMatch($result)) {
            $result = $regex.Replace($result, ' - ');
          }
          $result;
        };
        'Signal'       = 'REMY.DASHES'
      },

      @{
        ID             = 'Spaces';
        'IsApplicable' = [scriptblock] {
          param([string]$_Input)
          $_Input -match "\s{2,}";
        };

        'Transform'    = [scriptblock] {
          param([string]$_Input)
          $_Input -replace "\s{2,}", ' '
        };
        'Signal'       = 'MULTI-SPACES'
      }
    );
  }

  Compute  = [PSCustomObject]@{
    Reno = [PSCustomObject]@{
      Add1   = [scriptblock] {
        [OutputType([int])]
        param(
          [int]$number
        )
        return $number + 1;
      }
      Double = [scriptblock] {
        [OutputType([int])]
        param(
          [int]$number
        )
        return $number * 2;
      }
    }
  }
}
