---
external help file: Elizium.BulkRenamer-help.xml
Module Name: Elizium.BulkRenamer
online version:
schema: 2.0.0
---

# Test-IsAlreadyAnchoredAt

## SYNOPSIS

Checks to see if a given pattern is matched at the start or end of an input string.

## SYNTAX

```powershell
Test-IsAlreadyAnchoredAt [[-Source] <String>] [[-Expression] <Regex>] [[-Occurrence] <String>] [-Start] [-End]
 [<CommonParameters>]
```

## DESCRIPTION

When Rename-Many uses the Start or End switches to move a match to the corresponding location,
it needs to filter out those entries where the specified occurrence of the Pattern is already
at the desire location. We can't do this using a synthetic anchored regex using ^ and $, rather
we must use the origin regex, perform the match and then see where that match resides, by consulting
the index and length of that match instance.

## EXAMPLES

### Example 1

```powershell
  [string]$source = 'ABCDEA';
  [regex]$reg = 'A';

  Test-IsAlreadyAnchoredAt -Source $source -Start -Expression $reg -Occurrence 'f';
```

Requested occurrence 'A' IS already at start of the source string 'ABCDEA', will return true.

## PARAMETERS

### -End

Check match is at the end of the input source

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

### -Expression

A regex instance to match against

```yaml
Type: Regex
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Occurrence

Which match occurrence in Expression do we want to check

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Source

The input source

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Start

Check match is at the start of the input source

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Boolean

## NOTES

## RELATED LINKS

[Elizium.BulkRenamer](https://github.com/EliziumNet/BulkRenamer)
