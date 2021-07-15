---
external help file: Elizium.Bulk-help.xml
Module Name: Elizium.Bulk
online version:
schema: 2.0.0
---

# Rename-Many

## SYNOPSIS

Performs a bulk rename for all file system objects delivered through the pipeline, via regular expression replacement. For more information, please see [UPDATE THIS LINK Bulk Renamer](https://github.com/EliziumNet/Loopz/blob/master/resources/docs/bulk-renamer.md)

## SYNTAX

### UpdateInPlace (Default)

```powershell
Rename-Many -underscore <FileSystemInfo> [-Pattern] <Array> [-Copy <Array>] [[-With] <String>] -Paste <String>
 [-File] [-Directory] [-Except <String>] [-Include <String>] [-Whole <String>] [-Condition <ScriptBlock>]
 [-Top <Int32>] [-Context <PSObject>] [-Diagnose] [-Test] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Transformer

```powershell
Rename-Many -underscore <FileSystemInfo> [-Pattern] <Array> [-File] [-Directory] [-Except <String>]
 [-Include <String>] [-Whole <String>] [-Condition <ScriptBlock>] [-Top <Int32>] -Transform <ScriptBlock>
 [-Context <PSObject>] [-Diagnose] [-Test] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### MoveToEnd

```powershell
Rename-Many -underscore <FileSystemInfo> [-Pattern] <Array> [-Copy <Array>] [[-With] <String>] [-End]
 [-Drop <String>] [-File] [-Directory] [-Except <String>] [-Include <String>] [-Whole <String>]
 [-Condition <ScriptBlock>] [-Top <Int32>] [-Context <PSObject>] [-Diagnose] [-Test] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### MoveToStart

```powershell
Rename-Many -underscore <FileSystemInfo> [-Pattern] <Array> [-Copy <Array>] [[-With] <String>] [-Start]
 [-Drop <String>] [-File] [-Directory] [-Except <String>] [-Include <String>] [-Whole <String>]
 [-Condition <ScriptBlock>] [-Top <Int32>] [-Context <PSObject>] [-Diagnose] [-Test] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### MoveToAnchor

```powershell
Rename-Many -underscore <FileSystemInfo> [-Pattern] <Array> [-Anchor] <Array> [-Relation <String>]
 [-Copy <Array>] [[-With] <String>] [-Drop <String>] [-File] [-Directory] [-Except <String>]
 [-Include <String>] [-Whole <String>] [-Condition <ScriptBlock>] [-Top <Int32>] [-Context <PSObject>]
 [-Diagnose] [-Test] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### HybridEnd

```powershell
Rename-Many -underscore <FileSystemInfo> [-Pattern] <Array> [-AnchorEnd] <Array> [-Relation <String>]
 [-Copy <Array>] [[-With] <String>] [-Drop <String>] [-File] [-Directory] [-Except <String>]
 [-Include <String>] [-Whole <String>] [-Condition <ScriptBlock>] [-Top <Int32>] [-Context <PSObject>]
 [-Diagnose] [-Test] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### HybridStart

```powershell
Rename-Many -underscore <FileSystemInfo> [-Pattern] <Array> [-AnchorStart] <Array> [-Relation <String>]
 [-Copy <Array>] [[-With] <String>] [-Drop <String>] [-File] [-Directory] [-Except <String>]
 [-Include <String>] [-Whole <String>] [-Condition <ScriptBlock>] [-Top <Int32>] [-Context <PSObject>]
 [-Diagnose] [-Test] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Affix

```powershell
Rename-Many -underscore <FileSystemInfo> [-Copy <Array>] -Append <String> [-File] [-Directory]
 [-Except <String>] [-Include <String>] [-Whole <String>] [-Condition <ScriptBlock>] [-Top <Int32>]
 [-Context <PSObject>] [-Diagnose] [-Test] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Prefix

```powershell
Rename-Many -underscore <FileSystemInfo> [-Copy <Array>] -Prepend <String> [-File] [-Directory]
 [-Except <String>] [-Include <String>] [-Whole <String>] [-Condition <ScriptBlock>] [-Top <Int32>]
 [-Context <PSObject>] [-Diagnose] [-Test] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NoReplacement

```powershell
Rename-Many -underscore <FileSystemInfo> -Cut <Array> [-File] [-Directory] [-Except <String>]
 [-Include <String>] [-Whole <String>] [-Condition <ScriptBlock>] [-Top <Int32>] [-Context <PSObject>]
 [-Diagnose] [-Test] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

The user should assemble the candidate items from the file system, be they files or
directories typically using Get-ChildItem, or can be any other function that delivers
file systems items via the PowerShell pipeline. For each item in the pipeline,
Rename-Many will perform a rename.

Rename-Many is a powerful command and should be used with caution. Because of the
potential of accidental misuse, a number of protections have been put in place:

* By default, the command is locked. This means that the command will not actually
perform any renames until it has been unlocked by the user. When locked, the command
runs as though -WhatIf has been specified. There are indications in the output to show
that the command is in a locked state (there is an indicator in the batch header and
a 'Novice' indicator in the summary). To activate the command, the user needs to
set the environment variable 'BULK_REMY_LOCKED' to $false. The user should not
unlock the command until they are comfortable with how to use this command properly
and knows how to write regular expressions correctly. (See regex101.com)

* An undo script is generated by default. If the user has invoked a rename operation
by accident without specifying $WhatIf (or any other WhatIf equivalent like $Diagnose)
then the user can execute the undo script to reverse the rename operation. The user
should clearly do this immediately on recognising the error of their ways. In a panic,
the user may terminate the command via ctrl-c. In this case, a partial undo script is
still generated and should contain the undo operations for the renames that were
performed up to the point of the termination request.
  The name of the undo script is based upon the current date and time and is displayed
in the summary. (The user can, if they wish disable the undo feature if they don't want
to have to manage the accumulation of undo scripts, by setting the environment variable
BULK_REMY_UNDO_DISABLED to $true)

Another important point of note is that there are currently 3 modes of operation:
'move', 'update' or 'cut':

* 'move': requires an anchor, which may be an $Anchor pattern or either $Start or $End switches.
* 'update': requires $With or $Paste without an anchor.
* 'cut': no anchor or $With/$Paste specified, the $Pattern match is simply removed
  from the name.

The following regular expression parameters:

* $Pattern
* $Anchor
* $Copy
can optionally have an occurrence value specified that can be used to select which
match is active. In the case where a provided expression has multiple matches, the
occurrence value can be used to single out which one. When no occurrence is specified,
the default is the first match only. The occurrence for a parameter can be:

* f: first occurrence
* l: last occurrence
* \<number\>: the nth occurrence
The occurrence is specified after the regular expression eg:
-Pattern '\w\d{2,3}', l
  which means match the Last occurrence of the expression.
(Actually, an occurrence may be specified for $Include and $Except but there is no
point in doing so because these patterns only provide a filtering function and play
no part in the actual renaming process).

  A note about escaping. If a pattern needs to use an regular expression character as
a literal, it must be escaped. There are multiple ways of doing this:
* use the 'esc' function; eg: -Pattern $($esc('(\d{2})'))
* use a leading ~; -Pattern '~(123)'

The above 2 approaches escape the entire string. The second approach is more concise
and avoids the necessary use of extra brackets and $.

* use 'esc' alongside other string concatenation:
  eg: -Pattern $($esc('(123)') + '-(?<ccy>GBP|SEK)').
This third method is required when the whole pattern should not be subjected to
escaping.

## EXAMPLES

### EXAMPLE 1 (Move)

```powershell
gci ... | Rename-Many -File -Pattern 'data' -Anchor 'loopz' -Relation 'before'
```

Move a static string before anchor (consider file items only)

### EXAMPLE 2 (Move)

```powershell
gci ... | Rename-Many -Pattern 'data',l -Anchor 'loopz' -Relation 'before' -Whole p
```

Move last occurrence of whole-word static string before anchor

### EXAMPLE 3 (Move)

```powershell
gci ... | Rename-Many -Directory -Pattern 'data' -Anchor 'loopz' -Relation 'before' -Drop '-'
```

Move a static string before anchor and drop (consider Directory items only)

### EXAMPLE 4 (Move)

```powershell
gci ... | Rename-Many -Directory -Pattern 'data' -AnchorEnd 'loopz' -Relation 'before' -Drop '-'
```

Move a static string before anchor and drop (consider Directory items only), if anchor
does not match, move the pattern match to end.

### EXAMPLE 5 (Move)

```powershell
gci ... | Rename-Many -Directory -Pattern 'data' -Start -Drop '-'
```

Move a static string to start and drop (consider Directory items only)

### EXAMPLE 6 (Move)

```powershell
gci ... | Rename-Many -Pattern '\d{2}-data' -Anchor 'loopz' -Relation 'before'
```

Move a match before anchor

### EXAMPLE 7 (Move)

```powershell
gci ... | Rename-Many -Pattern '\d{2}-data',l -Anchor 'loopz' -Relation 'before' -Whole p
```

Move last occurrence of whole-word static string before anchor.

### EXAMPLE 8 (Move)

```powershell
gci ... | Rename-Many -Pattern '\d{2}-data' -Anchor 'loopz' -Relation 'before' -Drop '-'
```

Move a match before anchor and drop

### EXAMPLE 9 (Update)

```powershell
gci ... | Rename-Many -Pattern 'data',l -Whole p -Paste '_info_'
```

Update last occurrence of whole-word static string using $Paste.

### EXAMPLE 10 (Update)

```powershell
gci ... | Rename-Many -Pattern 'data' -Paste '_info_'
```

Update a static string using $Paste

### EXAMPLE 11 (Update)

```powershell
gci ... | Rename-Many -Pattern '\d{2}-data', l -Paste '${_a}_info_'
```

Update 2nd occurrence of whole-word match using $Paste and preserve anchor

### EXAMPLE 12 (Update)

```powershell
gci ... | Rename-Many -Pattern (?<day>\d{2})-(?<mon>\d{2})-(?<year>\d{2})
  -Paste '(${year})-(${mon})-(${day}) ${_a}'
```

Update match contain named capture group using $Paste and preserve the anchor

### EXAMPLE 13 (Update)

```powershell
gci ... | Rename-Many -Pattern (?<day>\d{2})-(?<mon>\d{2})-(?<year>\d{2})
  -Copy '[A-Z]{3}',l -Whole c -Paste 'CCY_${_c} (${year})-(${mon})-(${day}) ${_a}'
```

Update match contain named capture group using $Paste and preserve the anchor and copy
whole last occurrence

### EXAMPLE 14 (Cut)

```powershell
gci ... | Rename-Many -Cut 'data'
```

Cut a literal token

### EXAMPLE 15 (Cut)

```powershell
gci ... | Rename-Many -Cut, l 'data'
```

Cut last occurrence of literal token

### EXAMPLE 16 (Cut)

```powershell
gci ... | Rename-Many -Cut, 2 '\d{2}'
```

Cut the second 2 digit sequence

### EXAMPLE 17 (Prepend)

```powershell
gci ... | Rename-Many -Prepend 'begin_'
```

Prefix items with fixed token

### EXAMPLE 18 (Append)

```powershell
gci ... | Rename-Many -Append '_end'
```

Append fixed token to items

## PARAMETERS

### -Anchor

Indicates that the rename operation will be a move of the token from its original point to the point indicated by Anchor. Anchor is a regular expression string applied to the pipeline item's name (after the $Pattern match has been removed). The $Pattern match that is removed is inserted at the position indicated by the anchor match in collaboration with the $Relation parameter.

```yaml
Type: Array
Parameter Sets: MoveToAnchor
Aliases: a

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AnchorEnd

Similar to Anchor except that if the pattern specified by AnchorEnd does not match, then
the Pattern match will be moved to the End. This is known as a Hybrid Anchor.

```yaml
Type: Array
Parameter Sets: HybridEnd
Aliases: ae

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AnchorStart

Similar to Anchor except that if the pattern specified by AnchorEnd does not match, then
the Pattern match will be moved to the Start. This is known as a Hybrid Anchor.

```yaml
Type: Array
Parameter Sets: HybridStart
Aliases: as

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Append

Appends a literal string to end of items name

```yaml
Type: String
Parameter Sets: Affix
Aliases: ap

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Condition

Provides another way of filtering pipeline items. This is not typically specified on the
command line, rather it is meant for those wanting to build functionality on top of Rename-Many.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Context

Provides another way of customising Rename-Many. This is not typically specified on the
command line, rather it is meant for those wanting to build functionality on top of Rename-Many.
$Context should be a PSCustomObject with the following note properties:

* Title (default: 'Rename') the name used in the batch header.
* ItemMessage (default: 'Rename Item') the operation name used for each renamed item.
* SummaryMessage (default: 'Rename Summary') the name used in the batch summary.
* Locked (default: 'BULK_REMY_LOCKED) the name of the environment variable which controls
the locking of the command.
* DisabledEnVar (default: 'BULK_REMY_UNDO_DISABLED') the name of the environment variable
which controls if the undo script feature is disabled.
* UndoDisabledEnVar (default: 'BULK_REMY_UNDO_DISABLED') the name of the environment
variable which determines if the Undo feature is disabled. This allows any other function
built on top of Rename-Many to control the undo feature for itself independently of
Rename-Many.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Copy

Regular expression string applied to the pipeline item's name (after the $Pattern match
has been removed), indicating a portion which should be copied and re-inserted (via the
$Paste parameter; see $Paste or $With). Since this is a regular expression to be used in
$Paste/$With, there is no value in the user specifying a static pattern, because that
static string can just be defined in $Paste/$With. The value in the $Copy parameter comes
when a generic pattern is defined eg \d{3} (is non Literal), specifies any 3 digits as
opposed to say '123', which could be used directly in the $Paste/$With parameter without
the need for $Copy. The match defined by $Copy is stored in special variable ${_c} and
can be referenced as such from $Paste and $With.

```yaml
Type: Array
Parameter Sets: UpdateInPlace, MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart, Affix, Prefix
Aliases: co

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Cut

Is a replacement for the Pattern parameter, when a Cut operation is required. The matched
items will be removed from the item's name, and no other replacement occurs.

```yaml
Type: Array
Parameter Sets: NoReplacement
Aliases:

Required: True
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
Aliases: dg

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Directory

switch to indicate only Directory items in the pipeline will be processed. If neither
this switch or the File switch are specified, then both File and Directory items
are processed.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: d

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Drop

A string parameter (only applicable to move operations, ie Anchor/Star/End/hybrid) that
defines what text is used to replace the Pattern match. So in this use-case, the user wants
to move a particular token/pattern to another part of the name and at the same time drop a
static string in the place where the $Pattern was removed from.

```yaml
Type: String
Parameter Sets: MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
Aliases: dr

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
Parameter Sets: MoveToEnd
Aliases: e

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Except

Regular expression string applied to the original pipeline item's name (before the $Pattern
match has been removed). Allows the user to exclude some items that have been fed in via the
pipeline. Those items that match the exclusion are skipped during the rename batch.

```yaml
Type: String
Parameter Sets: (All)
Aliases: x

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -File

switch to indicate only File items in the pipeline will be processed. If neither
this switch or the Directory switch are specified, then both File and Directory items
are processed.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: f

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Include

Regular expression string applied to the original pipeline item's name (before the $Pattern
match has been removed). Allows the user to include some items that have been fed in via the
pipeline. Only those items that match $Include pattern are included during the rename batch,
the others are skipped. The value of the Include parameter comes when you want to define
a pattern which pipeline items match, without it be removed from the original name, which is
what happens with $Pattern. Eg, the user may want to specify the only items that should be
considered a candidate to be renamed are those that match a particular pattern but doing so
in $Pattern would simply remove that pattern. That may be ok, but if it's not, the user should
specify a pattern in the $Include and use $Pattern for the match you do want to be moved
(with Anchor/Start/End) or replaced (with $With/$Paste).

```yaml
Type: String
Parameter Sets: (All)
Aliases: i

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Paste

Formatter parameter for Update operations. Can contain named/numbered group references
defined inside regular expression parameters, or use special named references $0 for the whole
Pattern match and ${_c} for the whole Copy match.

```yaml
Type: String
Parameter Sets: UpdateInPlace
Aliases: ps

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pattern

Regular expression string that indicates which part of the pipeline items' name that
either needs to be moved or replaced as part of bulk rename operation. Those characters
in the name which match are removed from the name.

The pattern can be followed by an occurrence indicator. As the $Pattern parameter is
strictly speaking an array, the user can specify the occurrence after the regular
expression eg:

  $Pattern '(?<code>\w\d{2})', l

  => This indicates that the last match should be captured into named group 'code'.

```yaml
Type: Array
Parameter Sets: UpdateInPlace, Transformer, MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
Aliases: p

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Prepend

Prefixes a literal string to start of items name

```yaml
Type: String
Parameter Sets: Prefix
Aliases: pr

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Relation

Used in conjunction with the $Anchor parameter and can be set to either 'before' or
'after' (the default). Defines the relationship of the $pattern match with the $Anchor
match in the new name for the pipeline item.

```yaml
Type: String
Parameter Sets: MoveToAnchor, HybridEnd, HybridStart
Aliases: r
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
Parameter Sets: MoveToStart
Aliases: s

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Test

Required for unit tests only.

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

### -Top

A number indicating how many items to process. If it is known that the number of items
that will be candidates to be renamed is large, the user can limit this to the first $Top
number of items. This is typically used as an exploratory tool, to determine the effects
of the rename operation.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: t

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Transform

A script block which is given the chance to perform a modification to the finally named
item. The transform is invoked prior to post-processing, so that the post-processing rules
are not breached and the transform does not have to worry about breaking them. The transform
function's signature is as follows:

* Original: original item's name
* Renamed: new name
* CapturedPattern: pattern capture

and should return the new name. If the transform does not change the name, it should return
an empty string.

```yaml
Type: ScriptBlock
Parameter Sets: Transformer
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Whole

 Provides an alternative way to indicate that the regular expression parameters
should be treated as a whole word (it just wraps the expression inside \b tokens).
If set to '*', then it applies to all expression parameters otherwise a single letter
can specify which of the parameters 'Whole' should be applied to. Valid values are:

* 'p': $Pattern
* 'a': $Anchor/AnchorEnd/AnchorStart
* 'c': $Copy
* 'i': $Include
* 'x': $Except
* '*': All the above
(NB: Currently, can't be set to more than 1 of the above items at a time)

```yaml
Type: String
Parameter Sets: (All)
Aliases: wh
Accepted values: p, a, c, i, x, u, *

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -With

This is a NON regular expression string.
It would be more accurately described as a formatter, similar to the $Paste parameter.
Defines what text is used as the replacement for the $Pattern match.
Works in concert with $Relation (whereas $Paste does not).
$With can reference special variables:

* $0: the pattern match
* ${_a}: the anchor match
* ${_c}: the copy match

When $Pattern contains named capture groups, these variables can also be referenced.
Eg if the $Pattern is defined as '(?\<day\>\d{1,2})-(?\<mon\>\d{1,2})-(?\<year\>\d{4})', then the variables ${day}, ${mon} and ${year} also become available for use in $With or $Paste.
Typically, $With is static text which is used to replace the $Pattern match and is inserted according to the Anchor match, (or indeed $Start or $End) and $Relation.
When using $With, whatever is defined in the $Anchor match is not removed from the pipeline's name (this is different to how $Paste works).

```yaml
Type: String
Parameter Sets: UpdateInPlace, MoveToEnd, MoveToStart, MoveToAnchor, HybridEnd, HybridStart
Aliases: w

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -underscore

The pipeline item which should either be an instance of FileInfo or DirectoryInfo.

```yaml
Type: FileSystemInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.FileSystemInfo

Parameter `$underscore`, can be DirectoryInfo instance or FileInfo instance.

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS

[Elizium.Bulk](https://github.com/EliziumNet/Bulk)
