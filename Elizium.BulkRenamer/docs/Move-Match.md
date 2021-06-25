---
external help file: Elizium.BulkRenamer-help.xml
Module Name: Elizium.BulkRenamer
online version:
schema: 2.0.0
---

# Move-Match

## SYNOPSIS

The core move match action function principally used by Rename-Many. Moves a
match according to the specified anchor(s).

## SYNTAX

### MoveToEnd

```powershell
Move-Match [-Value] <String> [-Pattern] <Regex> [-PatternOccurrence <String>] [-Copy <Regex>]
 [-CopyOccurrence <String>] [-With <String>] [-End] [-Drop <String>] [-Diagnose] [-Marker <Char>]
 [<CommonParameters>]
```

### MoveToStart

```powershell
Move-Match [-Value] <String> [-Pattern] <Regex> [-PatternOccurrence <String>] [-Copy <Regex>]
 [-CopyOccurrence <String>] [-With <String>] [-Start] [-Drop <String>] [-Diagnose] [-Marker <Char>]
 [<CommonParameters>]
```

### MoveToAnchor

```powershell
Move-Match [-Value] <String> [-Pattern] <Regex> [-PatternOccurrence <String>] -Anchor <Regex>
 [-AnchorOccurrence <String>] [-Relation <String>] [-Copy <Regex>] [-CopyOccurrence <String>] [-With <String>]
 [-Drop <String>] [-Diagnose] [-Marker <Char>] [<CommonParameters>]
```

### HybridEnd

```powershell
Move-Match [-Value] <String> [-Pattern] <Regex> [-PatternOccurrence <String>] -Anchor <Regex>
 [-AnchorOccurrence <String>] [-Relation <String>] [-Copy <Regex>] [-CopyOccurrence <String>] [-With <String>]
 [-End] [-Drop <String>] [-Diagnose] [-Marker <Char>] [<CommonParameters>]
```

### HybridStart

```powershell
Move-Match [-Value] <String> [-Pattern] <Regex> [-PatternOccurrence <String>] -Anchor <Regex>
 [-AnchorOccurrence <String>] [-Relation <String>] [-Copy <Regex>] [-CopyOccurrence <String>] [-With <String>]
 [-Start] [-Drop <String>] [-Diagnose] [-Marker <Char>] [<CommonParameters>]
```

### NoReplacement

```powershell
Move-Match [-Value] <String> -Cut <Regex> [-CutOccurrence <String>] [-Diagnose] [-Marker <Char>]
 [<CommonParameters>]
```

## DESCRIPTION

Returns a new string that reflects moving the specified $Pattern match to either
the location designated by $Anchor/$AnchorOccurrence/$Relation or to the Start or
End of the value indicated by the presence of the $Start/$End switch parameters.

First Move-Match, removes the Pattern match from the source. This makes the With and
Anchor match against the remainder ($patternRemoved) of the source. This way, there is
no overlap between the Pattern match and With/Anchor and it also makes the functionality more
understandable for the user. NB: $Pattern only tells you what to remove, but it's the
$With, $Copy and $Paste that defines what to insert, with the $Anchor/$Start/$End
defining where the replacement text should go. The user should not be using named capture
groups in $Copy, or $Anchor, rather, they should be defined inside $Paste and referenced
inside $Paste/$With.

## EXAMPLES

### EXAMPLE 1 (Anchor)

```powershell
Move-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Anchor ' -' -Relation 'before'
```

Move a match before an anchor

### EXAMPLE 2 (Anchor)

```powershell
Move-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Anchor ' -' -Relation 'before' -Drop '-'
```

Move a match before an anchor and drop a literal in place of Pattern

### EXAMPLE 3 (Hybrid Anchor)

```powershell
Move-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Anchor ' -' -End -Relation 'before' -Drop '-'
```

Move a match before an anchor, if anchor match fails, then move to end, then drop a literal in place of Pattern.

### EXAMPLE 4 (Anchor with Occurrence)

```powershell
Move-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Anchor ' -' -Relation 'before' -AnchorOccurrence 'l'
```

### EXAMPLE 5 (Result formatted by With, named group reference)

```powershell
Move-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Anchor ' -' -With '--(${dt})--'
```

Move a match to the anchor, and format the output including group references, no anchor

### EXAMPLE 6 (Result formatted by With, named group reference and insert anchor)

```powershell
Move-Match 'VAL 1999-02-21 + RH - CLOSE' '(?\<dt\>\d{4}-\d{2}-\d{2})' -Anchor ' -' -With '${_a}, --(${dt})--'
```

Move a match to the anchor, and format the output including group references, insert anchor

## PARAMETERS

### -Anchor

Anchor is a regular expression string applied to $Value (after the $Pattern match has
been removed). The $Pattern match that is removed is inserted at the position indicated
by the anchor match in collaboration with the $Relation parameter.

```yaml
Type: Regex
Parameter Sets: MoveToAnchor, HybridEnd, HybridStart
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AnchorOccurrence

Can be a number or the letters f, l

* f: first occurrence
* l: last occurrence
* \<number\>: the nth occurrence

```yaml
Type: String
Parameter Sets: MoveToAnchor, HybridEnd, HybridStart
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Copy

Regular expression string applied to $Value (after the $Pattern match has been removed),
indicating a portion which should be copied and re-inserted (via the $Paste parameter;
see $Paste or $With). Since this is a regular expression to be used in $Paste/$With, there
is no value in the user specifying a static pattern, because that static string can just be
defined in $Paste/$With. The value in the $Copy parameter comes when a generic pattern is
defined eg \d{3} (is non static), specifies any 3 digits as opposed to say '123', which
could be used directly in the $Paste/$With parameter without the need for $Copy. The match
defined by $Copy is stored in special variable ${_c} and can be referenced as such from
$Paste and $With.

```yaml
Type: Regex
Parameter Sets: MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
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
Parameter Sets: MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Cut

Regular expression object that indicates which part of the $Value that
either needs removed as part of overall rename operation. Those characters
in $Value which match $Cut, are removed.

```yaml
Type: Regex
Parameter Sets: NoReplacement
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CutOccurrence

Can be a number or the letters f, l

* f: first occurrence
* l: last occurrence
* \<number>: the nth occurrence

```yaml
Type: String
Parameter Sets: NoReplacement
Aliases:

Required: False
Position: Named
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
diagnostics along side the 'Not Renamed' reason to track down errors. When $Diagnose has
been specified, $WhatIf does not need to be specified.

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

### -Drop

A string parameter (only applicable to move operations, ie any of these Anchor/Star/End
are present) that defines what text is used to replace the $Pattern match. So in this
use-case, the user wants to move a particular token/pattern to another part of the name
and at the same time drop a static string in the place where the $Pattern was removed from.
The user can also reference named group captures defined inside Pattern or Copy. (Note that
the whole Copy capture can be referenced with ${_c}.)

```yaml
Type: String
Parameter Sets: MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -End

Is another type of anchor used instead of $Anchor and specifies that the $Pattern match
should be moved to the end of the new name.

```yaml
Type: SwitchParameter
Parameter Sets: MoveToEnd, HybridEnd
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Marker

A character used to mark the place where the $Pattern was removed from. It should be a
special character that is not easily typed on the keyboard by the user so as to not
interfere wth $Anchor/$Copy matches which occur after $Pattern match is removed.

```yaml
Type: Char
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pattern

Regular expression object that indicates which part of the $Value that either needs to be moved or replaced as part of overall rename operation. Those characters in $Value which match $Pattern, are removed.

```yaml
Type: Regex
Parameter Sets: MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
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
* \<number>: the nth occurrence

```yaml
Type: String
Parameter Sets: MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Relation

Used in conjunction with the $Anchor parameter and can be set to either 'before' or
'after' (the default). Defines the relationship of the $Pattern match with the $Anchor
match in the new name for $Value.

```yaml
Type: String
Parameter Sets: MoveToAnchor, HybridEnd, HybridStart
Aliases:
Accepted values: before, after

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Start

Is another type of anchor used instead of $Anchor and specifies that the $Pattern match
should be moved to the start of the new name.

```yaml
Type: SwitchParameter
Parameter Sets: MoveToStart, HybridStart
Aliases:

Required: True
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

### -With

This is a NON regular expression string. It would be more accurately described as a formatter.
Defines what text is used as the replacement for the $Pattern
match. $With can reference special variables:

* $0: the pattern match
* ${_a}: the anchor match
* ${_c}: the copy match

When $Pattern contains named capture groups, these variables can also be referenced. Eg if the
$Pattern is defined as '(?\<day>\d{1,2})-(?\<mon>\d{1,2})-(?\<year>\d{4})', then the variables
${day}, ${mon} and ${year} also become available for use in $With.
Typically, $With is static text which is used to replace the $Pattern match and is inserted
according to the Anchor match, (or indeed $Start or $End).

```yaml
Type: String
Parameter Sets: MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
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

### System.String

## NOTES

## RELATED LINKS

[Elizium.BulkRenamer](https://github.com/EliziumNet/BulkRenamer)
