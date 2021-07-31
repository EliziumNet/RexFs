---
external help file: Elizium.RexFs-help.xml
Module Name: Elizium.RexFs
online version:
schema: 2.0.0
---

# Add-Appendage

## SYNOPSIS

The core appendage action function principally used by Rename-Many. Adds either
a prefix or suffix to the Value.

## SYNTAX

```powershell
Add-Appendage [-Value] <String> [-Appendage] <String> [-Type] <String> [[-Copy] <Regex>]
 [[-CopyOccurrence] <String>] [-Diagnose] [<CommonParameters>]
```

## DESCRIPTION

Returns a new string that reflects the addition of an appendage, which can be Prepend
or Append. The appendage itself can be static text, or can act like a formatter supporting
Copy named group reference s, if present. The user can decide to reference the whole Copy
match with ${_c}, or if it contains named captures, these can be referenced inside the
appendage as ${\<group-name-ref\>}

## EXAMPLES

### Example 1

```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Appendage

String to either prepend or append to Value. Supports named captures inside Copy regex
parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Copy

Regular expression string applied to $Value, indicating a portion which should be copied and
inserted into the Appendage. The match defined by $Copy is stored in special variable ${_c} and
can be referenced as such from $Appendage.

```yaml
Type: Regex
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Diagnose

switch parameter that indicates the command should be run in WhatIf mode. When enabled
it presents additional information that assists the user in correcting the un-expected
results caused by an incorrect/un-intended regular expression. The current diagnosis
will show the contents of named capture groups that they may have specified. When an item
is not renamed (usually because of an incorrect regular expression), the user can use the
diagnostics along side the 'Not Renamed' reason to track down errors.

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

### -Type

Denotes the appendage type, can be 'Prepend' or 'Append'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Prepend, Append

Required: True
Position: 2
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

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS

[Elizium.RexFs](https://github.com/EliziumNet/RexFs)
