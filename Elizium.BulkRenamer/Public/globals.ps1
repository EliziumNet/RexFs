
$global:BulkRn = [PSCustomObject]@{
  Defaults = [PSCustomObject]@{
    Remy = [PSCustomObject]@{
      Marker  = [char]0x2BC1;

      Context = [PSCustomObject]@{
        Title             = 'Rename';
        ItemMessage       = 'Rename Item';
        SummaryMessage    = 'Rename Summary';
        Locked            = 'BULKRN_REMY_LOCKED';
        UndoDisabledEnVar = 'BULKRN_REMY_UNDO_DISABLED';
        OperantShortCode  = 'remy';
      }
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
}
