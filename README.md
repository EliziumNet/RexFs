# :shield: Elizium.Bulk

___Bulk operations module with Bulk File/Directory renamer powered by [:nazar_amulet: Elizium.Loopz](https://github.com/EliziumNet/Loopz) and colouring provided by [:rainbow: __Elizium.Krayola__](https://github.com/EliziumNet/Krayola)___

[![A B](https://img.shields.io/badge/branching-commonflow-informational?style=flat)](https://commonflow.org)
[![A B](https://img.shields.io/badge/merge-rebase-informational?style=flat)](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)
[![A B](https://img.shields.io/github/license/eliziumnet/Bulk)](https://github.com/eliziumnet/Bulk/blob/master/LICENSE)
[![A B](https://img.shields.io/powershellgallery/p/Elizium.Bulk)](https://www.powershellgallery.com/packages/Elizium.Bulk)

<!-- MarkDownLint-disable no-inline-html -->
<!-- MarkDownLint-disable no-emphasis-as-heading -->

## Table Of Contents

+ [Introduction](#Introduction)
+ [:rocket: Quick Start](#quick-start)
  + [Quick Move](#Quick-Move)
  + [Quick Update](#Quick-Update)
+ [:sparkles: General Concepts](#general.concepts)
  + [Safety features](#general.safety-features)
  + [Occurrence](#general.occurrence)
  + [Escaping](#general.escaping)
  + [Filtering](#general.filtering)
  + [Formatter Parameters](#general.formatter-parameters)
  + [General Parameters](#general.general-parameters)
  + [Post Processing](#general.post-processing)
  + [Signals](#general.signals)
  + [The Replacement Process](#general.the-replacement-process)
  + [Saved Undo Scripts](#general.saved-undo-scripts)
+ [:sparkles: Move Match](#action.move-match)
  + [Move to Anchor](#using.move-to-anchor)
  + [Move to Start](#using.move-to-start)
  + [Move to End](#using.move-to-end)
  + [Move to Hybrid Anchor](#using.move-to-hybrid-anchor)
+ [:sparkles: Update Match](#action.update-match)
+ [:sparkles: Cut Match](#action.cut-match)
+ [:sparkles: Add Appendage](#action.add-appendage)
  + [Add Prefix](#Add-Prefix)
  + [Add Suffix](#Add-Suffix)
+ [:sparkles: Parameter Reference](#parameter-reference)
+ [:radioactive: Troubleshooting / Common Errors](#troubleshooting)
+ [:hammer: Expanding Rename-Many Capabilities](#expanding-rename-many)
  + [:mortar_board: Higher Order Commands](#higher-order-commands)
  + [:robot: Using Transform](#using.transform)
+ [:green_salad: Recipes](#develop.recipes)
+ [:hammer: Developer Notes](#develop.notes)

## Introduction

The module can be installed using the standard **install-module** command:

> PS> install-module -Name Elizium.Bulk

The following dependencies will be installed automatically

+ [:mortar_board: __Elizium.Klassy__](https://github.com/EliziumNet/Klassy)
+ [:rainbow: __Elizium.Krayola__](https://github.com/EliziumNet/Krayola)
+ [:nazar_amulet: __Elizium.Loopz__](https://github.com/EliziumNet/Loopz)

:high_brightness: **Rename-Many** (*remy*) is a flexible regular expression based bulk rename command. In order to get the best out of this command, the user should become familiar and skilled in writing regular expressions.

:pushpin: Note, that it is recommended that this page is read in sequential order, in particular because the first usage scenario to be explained: [Move Match](#action.move-match), includes more screen snapshots and examples to help explain the concepts, which is not repeated to the same detail in subsequent usage scenarios.
See also the [Parameter Reference](#parameter-reference), for a more detailed explanation of each parameter and
[Safety Features](#general.safety-features) to see how to *Unlock* the command so it becomes effective.

There are multiple modes of operation that *Rename-Many* runs in, which are *Update*/*Move*/*Cut*/*Appendage*. On top of this, a developer can extend its capabilities by providing a custom [*Transform*](using.transform) and/or build [*Higher Order Commands*](#higher-order-commands).

| Mode                                   | DESCRIPTION
|----------------------------------------|---------------------------------------------
| [Move Match](#action.move-match)       | Move a regular expression match to an anchor
| [Update Match](#action.update-match)   | Replace a regular expression match
| [Cut Match](#action.cut-match)         | Remove a regular expression match
| [Add Appendage](#action.add-appendage) | Add a fixed token to Start or End of item
| [Transform](#using.transform)          | Apply a custom transform to perform rename

## :rocket: Quick Start<a name="quick-start"></a>

*Rename-Many works* by receiving it's input from the pipeline and renaming these file system items according to parameters specified. The benefit of using this command comes when there is a need to rename multiple items according to the same criteria. This criteria amounts to specifying regular expressions. The 2 most commonly used scenarios are:

+ [move](#action.move-match) a token from 1 point to another
+ [update](#action.update-match) a token in the location that it already resides

### Quick Move

Moves a regex match to another point, known as an anchor.

Let's say we have a directory containing a collection of log files, some of which are not named according to a fixed form eg they contain a date which is not at the end of the file name. We can bulk rename the rogue files with a command like:

> gci ./*.log | Rename-Many -Pattern '(?\<d>\d{2})-(?\<m>\d{2})-(?\<y>\d{4})' -End -WhatIf

Note the following:

+ :pushpin: we assemble the source file system items with the gci (Get-ChildItems) command and pipe to Rename-Many
+ :pushpin: we define a pattern (_-Pattern_), in this case a regex to recognise a date of the form 'dd-mm-yyyy' using named group captures (__d__, __m__ and __y__), which can be referenced via the formatter parameters (___With___/___Paste___)
+ :pushpin: we want to move the date to the end so we specify ___-End___ (this is an anchor)
+ :pushpin: since we haven't run our command before, we need to run safely first so specify the ___WhatIf___ flag. (Remember, if the command has never been run, then it will be in a locked state, so even if we omitted ___WhatIf___, the command would still run in a ___WhatIf___ context, see [Safety Features](#general.safety-features))

Extending this example a little further, let's say we also want to reformat the date so it's in ISO format (yyyy-mm-dd). We can achieve this by specifying the formatter parameter ___-With___ (___With___ is used for move operations, whereas ___Paste___ is used for update operations) as illustrated below:

> ... | remy -Pattern '(?\<d>\d{2})-(?\<m>\d{2})-(?\<y>\d{4})' -End -With '\${y}-\${m}-\${d}' -WhatIf

+ :pushpin:  _remy_ is defined as an alias of _Rename-Many_

In practice, there are a few more subtleties that need to be accounted for when performing bulk renames and the reader will discover this when reading the rest of this documentation. One such nuance is that moving the date like this may require the insertion of additional content to get the graceful result we require, eg wrap the date in brackets, or insert a dash before the date etc.

### Quick Update

Replace a regex match in it's present location with alternative content.

Continuing with our log files theme, let's say we just want to adjust the date format. So any date that appears as 'dd-mm-yyyy' we would like to adjust it to ISO format 'yyyy-mm-dd' instead. We can do this using the [*update*](#action.update-match) mode of _Rename-Many_:

> ... | remy -Pattern '(?\<d>\d{2})-(?\<m>\d{2})-(?\<y>\d{4})' -Paste '\${y}-\${m}-\${d}'

+ :pushpin: update operations do not require an anchor (___-End___/___-Start___/___-Anchor___)
+ :pushpin: the ___-Paste___ value is exactly the same as we performed in our move operation previously. This is because ___With___ and ___Paste___ do this same thing but are used in different contexts
+ :pushpin: the date is adjusted in its current location, not moved

Hopefully, the above examples have given a quick insight in the operation of the command, enough to get started with. Also note, to begin with, you can initially stick to using static patterns instead of more complex regex sequences for the more simple rename operations, eg rename the presence of the word 'CCY' to 'Currency', by using a pattern of 'CCY' and ___-With___/___-Paste___ of 'Currency'.

## :sparkles: General Concepts<a name="general.concepts"></a>

### :gem: Safety features<a name="general.safety-features"></a>

*Rename-Many* is a powerful command and should be used with caution. Because of the
potential of accidental misuse, a number of protections have been put in place:

+ By default, the command is locked. This means that the command will not actually
perform any renames until it has been unlocked by the user. When locked, the command
runs as though ___$WhatIf___ has been specified. There are indications in the output to show
that the command is in a locked state (there is an indicator in the batch header and
a 'Novice' indicator in the summary). To activate the command, the user needs to
set the environment variable 'BULK_REMY_LOCKED' to $false; ie ($env:BULK_REMY_LOCKED = $false, either temporarily in the session, or permanently in the powershell profile, see $Profile). The user should not
unlock the command until they are comfortable with how to use this command properly
and knows how to write regular expressions correctly. (See [regex101](regex101.com))

+ An undo script is generated by default. If the user has invoked a rename operation
by accident without specifying ___$WhatIf___ (or any other ___$WhatIf___ equivalent like ___$Diagnose___)
then the user can execute the undo script to reverse the rename operation. The user
should clearly do this immediately on recognising the error of their ways. In a panic,
the user may terminate the command via ctrl-c. In this case, a partial undo script is
still generated and should contain the undo operations for the renames that were
performed up to the point of the termination request.
The name of the undo script is based upon the current date and time and is displayed
in the summary. (The user can, if they wish disable the undo feature if they don't want
to have to manage the accumulation of undo scripts, by setting the environment variable
*BULK_REMY_UNDO_DISABLED* to $true.)

### :gem: Occurrence<a name="general.occurrence"></a>

All regular expression parameters as listed below ...

| Regex Parameter                           | Alias | DESCRIPTION
|-------------------------------------------|-------|------------------------------------------------------------------
| [Anchor](#parameter-ref.anchor)           | a     | Move a match to an anchor
| [AnchorEnd](#parameter-ref.anchorend)     | ae    | Move a match to an anchor or to end if anchor fails match
| [AnchorStart](#parameter-ref.anchorstart) | as    | Move a match to an anchor or to start if anchor fails match
| [Copy](#parameter-ref.copy)               | co    | Make a copy of this match for formatter reference
| [Cut](#parameter-ref.cut)                 | :heavy_multiplication_x:      | Remove this match without a replacement
| [Except](#parameter-ref.except)           | x     | Filter out items that match
| [Include](#parameter-ref.include)         | i     | Filter in items that match
| [Pattern](#parameter-ref.pattern)         | w     | Replace or Move this match

... are all declared as arrays. This allows the user to augment the regular expression with an additional value denoting which match occurrence is in effect. This value can be either numeric which denotes which match to select or 'f' for the first match or 'l' indicating the last match. The exception to the use of the *Occurrence* value is with ___$Include___/___$Except___, which are filtering parameters (see [Filtering](#general.filtering)). Since they are used for filtering, the *Occurrence* value is irrelevant, so should not be supplied.

So for example the ___$Pattern___ can be specified as:

> Rename-Many -Pattern 'foo', 2 ...

This means that the second occurrence of the match 'foo' should be taken as the token match for each item being renamed.

### :gem: Escaping<a name="general.escaping"></a>

If a regex parameter needs to use a regular expression character as
a literal, it must be escaped. There are multiple ways of doing this:

+ use the 'esc' function (alias for *Format-Escape*); eg: -Pattern $($esc('(123)'))
+ use a leading ~ inside the regex parameter; eg: -Pattern '~(123)'

The above 2 approaches escape the entire string. The second approach is more concise
and avoids the necessary use of extra brackets and $.

+ use 'esc' alongside other string concatenation:
  eg: -Pattern $($esc('(123)') + '-(?\<ccy>GBP|SEK)').

This third method is required when the whole pattern should not be subjected to
escaping.

### :gem: Filtering<a name="general.filtering"></a>

Generally, the user must indicate which items are to be renamed using the pipeline. Any command can be used to select file system items (directories or files), but typically *Get-ChildItem* would be used and the result then piped to Rename-Many. *Get-ChildItem* contains a *Filter* parameter but this can only filter as a blob using wildcards where appropriate, but can not filter by a regular expression. The user could use an extra pipeline stage using Where-Object eg:

> Get-ChildItem -LiteralPath ./ -File -Filter '*.log' | Where-Object { $_.Name -match 'bar' } | Rename-Many ...

However, this command is starting to get quite long. So instead, Rename-Many contains regex filters via the ___$Include___/___$Except___ parameters:

> Get-ChildItem -LiteralPath ./ -File -Filter '*.log' | Rename-Many -Include 'bar' ...

and similarly for ___$Except___.

Any items filtered out 'inband' (by the filter parameters on *Rename-Many* as opposed to 'out of band' filtering applied to the previous stage of the pipeline, eg the filter parameter on Get-ChildItem), will be counted as a 'Skipped' item in the Summary displayed at the end of the rename batch.

### :gem: Formatter Parameters<a name="general.formatter-parameters"></a>

The following parameters are known as *formatters*. This means that they are strings which contain the replacement text for the match. The formatter can also reference named (or numbered) group references defined in the non-filtering regex parameters:

| Formatter Parameter           | Alias | DESCRIPTION
|-------------------------------|-------|------------------------------------------------------------------
| [With](#parameter-ref.with)   | w     | used when performing *Move*
| [Paste](#parameter-ref.paste) | ps    | used when performing in place *Update*

So given the following as an example (not all parameters have been defined so do not take this as a literal example)

> ... | Rename-Many -Pattern '(?\<y\>\d{4})-(?\<m\>\d{2})-(?\<d\>\d{2})' -With '\${d}-\${m}-${y}'

we can see that inside the ___$With___ formatter, there are references to named group captures ('d', 'm', 'y') that are defined inside the ___$Pattern___ regex.

### :gem: General Parameters<a name="general.parameters"></a>

The following parameters belong to all *Rename-Many* parameter sets:

(The parameters marked as *Interactive* are those which are meant to be used interactively. The other parameters are intended for use by developers needing to expand the renaming possibilities of the command.)

| General Parameter                     | Alias | Interactive (non Developer)  | DESCRIPTION
|---------------------------------------|-------|------------------------------|-----------------------------------
| [Condition](#parameter-ref.condition) | :heavy_multiplication_x:      | :x:                          | A custom predicate script-block that filters pipeline items
| [Context](#parameter-ref.context)     | :heavy_multiplication_x:      | :x:                          | A PSCustomObject with options to customise Rename-Many
| [Directory](#parameter-ref.directory) | d     | :heavy_check_mark:           | Filter for Directory items only
| [Diagnose](#parameter-ref.diagnose)   | dg    | :heavy_check_mark:           | WhatIf mode with added diagnostic info
| [End](#parameter-ref.end)             | e     | :heavy_check_mark:           | Move Pattern
| [Except](#parameter-ref.except)       | x     | :heavy_check_mark:           | Filter out items that match this regex
| [File](#parameter-ref.file)           | f     | :heavy_check_mark:           | Filter for File items only
| [Include](#parameter-ref.include)     | i     | :heavy_check_mark:           | Filter out items that do not match this regex
| [Start](#parameter-ref.start)         | s     | :heavy_check_mark:           | Move matched Pattern to start of items name
| [Top](#parameter-ref.top)             | t     | :heavy_check_mark:           | Process the first n items only
| [Transform](#parameter-ref.transform) | :heavy_multiplication_x:      | :x:                          | A script-block to perform custom rename operation
| [Whole](#parameter-ref.whole)         | :heavy_multiplication_x:      | :heavy_check_mark:           | Applies 'whole word' match to regex parameters

### :gem: Post Processing<a name="general.post-processing"></a>

During the renaming process, an item maybe renamed resulting in unfavourable characteristics in the resultant file/directory name. Eg, it is not wise to leave a file name with trailing or leading spaces. The following are the characteristics that are automatically fixed by a post processing operation:

+ Leading/Trailing spaces (*Trim*)
+ Multiple consecutive spaces (*Spaces*)
+ Unresolved named capture groups (*MissingCapture*)

For *Trim* and *Spaces*, the post processing simply involves removal of the unwanted spaces. For *MissingCapture* this process involves the removal of any string of the form:

> ${some-variable}

which occurs as a result of a named group reference defined in a formatter parameter (___$With___/___$Paste___) not being populated as a result of applying a regex parameter to the item and it not matching. An example of this occurring is with the use of a [Hybrid Anchor](#using.move-to-hybrid-anchor) (___$AnchorStart___/___$AnchorEnd___), where the user specifies a pattern that includes a named group capture, but for some items, this match may fail (so by design, the match would fall back to being moved to start or end), but the formatter parameter ___$With___ contains a reference to that named capture group. When this match fails, the reference '${some-variable}' still remains, which is removed by the post processing operation.

These post-processing operations are made explicit in the ui because **sometimes** they occur as a result of
a mal-formed regular expression that can be automatically fixed, but doing so may lure the user into thinking they're specifying the regex pattern correctly when in fact a minor correctable mistake has been made. It is best to be explicit about such issues rather than fix them silently.

The following shows an example of the *MissingCapture* operation being applied and how it shows up in the output:

![picture](resources/images/bulk-rename.POST-PROC-EX.jpg)

### :gem: Signals<a name="general.signals"></a>

As the saying goes, 'a picture is worth a thousand words'. This is particularly cogent when eye-balling a stream of repetitive content generated as a result of an iterative operation such as the result of *Rename-Many*. Viewing and trying to process a wall of mono-coloured un-structured content can be difficult. This was the rationale behind the use of emojis (generalised into the concept of a *Signal* in commands, see [Loopz](https://github.com/EliziumNet/Loopz)) and of another Elizium PowerShell module [Krayola](https://github.com/EliziumNet/Krayola). The combination of coloured, consistently structured text with the use of emoji based signals is intended to aid human readability of repetitive content.

### :gem: The Replacement Process<a name="general.the-replacement-process"></a>

For those parameter sets that require the ___$Pattern___ parameter (which is most of them; *NoReplacement* which uses the ___$Cut___ parameter does not), the content that is matched by the Pattern, is removed prior to applying other regex parameters.

It is useful for the user to think about this when composing regex patterns. So for example, given the following input source:

> 01-From-My-Mind-To-Yours

... a ___$Pattern___ defined as:

> '\d{2}-'

results in first, the removal of the ___$Pattern___ match leaving this behind:

> From-My-Mind-To-Yours

It is to this remainder that all other regex parameters are applied.

### :gem: Saved Undo Scripts<a name="general.saved-undo-scripts"></a>

The undo facility enables a rename batch to be reversed. The location of the scripts is displayed in the rename summary. By default, scripts are saved to '.elizium' under the home (___$Home___) directory, but this can be overridden.

To change this path, the user should define either an absolute or relative path in the environment variable '*LOOPZ_PATH*'. Relative paths are relative to the $Home directory.

## :sparkles: Move Match<a name="action.move-match"></a>

| Move Parameter                            | Alias | DESCRIPTION
|-------------------------------------------|-------|-------------------------------------
| [Anchor](#parameter-ref.anchor)           | a     | Move a match to an anchor
| [AnchorEnd](#parameter-ref.anchorend)     | ae    | Move a match to an anchor or to end if anchor fails match
| [AnchorStart](#parameter-ref.anchorstart) | as    | Move a match to an anchor or to start if anchor fails match
| [End](#parameter-ref.end)                 | e     | Move match to end
| [Start](#parameter-ref.start)             | s     | Move match to start
| [With](#parameter-ref.anchor)             | w     | Formatter used when performing *Move*

Moves a match from it's current location in an item to a target location known as the [___$Anchor___](#parameter-ref.anchor). The anchor itself is a regular expression. All of the parameters in this section,  with the exception of ___$With___ are mutually exclusive (to see confirmation of this, the user can use the [Parameter Set Tools](https://github.com/EliziumNet/Loopz/blob/master/resources/docs/parameter-set-tools.md) in particular the command [Show-ParameterSetInfo (ships)](https://github.com/EliziumNet/Loopz/blob/master/resources/docs/parameter-set-tools.md/using.show-parameter-set-info), which reveals that they are indeed the unique parameters in their respective parameter sets).

In the following walk-throughs, example invocations are preceded with a :heavy_minus_sign: to indicate a solution that has some scope for improvement. Subsequent to this will be further discussion on how to improve the command and those which are deemed satisfactory are marked with :heavy_plus_sign:. Sometimes, a command does not work in the desired way. These examples are highlighted by a :x:.

### :gem: Move to Anchor<a name="using.move-to-anchor"></a>

Move a regex match identified by ___$Pattern___ from the items' name from its current location to a location specified by the ___$Anchor___ regex pattern.

Let's say we have a bunch of audio files which are currently named in the form:

> \'<DISC-NO\>-\<TRACK-NO\>\_\<TRACK-NAME\>.mp3'

(the underscore used in all examples are meant to represent a single space)

... and we wish to move the *DISC-NO* to after the *TRACK-NO*. In this case, the *DISC-NO* would be the subject of the ___$Pattern___ match and the *TRACK-NO* would be the ___$Anchor___.

So an initial attempt of the command could be:

:heavy_minus_sign: Rename-Many -Pattern '\d{2}' -Anchor '\d{2}' -WhatIf

> gci ... | Rename-Many -Pattern '\d{2}' -Anchor '\d{2}' -WhatIf

:pushpin: At the end of this section a final version of the command will be illustrated, but we will get there in small steps, so that little nuances can be explained fully.

Focusing on a single file item in the batch being: '**02-09 Radio Stars.mp3**':

+ **02** represents the *DISK-NO*
+ **09** represents the *TRACK-NO*
+ **Radio Stars** represents the *TRACK-NAME*

:heavy_minus_sign: Rename-Many -Pattern '\d{2}' -Anchor '\d{2}' -WhatIf

> -0902 Radio Stars.mp3

Although the order of the *DISC-NO* and *TRACK-NO* have been swapped around, this is almost certainly not what we would want. We need to maintain the dash in between them. We can't include the dash inside the ___$Pattern___ because that would just result in '0902-'. This is where the ___$With___ formatter parameter and ___$Relation___ comes into play. We can format the replacement text:

:heavy_minus_sign: Rename-Many -Pattern '\d{2}' -Anchor '\d{2}' -With '\${_a}-$0' -WhatIf

> -09-02 Radio Stars.mp3

This is starting to get better, but there is still a problem. We now have a stray leading dash, but before discussing that issue, the contents of the [___$With___](#parameter-ref.with) parameter needs explaining. Formatter parameters can access whole regex captures defined by other parameters and/or named/numeric capture groups defined within them. So in this example '$0' represents the whole [___$Pattern___](#parameter-ref.pattern) match which evaluates to '02' and ${_a} represents the whole [___$Anchor___](#parameter-ref.anchor) match which evaluates to '09'.

So back to the issue at hand, being the leading stray '-'. We could solve this 1 of 2 ways

+ 1️⃣ capture the dash inside the ___$Pattern___, but also inside the ___$Pattern___, the characters that we really want to preserve now need to be inserted into a named capture group, so that they can be individually addressed without the whole *Pattern match*. Inside ___$With___, we replace '\$0', with the named capture group 'disc', referenced as '${disc}':

:radio_button: -Pattern '(?\<disc\>\d{2})-' -Anchor '\d{2}' -With '\${_a}-${disc}' -WhatIf

> 09-02 Radio Stars.mp3

+ 2️⃣ capture the dash inside the ___$Anchor___ and use the same technique for 1️⃣ above. This time, inside ___$With___, we replace \${_a}, with the named capture group 'track', referenced as '${track}':

:radio_button: -Pattern '\d{2}' -Anchor '-(?\<track\>\d{2})' -With '${track}-\$0' -WhatIf

> 09-02 Radio Stars.mp3

Finally, we might decide that the \<TRACK-NO\>-\<DISC-NO\> sequence needs to be more clearly separated from the \<TRACK-NAME\>, so an extra ' - ' is inserted into ___$With___, let's say using technique 1️⃣ above (but equally applies to 2️⃣):

:heavy_plus_sign: Rename-Many -Pattern '(?\<disc>\d{2})-' -Anchor '\d{2}' -With '\${_a}-${disc} - ' -WhatIf

> 09-02 - Radio Stars.mp3

Now that we have our somewhat finalised version, lets see how this looks in a batch:

(actually, the screen shot below uses the [Top](#parameter-ref.top) parameter to reduce the number of items processed, for brevity)

![picture](resources/images/bulk-rename.MOVE-TO-ANCHOR-FINAL.with-post-SPACES.jpg)

It can be seen that for each item renamed, the new name is displayed in red, with the original name displayed in white. Next to the new name, supplementary info is displayed, including 'Post (Spaces)' (we'll come to this a little later) and a ___$WhatIf___ indicator.

At the beginning of the batch, a title is shown with the [Locked](#general.safety-features) status highlighted. At the end of the batch, the rename summary is shown, displaying the value of key parameter values and some stats.

The 'Post (Spaces)' previously mentioned, indicates we have made a slight formatting error that has been fixed automatically for us by [Post Processing](#general.post-processing). In this case we have created a ___$With___ formatter that results in consecutive spaces in the resultant rename.

So looking at our definition of ___$With___ again:

> -With '\${_a}-${disc} - '

That space at the end is our issue. There is already a space preceding the \<TRACK-NAME\> which was not captured by either ___$Pattern___ or ___$Anchor___, so we don't need to insert another. So adjusting this to be

> -With '\${_a}-${disc} -'

... without the trailing space, fixes the problem:

:heavy_plus_sign: Rename-Many -Pattern '(?\<disc\>\d{2})-' -Anchor '\d{2}' -With '\${_a}-${disc} -' -Top 10 -WhatIf

![picture](resources/images/bulk-rename.MOVE-TO-ANCHOR-FINAL.fixed-post-SPACES.jpg)

The *Post Processing* is there to watch our back by automatically enforcing desirable rules and makes the command less pedantic in its operation.

In other more complicated rename batches, we might (and probably will) encounter a scenario where the named group captures defined are not doing what we expected. In this case, we can run the command with diagnostics enabled via the [___$Diagnose___](#parameter-ref.diagnose) parameter.

For this example, when ___$Diagnose___ is specified, we can see the value of named capture groups:

![picture](resources/images/bulk-rename.MOVE-TO-ANCHOR-FINAL.fixed-with-DIAGNOSTICS.jpg)

Focusing on the first entry, item named '01-01 Autobahn.mp3', we can see the diagnostics entry:

> "[🧪] Pattern" => "([☂️] \<disc\>)='01', ([☂️] <0>)='01-'"

This tells us that ___$Pattern___ contains named group reference(s), in this case:

+ 'disc': '01'
+ '0': '01-'

This is quite a convenient and tidy example, because all the input items are of identical form, but this is not always the case. Let's assume, the first entry in this list: '01-01 Autobahn.mp3' is not named that way, instead it is '01-0 Autobahn.mp3' so the track number is now just a single digit '0'.

In this case, the ___$Pattern___ will match because there is still a 2 digit sequence, but the ___$Anchor___ will no longer match. This results in this item not being renamed and this is indicated in the output:

![picture](resources/images/bulk-rename.MOVE-TO-ANCHOR-FINAL.not-renamed-BECAUSE.jpg)

:warning: <a name = "using.formatters-must-use-single-quotes"></a> The ___$With___ format parameter MUST be defined with single quotes. Using double quotes causes string interpolation to occur resulting in named group references to not be evaluated as expected. Let's re-run the last command, but using double quotes for the ___$With___ parameter:

:x: Rename-Many -Pattern '(?\<disc\>\d{2})-' -Anchor '\d{2}' -With "\${_a}-${disc} -" -Top 10 -WhatIf

![picture](resources/images/bulk-rename.MOVE-TO-ANCHOR-FINAL.interpolated-WITH.double-quotes.jpg)

This shows that '\${_a}' and '${disc}' are both evaluated to an empty string, breaking the desired result. The same applies to the [___$Paste___](#parameter-ref.paste) format parameter.

The final point worthy of note is the 'Undo Rename' in the summary. By default, all executed commands are *undo-able* (assuming the undo feature has not been disabled). If we find that after running the command (assuming it has been unlocked and ___$WhatIf___ is not specified), the results are not as envisioned (shouldn't really happen, because the ___$WhatIf___ should always be used for new executions), the rename can be undone.

The summary contains a [path](#general.saved-undo-scripts) to an undo script under the 'Undo Rename' signal. The user can review its contents first (recommended before running any scripts on a system) and then source that file. The undo script is purely a sequence of renames in reverse with the original name and new names swapped around, thereby reversing the whole batch.

### :gem: Move to Start<a name="using.move-to-start"></a>

Move a regex match identified by ___$Pattern___ from the items' name from its current location to the start of an item's name.

Continuing with the audio files as discussed in [*Move To Anchor*](#using.move-to-anchor), let's say we want to move the \<TRACK-NO\> to the start of an item's name.

Focusing on a single file item in the batch, this time being: '**02-06 Airwaves.mp3**':

+ **02** represents the *DISK-NO*
+ **06** represents the *TRACK-NO*
+ **Airwaves** represents the *TRACK-NAME*

:heavy_minus_sign: 1️⃣ Rename-Many -Pattern '\d{2}', 2 -Start -WhatIf

> 0602- Airwaves.mp3

However, as we discovered in the [previous section](#using.move-to-anchor), we need to do more to obtain a satisfactory result. We can tidy this up, with the use of the ___$With___ parameter:

:heavy_plus_sign: Rename-Many -Pattern '-(?\<track\>\d{2})' -Start -With '${track}-' -Drop ' -' -WhatIf

> 06-02 - Airwaves.mp3

Let's explore each of the points that gets us to this result:

+ *___$Start___*: switch parameter specified, this means, move the ___$Pattern___ match to the start
+ *'-'* inside ___$Pattern___: this is required, otherwise the remaining '02' will have a '-' right next to it, when we would rather there be a space in between. So we remove it by including it in the ___$Pattern___ and then drop a ' -'
+ **track**: named capture group inside ___$Pattern___. This is now required because the ___$Pattern___ now includes a '-' which needs to be removed so it can be replaced by a ' -' via the ___$Drop___.
+ **Drop**: We use ' -' to ensure that the remaining dash is preceded by a space. Note, the ___$Drop___ parameter allows us to perform an additional operation to the prime one, which in this case is the move of a token to the start.
+ **Pattern Occurrence**: In our first attempt above (:heavy_minus_sign: 1️⃣), we used an *Occurrence* of 2, because we initially targetted the 2nd 2 digit sequence. Now that the ___$Pattern___ includes a '-', there is now no ambiguity between the two 2 digit sequences, so we can leave the *Occurrence* to default to the first.

Now that we have our finalised version, lets see how this looks in a batch:

(actually, the screen shot below uses the [Top](#parameter-ref.top) parameter to reduce the number of items processed, for brevity)

![picture](resources/images/bulk-rename.MOVE-TO-START-FINAL.fixed.jpg)

:warning: When using the ___$Start___ and ___$End___ anchors (this does not apply to [*Hybrid Anchors*](#using.move-to-hybrid-anchor)), the user should be aware that if the match is already at the target location, then it will be skipped. For example, if we had a series of directories that contained a date in its name, but the location of the date was inconsistent, we might decide we want to move the date for every directory to the end. However, some directories may already have the date at the end, so there is no point in processing these items. That is why some items may be skipped when using ___$Start___ and ___$End___ anchors.

### :gem: Move to End<a name="using.move-to-end"></a>

Move a regex match identified by ___$Pattern___ from the item's name from its current location to the end of its name.

This time, we want to move the \<DISK-NO\> to the end of the item's name. The reader might be thinking *well isn't this just the opposite to using Start?* and they would be right. But in the discussion of *Move To End* we'll address some slightly different issues/techniques that illustrate other ways the command can be used.

Focusing on a single file item in the batch, this time being: '**02-04 Intermission.mp3**':

+ **02** represents the *DISK-NO*
+ **04** represents the *TRACK-NO*
+ **Intermission** represents the *TRACK-NAME*

Our initial naive attempt might be:

:heavy_minus_sign: 2️⃣ Rename-Many -Pattern '\d{2}' -End -WhatIf

resulting in:

> -04 Intermission02.mp3

This works, but it's not very graceful. So again we can optimise this via the ___$With___ formatter.

:heavy_minus_sign: Rename-Many -Pattern '(?\<disc\>\d{2})-' -End -With ' (disc-${disc})' -WhatIf

> 04 Intermission (disc-02).mp3

We have chosen to spice up the formatter with extra content, but as we did before, we'll examine all the points that gets us to this state:

+ **End**: switch parameter specified, this means, move the ___$Pattern___ match to the end
+ *'-'* inside ___$Pattern___: this is required, otherwise the remaining '04' will have a '-' right next to it, when this time, we'd rather it were removed. So we remove it by including it in the ___$Pattern___
+ **disc**: named capture group inside ___$Pattern___. This is now required because the ___$Pattern___ now includes a '-' which needs to be removed because a leading '-' is unsightly and unnecessary.
+ **With**: includes named group reference to the captured *DISK-NO*, but this also contains additional literal content; ie wrapping in brackets and inserting the literal 'disc-'.

However, this is not our chosen solution. We want to insert a dash in between the *TRACK-NO* and *TRACK-NAME* as we did before so that our example is renamed to: '04 - Intermission (disc-02).mp3'

Achieving this, requires more work than we completed in our initial attempt 2️⃣:

:heavy_plus_sign: Rename-Many -Pattern '(?\<disc\>\d{2})-(?\<track\>\d{2})' -End -With ' (disc-\${disc})' -Drop '${track} -' -WhatIf

which results in:

> 04 - Intermission (disc-02).mp3

Bingo! The extra points worthy of note are:

+ **Pattern**: Now, we capture the *DISK-NO* and the *TRACK-NO* and then drop *TRACK-NO*
+ **Drop**: This example illustrates that we don't have to drop static text. We can also reference named capture groups defined in ___$Pattern___ and other regex parameters such as ___$Anchor___ and ___$Copy___. In this case, we drop the *TRACK-NO* with an additional ' -'.

Let's see this in our batch:

(actually, the screen shot below uses the [Top](#parameter-ref.top) parameter to reduce the number of items processed, for brevity)

![picture](resources/images/bulk-rename.MOVE-TO-END-FINAL.fixed.jpg)

### :gem: Move to Hybrid Anchor<a name="using.move-to-hybrid-anchor"></a>

In the rename batch, some items may match the ___$Anchor___ pattern and others may not. Ordinarily, if the ___$Anchor___ does not match, then the rename will not occur for this item. This would then require the user to re-run the command with a redefined anchor or run with an entirely different parameter set. However, with a *Hybrid Anchor*, what we're saying is:

*If the specified anchor fails to match, then move the match to the Start or End*

So using a hybrid anchor allows the user to perform an anchor oriented operation with a backup if the anchor doesn't match, all in the same batch.

Consider the following directory list in our somewhat contrived example:

![picture](resources/images/bulk-rename.MOVE-TO-HYBRID-ANCHOR.dir-list.jpg)

We've decided that we want to move the date (if it exists) to precede the fragment '- at'. So in this case the date is the target of the ___$Pattern___ match and '- at' is our ___$Anchor___. The directories are not consistently named, so we'll encounter different results from each item.

Let's tailor our requirement a little and say, move the date to the ___$Anchor___ if it exists and if it doesn't, then move it to the end. This is where we need a *Hybrid Anchor*. The hybrid parameters are [___$AnchorStart___](#parameter-ref.anchorstart) and [___$AnchorEnd___](#parameter-ref.anchorend).

Before we start using a *Hybrid Anchor* let's see what happens when we use a regular one:

:heavy_minus_sign: Rename-Many -Pattern '\(?\d{2}-\d{2}-\d{4}\)?' -Anchor '- at' -Relation 'before' -WhatIf

Results in (please excuse the wraparounds):

![picture](resources/images/bulk-rename.MOVE-TO-HYBRID-ANCHOR.not-HYBRID.jpg)

Things to note:

+ 2 items filtered out, the first: **'(21-06-216) The Nephilim - Summer Solstice - at Kentish Town'** because the date is incorrect, the year is wrong, and **'Def Leppard, Hysteria in the Round - at Corn Exchange'** because it doesn't have a date at all.
+ 2 items are not renamed, the first: **'(27-03-1997) Orbital - The Middle Of Nowhere Tour Pics'** because it does not contain the ___$Anchor___ '- at' that we require and the second **'Motley Crue - Gig Photos (23-11-2011) London'** not renamed for the same reason. See the *Because* signal in the output (*'Anchor Match'*).
+ We specify ___$Relation___ to be *'after'*, since the default is 'before' and we want to move after the ___$Anchor___.

So in this particular batch run, 2 items are not renamed because the ___$Anchor___ match failed. Now let's use a *Hybrid Anchor* (we simply replace ___$Anchor___ with ___$AnchorEnd___):

:heavy_minus_sign: 3️⃣ Rename-Many -Pattern '\\(?\d{2}-\d{2}-\d{4}\\)?' -AnchorEnd '- at' -Relation 'before' -WhatIf

results in:

![picture](resources/images/bulk-rename.MOVE-TO-HYBRID-ANCHOR.with-ANCHOR-END.jpg)

Now, all the un-skipped items in the batch are renamed. When the Anchor does not match, the date is moved to the end.

But again, the date inserted could do with some alteration. Let's say we wanted to change the date format so that they are in the ISO form '\<YEAR\>-\<MONTH\>-\<DAY\>'. To do this, our ___$Pattern___ has to make use of named capture groups again. Also, other literal text can be defined, which we can achieve by using the ___$With___ parameter.

But before we move on, let's take another look at our command in 3️⃣. Did you notice anything different about this example? Well, since the directories contain characters that are special to regular expressions and we access them in our ___$Pattern___, they need to be [escaped](#general.escaping). In this case, the open '(' and close ')' brackets need escaping hence the '\\(' and '\\)' in the ___$Pattern___.

So, improving our command line, we get to:

:heavy_minus_sign: Rename-Many -Pattern '\\(?(?\<d\>\d{2})-(?\<m\>\d{2})-(?\<y\>\d{4})\\)?' -AnchorEnd '- at' -With ' - on ${y}-${m}-${d} ${_a}' -WhatIf

Resulting in:

![picture](resources/images/bulk-rename.MOVE-TO-HYBRID-ANCHOR.with-ANCHOR-END.and-captures.jpg)

Points of note:

+ **Pattern**: contains named captures for day, month and year. This is so we can re-arrange them inside ___$With___.
+ **Relation**: No need to specify the ___$Relation___ now, because ___$With___ has been specified (see next point)
+ **With**: contains a reference to the whole ___$Anchor___ (${_a}), which is now removed, requiring it to be re-inserted if so required. It also contains extra literal content, in particular a leading ' -'.

On closer inspection, it appears we have an issue. Item **'Underworld - (01-06-1999) - at Brixton Academy'** is renamed to: **'Underworld - - on 1999-06-01 - at Brixton Academy'**. The '- -' looks ugly and is an un-intended result (caused by the leading ' -' previously mentioned), which occurs because of our ___$With___ replacement, not quite meeting the needs of this item. This kind of thing happens regularly and in this situation we can exclude it so that it can be processed in a separate batch. Since this is the only item to be excluded, we can use a very specific discriminating value for the [___$Except___](#parameter-ref.except) parameter, ie: 'Underworld':

:heavy_plus_sign: Rename-Many -Except 'Underworld' -Pattern '\\(?(?\<d\>\d{2})-(?\<m\>\d{2})-(?\<y\>\d{4})\\)?' -AnchorEnd '- at' -With ' - on ${y}-${m}-${d} ${_a}' -WhatIf

and we finally arrive at:

![picture](resources/images/bulk-rename.MOVE-TO-HYBRID-ANCHOR-FINAL.with-EXCEPT.jpg)

Typically, ___$Except___ would be just generic enough to single out items to be skipped, but can't be so general as to exclude items that ought not to be. We only need to exclude a single item in this case, so our regular expression can be as specific as it needs to be (*'Underworld'*).

What we've learnt about ___$AnchorEnd___ hybrid applies identically to ___$AnchorStart___, except that the ___$Pattern___ match is moved to the start.

## :sparkles: Update Match<a name="action.update-match"></a>

| Update Parameter              | Alias | DESCRIPTION
|-------------------------------|-------|------------------------------------------------------------------
| [Paste](#parameter-ref.paste) | ps    | Formatter used when performing in place *Update*

*Update-Match* simply involves modifying a match in its present location. Since we don't have an ___$Anchor___ to deal with, it is much simpler to use than *Move Match* scenarios.

As well as no ___$Anchor___ and related parameters, instead of using the ___$With___ parameter, we use the ___$Paste___ format parameter instead and it serves a similar purpose. The peculiarities of PowerShell parameter sets means that it is much easier to use a separate parameter, rather than to try an re-use ___$With___ in a different context (it is the same reason why new parameters were defined for the *Hybrid Anchors*, instead of re-purposing ___$Anchor___/___$Start___/___$End___).

The file list which was the subject of [Move To Hybrid](#using.move-to-hybrid-anchor) will be used in the following discussion.

This time, we want to update the dates in place, changing the format to be in US date format (mm-dd-yyyy)

:heavy_plus_sign: Rename-Many -Pattern '\\(?(?\<d\>\d{2})-(?\<m\>\d{2})-(?\<y\>\d{4})\\)?' -Paste '[\${m}-\${d}-\${y}]' -WhatIf

![picture](resources/images/bulk-rename.UPDATE-MATCH-FINAL.with-PASTE.jpg)

## :sparkles: Cut Match<a name="action.cut-match"></a>

| Regex Parameter           | Alias                    | DESCRIPTION
|---------------------------|--------------------------|----------------------------------------
| [Cut](#parameter-ref.cut) | :heavy_multiplication_x: | Remove this match without a replacement

Simply removes the content matched by ___$Cut___

Let's remove the date element from the directory list featured in the previous section

:heavy_plus_sign: Rename-Many -Cut '\\(?(?\<d\>\d{2})-(?\<m\>\d{2})-(?\<y\>\d{4})\\)?' -WhatIf

![picture](resources/images/bulk-rename.CUT-MATCH-FINAL.jpg)

## :sparkles: Add Appendage<a name="action.add-appendage"></a>

### Add Prefix

| Prefix Parameter                  | Alias | DESCRIPTION
|-----------------------------------|-------|----------------------------------------------------
| [Prepend](#parameter-ref.prepend) | pr    | Prefix items' name with this literal string

Appends literal content to start of an item's name.

Using our audio file list, example from [Move To Anchor](#using.move-to-anchor), we can prefix each items name with some literal content:

:heavy_plus_sign: Rename-Many -Prepend 'Kraftwerk - ' -Top 10 -WhatIf

![picture](resources/images/bulk-rename.PREPEND-FINAL.jpg)

### Add Suffix

| Suffix Parameter                  | Alias | DESCRIPTION
|-----------------------------------|-------|----------------------------------------------------
| [Append](#parameter-ref.append)   | ap    | Append this literal string to items' name

Appends literal content to end of an item's name.

Eg:

:heavy_plus_sign: Rename-Many -Append ' - Kraftwerk' -Top 10 -WhatIf

## :sparkles: Parameter Reference<a name="parameter-reference"></a>

### :dart: Anchor<a name="parameter-ref.anchor"></a>

**Type**: [array](regular expression, string)

Indicates that the rename operation will be a move of the token from its original point
to the point indicated by [___$Anchor___](#parameter-ref.anchor). ___$Anchor___ is a regular expression string applied to the pipeline item's name (after the ___$Pattern___ match has been removed). The [___$Pattern___](#parameter-ref.pattern) match that is removed is inserted at the position indicated by the anchor match in collaboration with
the [Relation](#parameter-ref.relation) parameter.

### :dart: AnchorEnd<a name="parameter-ref.anchorend"></a>

**Type**: [array](regular expression, string)

Similar to [___$Anchor___](#parameter-ref.anchor) except that if the pattern specified by ___$AnchorEnd___ does not match, then the [___$Pattern___](#parameter-ref.pattern) match will be moved to the end. This is known as a **Hybrid Anchor**.

### :dart: AnchorStart<a name="parameter-ref.anchorstart"></a>

**Type**: [array](regular expression, string)

Similar to [___$Anchor___](#parameter-ref.anchor) except that if the pattern specified by ___$AnchorStart___ does not match, then the [___$Pattern___](#parameter-ref.pattern) match will be moved to the start. This is known as a **Hybrid Anchor**.

### :dart: Append<a name="parameter-ref.append"></a>

**Type**: [string]

Appends a literal string to end of item's name.

### :dart: Condition<a name="parameter-ref.condition"></a>

**Type**: [ScriptBlock] (predicate)

Provides another way of filtering pipeline items. This is not typically specified on the
command line, rather it is meant for those wanting to build functionality on top of *Rename-Many*.

### :dart: Context<a name="parameter-ref.context"></a>

**Type**: [PSCustomObject]

Provides another way of customising *Rename-Many*. This is not typically specified on the
command line, rather it is meant for those wanting to build functionality on top of *Rename-Many*.
*Context* should be a PSCustomObject with the following note properties:

+ Title (default: 'Rename') the name used in the batch header.
+ ItemMessage (default: 'Rename Item') the operation name used for each renamed item.
+ SummaryMessage (default: 'Rename Summary') the name used in the batch summary.
+ Locked (default: 'BULK_REMY_LOCKED) the name of the environment variable which controls
the locking of the command.
+ DisabledEnVar (default: '*BULK_REMY_UNDO_DISABLED*') the name of the environment variable
which controls if the undo script feature is disabled.
+ UndoDisabledEnVar (default: '*BULK_REMY_UNDO_DISABLED*') the name of the environment
variable which determines if the Undo feature is disabled. This allows any other function
built on top of Rename-Many to control the undo feature for itself independently of
Rename-Many.

### :dart: Copy<a name="parameter-ref.copy"></a>

**Type**: [array](regular expression, string)

Regular expression string applied to the pipeline item's name (after the [___$Pattern___](#parameter-ref.pattern) match has been removed), indicating a portion which should be copied and re-inserted (via the
format parameters [___$Paste___](#parameter-ref.paste) and [___$With___](#parameter-ref.with)). Since this is a regular expression to be used in ___$Paste___/___$With___, there is no value in the user specifying a static pattern, because that literal string can just be defined in ___$Paste___/___$With___. The value in the ___$Copy___ parameter comes
when a generic pattern is defined eg \d{3} (is non Literal), specifies any 3 digits as
opposed to say '123', which could be used directly in the formatter parameters without
the need for ___$Copy___. The match defined by ___$Copy___ is stored in special variable ${_c} and
can be referenced as such from ___$Paste___ and ___$With___.

### :dart: Cut<a name="parameter-ref.cut"></a>

**Type**: [array](regular expression, string)

Is a replacement for the [___$Pattern___](#parameter-ref.pattern) parameter, when a *Cut* operation is required. The pattern match will be removed from the item's name and no other replacement occurs.

### :dart: Diagnose<a name="parameter-ref.diagnose"></a>

**Type**: [switch]

Indicates the command should be run in ___$WhatIf___ mode. When enabled, it presents additional information that assists the user in correcting the un-expected results caused by an incorrect/un-intended regular expression. The current diagnosis will show the contents of named capture groups that they may have specified. When an item
is not renamed (usually because of an incorrect regular expression), the user can use the diagnostics along side the 'Not Renamed' reason to track down errors. When ___$Diagnose___ has been specified, ___$WhatIf___ does not need to be specified.

### :dart: Directory<a name="parameter-ref.directory"></a>

**Type**: [switch]

Indicates only Directory items in the pipeline will be processed. If neither this switch or the [File](#parameter-ref.file) switch are specified, then both File and Directory items are processed.

### :dart: Drop<a name="parameter-ref.drop"></a>

**Type**: [string]

Only applicable to move operations. Defines what text is used to replace the [___$Pattern___](#parameter-ref.pattern) match with. So in this use-case, the user wants to move a particular token/pattern to another part of the name and at the same time drop a static string in the place where the ___$Pattern___ was removed from.

### :dart: End<a name="parameter-ref.end"></a>

**Type**: [switch]

Is another type of anchor used instead of [___$Anchor___](#parameter-ref.anchor) and specifies that the [___$Pattern___](#parameter-ref.pattern) match should be moved to the end of the new name.

### :dart: Except<a name="parameter-ref.except"></a>

**Type**: [string](regular expression)

Regular expression string applied to the original pipeline item's name (before the [___$Pattern___](#parameter-ref.pattern) match has been removed). Allows the user to exclude some items that have been fed in via the
pipeline. Those items that match the exclusion are skipped during the rename batch.

### :dart: File<a name="parameter-ref.file"></a>

**Type**: [switch]

Indicates only File items in the pipeline will be processed. If neither this switch or the [___$Directory___](#parameter-ref.directory) switch are specified, then both *File* and *Directory* items are processed.

### :dart: Include<a name="parameter-ref.include"></a>

**Type**: [string](regular expression)

Regular expression string applied to the original pipeline item's name (before the [___$Pattern___](#parameter-ref.pattern) match has been removed). Allows the user to include some items that have been fed in via the
pipeline. Only those items that match ___$Include___ pattern are included during the rename batch,
the others are skipped. The value of the ___$Include___ parameter comes when you want to define
a pattern which pipeline items match, without it be removed from the original name, which is
what happens with ___$Pattern___. Eg, the user may want to specify the only items that should be
considered a candidate to be renamed are those that match a particular pattern but doing so
in ___$Pattern___ would simply remove that pattern. That may be ok, but if it's not, the user should
specify a pattern in the ___$Include___ and use ___$Pattern___ for the match you do want to be moved
(with the anchor parameters) or replaced (with the formatter parameters).

### :dart: Paste<a name="parameter-ref.paste"></a>

**Type**: [string]

Formatter parameter for Update operations. Can contain named/numbered group references
defined inside regular expression parameters, or use special named references $0 for the whole
[___$Pattern___](#parameter-ref.pattern) match and ${_c} for the whole [___$Copy___](#parameter-ref.copy) match.

### :dart: Pattern<a name="parameter-ref.pattern"></a>

**Type**: [array](regular expression, string)

Regular expression string that indicates which part of the pipeline items' name that
either needs to be moved or replaced as part of bulk rename operation. Those characters
in the name which match are removed from the name.

### :dart: Prepend<a name="parameter-ref.prepend"></a>

**Type**: [string]

Prefixes a literal string to start of item's name.

### :dart: Relation<a name="parameter-ref.relation"></a>

**Type**: [string]("before" | "after")

Used in conjunction with the [___$Anchor___](#parameter-ref.anchor) parameter and can be set to either 'before' or
'after' (the default). Defines the relationship of the [___$Pattern___](#parameter-ref.pattern) match with the ___$Anchor___ match in the new name for the pipeline item.

### :dart: Start<a name="parameter-ref.start"></a>

**Type**: [switch]

Another type of anchor used instead of [___$Anchor___](#parameter-ref.anchor) and specifies that the [___$Pattern___](#parameter-ref.pattern) match should be moved to the start of the new name.

### :dart: Test<a name="parameter-ref.test"></a>

**Type**: [switch]

Indicates if this is being invoked from a test case, so that the
output can be suppressed if appropriate. By default, the test cases should be
quiet. During development and test stage, the user might want to see actual
output in the console. The presence of variable '*EliziumTest*' in the
environment will enable verbose tests. When invoked by an interactive user in
production environment, the Test flag should not be set. Doing so will suppress
the output depending on the presence of '*EliziumTest*'. **ALL** test cases should
specify this Test flag.

### :dart: Top<a name="parameter-ref.top"></a>

**Type**: [int]

A number indicating how many items to process. If it is known that the number of items
that will be candidates to be renamed is large, the user can limit this to the first ___$Top___
number of items. This is typically used as an exploratory tool, to determine the effects
of the rename operation.

### :dart: Transform<a name="parameter-ref.transform"></a>

**Type**: [ScriptBlock]

A script block which is given the chance to perform a modification to the finally named
item. The transform is invoked prior to post-processing, so that the post-processing rules
are not breached and the transform does not have to worry about breaking them. The transform
function's signature is as follows:

+ Original: original item's name
+ Renamed: new name
+ CapturedPattern: pattern capture

and should return the new name. If the transform does not change the name, it should return
an empty string.

### :dart: underscore<a name="parameter-ref.underscore"></a>

**Type**: [FileSystemInfo]

The pipeline item which should either be an instance of FileInfo or DirectoryInfo.

### :dart: Whole<a name="parameter-ref.whole"></a>

**Type**: [char]

Provides an alternative way to indicate that the regular expression parameters
should be treated as a whole word (it just wraps the expression inside \b tokens).
If set to '*', then it applies to all expression parameters otherwise a single letter
can specify which of the parameters 'Whole' should be applied to. Valid values are:

+ 'p': $Pattern
+ 'a': $Anchor/AnchorEnd/AnchorStart
+ 'c': $Copy
+ 'i': $Include
+ 'x': $Except
+ '*': All the above
(NB: Currently, can't be set to more than 1 of the above items at a time)

### :dart: With<a name="parameter-ref.with"></a>

**Type**: [string]

Formatter which defines what text is used as the replacement for the [___$Pattern___](#parameter-ref.pattern)
match. Works in concert with [___$Relation___](#parameter-ref.relation) (whereas [___$Paste___](#parameter-ref.paste) does not). ___$With___ can reference special variables:

+ $0: the pattern match
+ ${_a}: the anchor match
+ ${_c}: the copy match

When ___$Pattern___ contains named capture groups, these variables can also be referenced. Eg if the
___$Pattern___ is defined as '(?\<day>\d{1,2})-(?\<mon>\d{1,2})-(?\<year>\d{4})', then the variables
\${day}, \${mon} and \${year} also become available for use in ___$With___ or ___$Paste___.

Typically, ___$With___ is literal text which is used to replace the ___$Pattern___ match and is inserted
according to the anchor parameters and ___$Relation___. When using ___$With___, whatever is defined in the *anchor* match **IS** removed from the pipeline's name and requires the user to re-insert it with '${_a}' inside ___$With___
if so required. The reason for this is that when ___$With___ is not present, the ___$Pattern___ match content is inserted verbatim next to the ___$Anchor___ either before or after. But if we use a ___$With___, then the user has full control over whereabouts the ___$Anchor___ is inserted inside ___$With___, so ___$Relation___ is redundant.

## :radioactive: Troubleshooting / Common Errors<a name="troubleshooting"></a>

Most issues that occur with using *Rename-Many* is as the result of not defining a regex pattern correctly. These clearly can only be fixed, by reviewing the pattern and adjusting accordingly.

It is advised that users always run with ___$WhatIf___ enabled for new invocations of Rename-Many, so that the results can be confirmed before being actioned for real. When unexpected results occur, the user can specify the ___$Diagnose___ parameter to ensure that named capture groups are working as expected. Readers are also directed to use other 3rd party resources to debug regex patterns such as [regex101](https://regex101.com).

+ incorrect use of double quotes on formatter parameters; use single quotes to avoid incorrect interpolation. (See [Formatters Must Use Single Quotes](#using.formatters-must-use-single-quotes))
+ use PCRE compatible patterns. Eg, for named capture groups some regex engines use '(P?\<name\>)', this form will not work with Rename-Many, so make sure the correct syntax is being used in regex definitions.
+ mixing up ___$Paste___ with ___$With___. In the early stages of using *Rename-Many*, the user may accidentally use the wrong formatter parameter for the rename action being performed, usually resulting in PowerShell prompting for the wrong mandatory arguments or simply resulting in a terminating error. ___$With___ is used for *Move* operations and ___$Paste___ is used for static in-place updates.

## :hammer: Expanding Rename-Many Capabilities<a name = "expanding-rename-many"></a>

### :mortar_board: Higher Order Commands<a name = "higher-order-commands"></a>

Provides the facility to reuse the base *Rename-Many* functionality to build higher level functionality. Since regular expressions are not particularly easy to specify without prior skill and knowledge, it might be advantageous to build a high level command that wraps the base functionality and has embedded within it a commonly used combination of parameters and regular expression definitions. This way the high level version can hide-away difficult to remember regular expressions that are used on a regular basis.

To build a high level *Rename-Many* command, a developer should perform the following tasks:

+ Define the contents of the [___$Context___](#parameter-ref.context) parameter
+ Define the regular expression and formatter parameters that need to be abstracted away and encapsulated
+ Define the new user facing parameter set
+ Define the higher level command implementation

Let's say we want to create a command to re-arrange dates in UK format (dd-mm-yyyy) to ISO format 'yyyy-mm-dd', called **Convert-Date**

:pencil: **1) Define a context**

```powershell
  [PSCustomObject]$Context = [PSCustomObject]@{
    Title             = 'Reformat UK dates to ISO Format';
    ItemMessage       = 'To ISO format';
    SummaryMessage    = 'UK Dates Converted to ISO';
    Locked            = 'CONVERT_UK_DATES_LOCKED';
    UndoDisabledEnVar = 'CONVERT_UK_DATES_UNDO_DISABLED';
    OperantShortCode  = 'convuk';
  }
```

Taking one of the previously displayed screen-shots ...:

![picture](resources/images/bulk-rename.MOVE-TO-HYBRID-ANCHOR.with-ANCHOR-END.jpg)

... we can see, where some of those context items appear in the output. From this screen-shot:

+ *Title* ('Locked: Rename'): **'Locked: Reformat UK dates to ISO Format'**
+ *ItemMessage* ('Rename Item'): **'To ISO format'**
+ *SummaryMessage* ('Rename Summary'): **'UK Dates Converted to ISO'**

The other non UI elements:

+ *Locked*: The name of the environment variable used to unlock this command
+ *UndoDisabledEnVar*: The name of the environment variable used to disable the *Undo Rename* feature for this command
+ *OperantShortCode*: A short code representing the command (typically, the command's alias) used as part of the path to files generated by the *Undo Rename* feature

:pencil: **2) Define the arguments passed into 'Rename-Many'**

+ ___$Pattern___: '(?\<d>\d{2})-(?\<m>\d{2})-(?\<y>\d{4})'
+ ___$Paste___: '(\${y}-\${m}-\${d})'

These arguments will be hardcoded into *Convert-Date*, so that the end user doesn't have to specify them.

:pencil: **3) Define new user facing parameters**

We can either accept file system objects from the pipeline (but they would need to be collected up and passed into a new pipeline involving *Rename-Many*) or define a new ___$Path___ like parameter. We'll do the latter in this case and call it ___$LiteralPath___.

We probably need to replicate ___$WhatIf___ and ___$Diagnose___, which would be forwarded onto *Rename-Many*. In the case of ___$WhatIf___, we don't define that explicitly, instead we decorate our function with *SupportsShouldProcess*. But it should be noted that generally, the value of ___$WhatIf___ flows from the user invoked command to other standard PowerShell functions (eg *Move-Item*), but it doesn't flow from one 3rd party command to another unless they are in the same module. That is to say, ___$WhatIf___ does not cross module boundaries (except the standard PowerShell functions). This means we need to forward the value of ___$WhatIf___ explicitly, by doing something like:

> -WhatIf:$($PSBoundParameters.ContainsKey('WhatIf'))

Since *$WhatIf* doesn't exist in its own right, we need to use *$PSBoundParameters* to see if it is present in the bound parameters.

Now we end up with a command signature as follows:

```powershell
  function Convert-Date {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('convuk')]
    param( 
      [Parameter()]
      [string]$LiteralPath,

      [Parameter()]
      [switch]$Diagnose
    )
    ...
  }
```

:pencil: **4) Define the implementation**

Typically, the parameters to *Rename-Many* would be splatted, via a hashtable.

```powershell
  function Convert-Date {
    # signature not repeated, see previous code snippet instead

    [PSCustomObject]$context = @{
      Title             = 'Reformat UK dates to ISO Format';
      ItemMessage       = 'To ISO format';
      SummaryMessage    = 'UK Dates Converted to ISO';
      Locked            = 'CONVERT_UK_DATES_LOCKED';
      UndoDisabledEnVar = 'CONVERT_UK_DATES_UNDO_DISABLED';
      OperantShortCode  = 'convuk';
    }

    [hashtable]$parameters = @{
      'Pattern'  = '(?<d>\d{2})-(?<m>\d{2})-(?<y>\d{4})';
      'Paste'    = '(${y}-${m}-${d})';
      'Context'  = $context;
      'Diagnose' = $Diagnose.IsPresent;
      'WhatIf'   = $PSBoundParameters.ContainsKey('WhatIf');
    }

    Get-ChildItem -LiteralPath $LiteralPath | Rename-Many @parameters
  }
```

The user can use the higher order command *Convert-Date* with a simpler more specialised interface instead of *Rename-Many*, eg:

:heavy_plus_sign: Convert-Date -LiteralPath ~/logs -WhatIf

Note, there is another way of complementing the functionality of existing commands that would apply in this scenario and that is with a *Proxy Command*. This is a slightly more involved process but contains some of the same techniques just discussed. It's out of the scope of this documentation, but [here](https://devblogs.microsoft.com/scripting/proxy-functions-spice-up-your-powershell-core-cmdlets/) is a blog post that describes how to apply this technique.

### :robot: Using Transform<a name = "using.transform"></a>

Another way to obtain custom functionality from *Rename-Many* is to provide a custom script-block for the *Transform* parameter. This will be illustrated with an example that replaces all '[' with '(' and all ')' with ']'. This might be useful to skirt round a widely encountered problem using the ___$Path___ parameter of mutating commands like *Rename-Item* which ascribes custom semantics to '[' and ']' in file system paths, causing un-expected results. (This can be averted using ___$LiteralPath___, but this is just an example to discuss using the *Transform* parameter.)

The signature of the *Transform* script-block is as follows

```powershell
  param(
    [Parameter()]
    [string]$Original,

    [Parameter()]
    [string]$Renamed,

    [Parameter()]
    [string]$PatternCapture,

    [Parameter()]
    [hashtable]$Exchange
  )
```

where:

+ **Original:** The original file or directory name
+ **Renamed:** The original name with the ___$Pattern___ match removed
+ **PatternCapture:** The content matched by ___$Pattern___
+ **Exchange:** The exchange instance (See [Exchange](../../README.md/#general.exchange))

This could be implemented as follows

```powershell
  [ScriptBlock]$transformer = [ScriptBlock] {
    param($Original, $Renamed, $PatternCapture, $Exchange)
    return $Original.Replace('[', '(').Replace(']', ')');
  }
```

... and theoretically, could be invoked as:

:heavy_multiplication_x: Rename-Many -Pattern '\\[[\w]+\\]' -Transform $transformer -WhatIf

But, the *Transform* parameter is not meant to be used interactively (although it could be, but would be cumbersome). Rather, the intention is that the user would create a [*Higher Order Command*](#higher-order-commands) so invoking this function interactively would become more convenient on the command line.

:pushpin: In this example, the ___$Pattern___ becomes a filter, such that only items containing any word characters (\\w) inside square brackets are processed.

## :green_salad: Recipes<a name = "develop.recipes"></a>

This section *will* contain some examples that solve common renaming requirements. They are intended to give the reader a jump start in defining their own regular expressions and formatters to use with *Rename-Many*.

## :hammer: Developer Notes<a name = "develop.notes"></a>

This module has the following developer dependencies:

+ [Assert](https://www.powershellgallery.com/packages/Assert)
+ [InvokeBuild](https://www.powershellgallery.com/packages/InvokeBuild)
+ [Pester](https://www.powershellgallery.com/packages/Pester)
+ [platyPS](https://www.powershellgallery.com/packages/platyPS)
+ [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer/)

After cloning the repo, change to the *Elizium.Bulk* directory from the root. You can look at the build script *Elizium.Bulk.build.ps1*, it will contain various tasks, the most important of which are explained below

### Running build tasks<a name = "develop.running-build-tasks"></a>

To build the module and run the unit tests:

> invoke-build

To build the module only:

> invoke-build build

To Run the unit tests only (assuming already built)

> invoke-build tests

To build external help:

> invoke-build buildHelp

#### Problem rebuilding modified classes in the same PowerShell session<a name = "develop.problem-rebuilding"></a>

:warning: __Elizium.Bulk__ makes use of PowerShell classes. Because of the nature of classes in PowerShell, re-building edited code can cause errors. This is not a fault of the __Elizium.Bulk__ code, it's just the way PowerShell classes have been designed.

What you will find is, if a class has been modified then rebuilt in the same session, you may find multiple class errors like so:

```powershell
[-] EndAdapter.given: EndAdapter.should: get name 31ms (30ms|1ms)
 PSInvalidCastException: Cannot convert the "EndAdapter" value of type "EndAdapter" to type "EndAdapter".
 ArgumentTransformationMetadataException: Cannot convert the "EndAdapter" value of type "EndAdapter" to type "EndAdapter".
 at <ScriptBlock>, ..\github\PoSh\Bulk\Elizium.Bulk\Tests\Rename-Many.tests.ps1:21
```

Fear not, this is just reporting that the class definition has changed and because of this difference, one can't be substituted for another in the same PowerShell session (this is in contrast to the way functions work, where you can simply re-define a function in the same session and it will replace the previous definition. This luxury has not been afforded to classes unfortunately). All that's required is to restart a new session. The rebuild in the new session should progress without these errors.

It is a bit onerous having to restart a session for every build, but below is a function that can be defined in the users powershell profile that when invoked, begins a restart loop. Now, when an exit is issued, the session is automatically restarted:

#### Helper function restart-session<a name = "develop.restart-session"></a>

Insert this into your PowerShell session file.

```powershell
function Get-TagPath {
  return Join-Path $env:temp -ChildPath 'restart-session.tag.txt';
}

function Restart-Session {
  [Alias('ress')]
  param()
 
  [string]$tagPath = Get-TagPath;
  if (-not([string]::IsNullOrEmpty($env:tag))) {
    Set-Content -Path $tagPath -Value $env:tag;
  }
  elseif (Test-Path -Path $tagPath) {
    Remove-Item -Path $tagPath;
  }

  [System.Management.Automation.PathInfo]$pathInfo = Get-Location;
  while ($true) {
    pwsh -Command {
      [string]$tagPath = Get-TagPath;
      [string]$greeting = "🍺 Restarted!";
      if (Test-Path -Path $tagPath) {
        $tag = Get-Content -Path $tagPath;

        if (($tag -is [string]) -or ($tag -is [string[]])) {
          $env:tag = $tag;
          $greeting = "🍺 Restarted! (Pester Tag: '$env:tag' ✔️)";
        }
      }

      Write-Host -ForegroundColor 'Cyan' $greeting;
    } -NoExit -WorkingDirectory $($pathInfo.Path)
    if ($LASTEXITCODE) {
      break
    }
  }
}
```

Another feature this function possesses is the restoration of the *Tag* environment variable. The Tag is used to control which testcases Pester runs. Pester contains a Tag in its configuration and when set, it will only run those test cases decorated with this tag value.

So, when a restart occurs, the Tag if set is restored and you will see which tag is in play as part of the restart. If no tag is found then no tag is restored. This function just helps the tedium of having to keep redefining the Tag in-between restarts, as now this is automatically restored.

The sequence goes:

+ Set the tag (if you want one): "$env:tag = 'Current'"
+ restart session: "restart-session" (this saves the current tag; written to a temp file)

After restart, tag is restored and the restart message will indicate as such

+ Modify class definition
+ first build should be ok
+ Re-edit the class definition, then rebuild => this will fail
+ run "exit", this will automatically restart the session, restoring the Tag value

... and repeat.

### :triangular_flag_on_post: EliziumTest flag

The user can set this flag in the environment (just set it to any non $null value).

By default, $env:EliziumTest, will not be present, this means, that the unit tests in __Elizium.Bulk__ will run in silent mode. However, there are some tests which are less valuable in silent mode, doing so would invalidate them to some degree. There are only a few of the tests in this category (tagged as 'Host') and it's because they require Write-Host to be invoked. Theoretically, one could mock out the Write-Host call, but some errors can be much easier to spot visually. This generally is not the best technique in unit-testing, but these test cases have been backed up by non noisy equivalents to make sure all bases are covered.

During development, it is very useful to get a visual on how ui commands are behaving. This was the rationale behind the introduction of this flag. So when *EliziumTest* is defined, the user will see more output that reflects the execution of the Scribbler and Krayon.
