---
external help file: Elizium.BulkRenamer-help.xml
Module Name: Elizium.BulkRenamer
online version:
schema: 2.0.0
---

# Format-Escape

## SYNOPSIS

Escapes the regular expression specified. This is just a wrapper around the
.net regex::escape method, but gives the user a much easier way to
invoke it from the command line.

## SYNTAX

```powershell
Format-Escape [-Source] <Object> [<CommonParameters>]
```

## DESCRIPTION

Various functions in Loopz have parameters that accept a regular expression. This
function gives the user an easy way to escape the regex, without them having to do
this manually themselves which could be tricky to get right depending on their
requirements. NB: an alternative to using the 'esc' function is to add a ~ to the start
of the pattern. The tilde is not taken as part of the pattern and is stripped off.
If a partial escape is required, then split the value into parts that require escaping and
the other parts that don't.

## EXAMPLES

### Example 1

```powershell
Rename-Many -Pattern $(esc('(123)'))
```

Use the 'esc' alias with the Rename-Many command, escaping the regex characters in the Pattern definition.

### EXAMPLE 2 (Use with Rename-Many command)

```powershell
Rename-Many -Pattern '~(123)'
```

Use a leading '~' in the pattern definition, to escape the whole value.

### EXAMPLE 3 (Use with Rename-Many command)

```powershell
Rename-Many -Pattern $(esc('(123)') + '(?<n>\d{3})')
```

Partial escape defined by concatenating patterns individually escaped or not.

## PARAMETERS

### -Source

The source string to escape.

```yaml
Type: Object
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

[Elizium.BulkRenamer](https://github.com/EliziumNet/BulkRenamer)
