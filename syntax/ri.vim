" Vim syntax file
" Language:	Vim help file
" Maintainer:	Jonas Fonseca <fonseca@diku.dk>
" Last Change:	Nov 24th 2002

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn include @riRuby <sfile>:p:h/ruby.vim

syn region	riDelimRegion	start=+^---*+ end=+^---*+ contains=riApiCode,@riTitle

" Ruby code should be matched over moere lines. Not just one at the time.
syn region	riApiCode	contained start=+^\s\{5}+ end=+\(->\|$\)+me=s-1 keepend contains=riComma,@riRuby nextgroup=riEvalsto
syn match	riEvalsTo	contained "->"
syn match	riComma		contained ","

" Keep below riApiCode but before riExampleCode ;)
syn match	riDescription	"^\s\{5}.*$"

syn cluster	riTitle		contains=riClassOrModule,riAppend,riMethod

syn match	riClassOrModule	contained "[A-Z]\w*"	nextgroup=riAppend
syn match	riAppend	contained "\(\#\|::\)"	nextgroup=riMethod
syn match	riMethod	contained "[a-z_[\]=?]*$"

syn region	riExampleCode	start=+^\s\{8}+ end=+\(#=>\|$\)+me=s-1 keepend contains=@riRuby nextgroup=riEvalsTo
syn match	riEvalsTo	"#=>.*$" contains=riOutput
syn region	riOutput	start=+#=>+ms=s+3 end=+$+me=s-1 keepend contains=@riRuby

syn sync minlines=40

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_help_syntax_inits")
  if version < 508
    let did_help_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink riDelimiter		Delimiter
  HiLink riDelimRegion		Delimiter
  HiLink riClassOrModule	Identifier
  HiLink riMethod		Keyword
  HiLink riUnmatched		Special
  HiLink riAppend		PreProc
  HiLink riClassFunction	Operator
  HiLink riEvalsTo		PreProc
  HiLink riDescription		Comment

delcommand HiLink
endif

let b:current_syntax = "ri"

" vim: ts=8 sw=2
