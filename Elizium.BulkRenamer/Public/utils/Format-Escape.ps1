
function Format-Escape {
  <#
  .NAME
    Format-Escape

  .SYNOPSIS
    Escapes the regular expression specified. This is just a wrapper around the
  .net regex::escape method, but gives the user a much easier way to
  invoke it from the command line.

  .DESCRIPTION
    Various functions in Loopz have parameters that accept a regular expression. This
  function gives the user an easy way to escape the regex, without them having to do
  this manually themselves which could be tricky to get right depending on their
  requirements. NB: an alternative to using the 'esc' function is to add a ~ to the start
  of the pattern. The tilde is not taken as part of the pattern and is stripped off.

  .LINK
    https://eliziumnet.github.io/Loopz/

  .PARAMETER Source
    The source string to escape.

  .EXAMPLE 1
  Rename-Many -Pattern $(esc('(123)'))

  Use the 'esc' alias with the Rename-Many command, escaping the regex characters in the Pattern definition

  .EXAMPLE 2
  Rename-Many -Pattern '~(123)'

  Use a leading '~' in the pattern definition, to escape the whole value.

  .EXAMPLE 3
  Rename-Many -Pattern $('esc(123)' + '_(?<n>\d{3})')

  Split the pattern into the parts that need escaping and those that don't. This will
  match 
  #>
  [Alias('esc')]
  [OutputType([string])]
  param(
    [Parameter(Position = 0, Mandatory)]$Source
  )
  [regex]::Escape($Source);
}
