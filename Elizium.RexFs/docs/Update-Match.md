---
external help file: Elizium.RexFs-help.xml
Module Name: Elizium.RexFs
online version:
schema: 2.0.0
---

# Update-Match

## SYNOPSIS

The core update match action function principally used by Rename-Many. Updates
$Pattern match in it's current location.

## SYNTAX

```powershell
Update-Match [-Value] <String> [-Pattern] <Regex> [-PatternOccurrence <String>] [-Copy <Regex>]
 [-CopyOccurrence <String>] [-Paste <String>] [-Diagnose] [<CommonParameters>]
```

## DESCRIPTION

Returns a new string that reflects updating the specified $Pattern match.
  Firstly, Update-Match removes the Pattern match from $Value. This makes the Paste and
Copy match against the remainder ($patternRemoved) of $Value. This way, there is
no overlap between the Pattern match and $Paste and it also makes the functionality more
understandable for the user. NB: Pattern only tells you what to remove, but it's the
Copy and Paste that defines what to insert.

## EXAMPLES

### EXAMPLE 1

```powershell
Update-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Paste '----X--X--'
```

Update with literal content

### EXAMPLE 2

```powershell
[string]$today = Get-Date -Format 'yyyy-MM-dd'
Update-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Paste $('_(' + $today + ')_')
```

Update with variable content

### EXAMPLE 3

```powershell
Update-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Paste '${_c},----X--X--' -Copy '[^\s]+'
```

Update with whole copy reference

### EXAMPLE 4

```powershell
Update-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Paste '${first},----X--X--' -Copy '(?<first>[^\s]+)'
```

Update with group references

### EXAMPLE 5

```powershell
Update-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Paste '${_c},----X--X--' -Copy '[^\s]+' -CopyOccurrence 2
```

Update with 2nd copy occurrence

## PARAMETERS

### -Copy

  Regular expression string applied to $Value (after the $Pattern match has been removed),
indicating a portion which should be copied and re-inserted (via the $Paste parameter;
see $Paste). Since this is a regular expression to be used in $Paste, there
is no value in the user specifying a static pattern, because that static string can just be
defined in $Paste. The value in the $Copy parameter comes when a non literal pattern is
defined eg \d{3} (is non literal), specifies any 3 digits as opposed to say '123', which
could be used directly in the $Paste parameter without the need for $Copy. The match
defined by $Copy is stored in special variable ${_c} and can be referenced as such from
$Paste.

```yaml
Type: Regex
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CopyOccurrence

Can be a number or the letters f, l

* f: first occurrence
* l: last occurrence
* \<number\>: the nth occurrence

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Diagnose

switch parameter that indicates the command should be run in WhatIf mode. When enabled it presents additional information that assists the user in correcting the un-expected results caused by an incorrect/un-intended regular expression. The current diagnosis will show the contents of named capture groups that they may have specified. When an item is not renamed (usually because of an incorrect regular expression), the user can use the diagnostics along side the 'Not Renamed' reason to track down errors.
When $Diagnose has been specified, $WhatIf does not need to be specified.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Paste

Formatter parameter for Update operations. Can contain named/numbered group references
defined inside regular expression parameters, or use special named references $0 for the whole
Pattern match and ${_c} for the whole Copy match. The Paste can also contain named/numbered
group references defined in $Pattern.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pattern

Regular expression string that indicates which part of the $Value that either needs
to be moved or replaced as part of overall rename operation. Those characters in $Value
which match $Pattern, are removed.

```yaml
Type: Regex
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PatternOccurrence

Can be a number or the letters f, l

* f: first occurrence
* l: last occurrence
* \<number\>: the nth occurrence

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value

The source value against which regular expressions are applied.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS

[Elizium.RexFs](https://github.com/EliziumNet/RexFs)
