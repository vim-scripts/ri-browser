" Vim filetype plugin
" Language:	ri / Ruby Information
" Description:	Interface for browsing ri/ruby documentation.
" Maintainer:   Jonas Fonseca <fonseca@diku.dk>
" Last Change:  Nov 25th 2002
" CVS Id:	$Id: ri.vim,v 1.4 2002/11/25 02:56:53 fonseca Exp $
" License:	This file is placed in the public domain.
" Credits:	Thanks to Bob Hiestand <bob@hiestandfamily.org> for making
"		the cvscommand.vim plugin from which much of the code
"		derives. <URL:http://www.vim.org/script.php?script_id=90>
"
" Section: Documentation {{{1
"
" Tip: {{{2
"
" Add something like
"
"	" Load ri interface
"	source $VIMFILES/ftplugin/ri.vim
"
" to your ftplugin/ruby.vim to load it when editing ruby files.
"
" Options: {{{2
"
" To set an option simply put
"
"	let <option> = <value>
"
" in your vimrc file.
"
" Note: For all string/bool options goes that setting them to anything
" different from the default will result in the opposite behaviour.
"
" Option:	ri_split_orientation
" Type:		string/bool
" Description:	Controls the split orientation when creating the Ri buffer.
" Default:	'horizontal'
"
" Option:	ri_nonprompting_history
" Type:		string/bool
" Description:	Controls wether lookups derived from word under the cursor
" 		should be added to the input history.
" Default:	'add'
"
" Option:	ri_check_expansion
" Type:		string/bool
" Description:	Controls wether to abandon expansion when the search term's
"		first character is uppercase[1] to avoid bogus lookups like
"		Array#Hash. Only affects lookups done in a Ri class/module
"		buffer[2].
"
"		Provided as an option since lookups like 'Kernel#Array' are
"		valid although this should not be important since this will
"		result in the same lookup as with checking enabled.
"		(see also impact on <M-[> mapping below)
" Default:	'on' (meaning: do the check)
"
" [1] In Ruby this indicates a class or module name.
" [2] A Ri class/module buffer is a buffer showing all the methods belonging
"     to a class/modul. Example: typing ':Ri Hash' followed by enter in
"     normal mode will open the 'Hash' class buffer.
"
" Events: {{{2
"
"   It's possible to define autocommands to be run when a Ri buffer has
"   been created. For instance, the following could be added to vimrc
"   to provide a 'q' mapping to quit a Ri buffer:
"
"   augroup Ri
"     au Ri RiBufferCreated silent! nmap <unique> <buffer> q:bwipeout<cr> 
"   augroup END
"
" Mappings: {{{2
"
" Below are a description of the default mappings that are defined.
" User-defined mappings can be used instead by mapping to <Plug>CommandName,
" for instance:
"
"	nnoremap ,ri <Plug>Ri
"
" The following command names are available:
" 
"   Ri		Prompts for word to lookup.
"   RiExpand	Prepends class/module if any before promption for word.
"
" Prompting:
"
"   <M-i>	Clean prompting.
"   <M-I>	Prepend class/module if any before prompting. (ex: Array#)
"
"   <Leader>ri	Same as <M-i>
"   <Leader>rx	Same as <M-I>
"
" Cursorword:
"
" When using the words under the cursor (WUC) trailing characters like
" punctuation dots, commas and parenthesis are removed before Ri is called.
"
"   <M-]>	Gready expansion of WUC. This will work for both the
"		'Array.new', 'Hash#each' and 'Kernel::block_given?' way of
"		specifying a method.
"
"   <M-[>	Not so gready expansion of WUC but will also prepending the
"		class/module when in a Ri class/module buffer[3]. This makes
"		it possible to lookup 'Array#each' by placing cursor on
"		'each' in the 'Array' class buffer. Note that when the option
"		ri_check_expansion[4] is not 'on' ('on' being the default) this
"		can result in bogus lookups like 'Float#Marshall'.
"
" [3] See footnote 2 in the Option section. ;)
" [4] Descripted in the Option section as well.
"
" Todo: {{{2
"
" Still some rough edges to work on but quite usefull already. This is my
" first plugin so please send comments. Anyway here some possible futuristic
" improvements:
"
" * Better syntax highlighting.
" * Better 'chomping' of words so 'Array.new.first' gives 'Array.new'
" * Lookup rdoc's or use http://www.ruby-doc.org/ri (through text browser
"   or external ruby script) if ri is not installed. ;P
" * History! Could be term/lookup history but also class/module history.
"   Luckily Vim takes care of prompting history. :)
"
" Section: Loading {{{1

" Only do this when not done yet for this buffer
if exists("g:did_riinterface")
  finish
endif

" Don't load another plugin for this buffer
let g:did_riinterface = 1

" Section: Event group setup {{{1
 
augroup Ri
augroup END

" Function: s:RiGetOption(name, default) {{{1 
" Grab a user-specified option to override the default provided.
" Options are searched in the window, buffer, then global spaces.

function! s:RiGetOption(name, default)
  if exists("w:" . a:name)
    execute "return w:".a:name
  elseif exists("b:" . a:name)
    execute "return b:".a:name
  elseif exists("g:" . a:name)
    execute "return g:".a:name
  else
    return a:default
  endif
endfunction

" Function: s:RiGetBuffer() {{{1
" Attempts to switch to the LRU Ri buffer else creates a new buffer.

function! s:RiSetupBuffer(name)
  if exists("g:ri_buffer") && bufwinnr(g:ri_buffer) != -1
    " The Ri buffer is still open so switch to it
    let s:switchbuf_save = &switchbuf
    set switchbuf=useopen
    execute 'sbuffer' g:ri_buffer
    let &switchbuf = s:switchbuf_save
    let edit_cmd   = 'edit'
  else
    " Original buffer no longer exists.
    let v:errmsg = ""
    if s:RiGetOption('ri_split_orientation', 'horizontal') == 'horizontal'
      let edit_cmd = 'rightbelow split'
    else
      let edit_cmd = 'vert rightbelow split'
    endif
  end

  execute edit_cmd a:name
  if v:errmsg != ""
    if &modified && !&hidden
      echoerr "Unable to open command buffer: 'nohidden' is set and the current buffer is modified (see :help 'hidden')."
    else
      echoerr "Unable to open command buffer:" v:errmsg
    endif
    return -1
  endif

  " Define the environment and execute user-defined hooks.
  silent do Ri User RiBufferCreated
  let g:ri_buffer     = bufnr("%")
  set buftype=nofile
  set noswapfile
  set filetype=ri
  set bufhidden=delete " Delete buffer on hide

  return g:ri_buffer
endfunction

" Function: s:RiExecute(term) {{{1
" Sets up the Ri buffer and executes the Ri lookup 

function! s:RiExecute(term)
  let command    = '0r!ri "' . a:term . '"'
  let buffername = 'Ri browser [' . escape(a:term, ' |\*') . ']'

  if s:RiSetupBuffer(buffername) == -1
    return -1
  endif

  silent execute command
  $d
  1
endfunction

" Function: s:RiGetClassOrModule() {{{1
" Returns the class/module name when in a class/module ri buffer

function! s:RiGetClassOrModule()
  let line   = getline(2)
  let ident  = substitute(line, '^\s\{5}\(class\|module\): \([A-Z]\w*\).*$', '\2', '')
  if line == ident " No match
    let ident = ''
  else
    " Appending the hash here makes it useful if prompting later
    let ident = ident . '#'
  endif
  return ident
endfunction

" Function: Ri(term) {{{1
" Handles class/module expansion and initial escaping of search term.
" <expand> is a bool [0|1].
" <term> is a string. Prompting is done when it's empty.

function! Ri(term, expand)
  let class = ''
  if a:expand == 1
    let class = s:RiGetClassOrModule()
  endif

  if s:RiGetOption('ri_check_expansion', 'on') == 'on'
    " If the search term's first char is uppercase don't expand
    if a:expand && match(a:term, '^[A-Z]') == '0'
      let class = ''
    endif
  endif

  " Remove trailing characters
  " Note: Remove punctuation dots. Non-greedy dot removal handled elsewhere.
  let term = substitute(a:term, '[,()].*\.\?$', '', '')
  if term == ''
    let term = input('Ri search term: ', class)
  elseif class != '' && a:expand
    let term = class . term
  endif

  if s:RiGetOption('ri_nonprompting_history', 'add') == 'add'
    call histadd('input', term)
  endif

  " Escape so Vim don't substitute with buffer name.
  call s:RiExecute(escape(term, '#'))
endfunction

command! -nargs=1 Ri	   :call Ri('<args>', 0)
command! -nargs=1 RiExpand :call Ri('<args>', 1)

" Section: Setup mappings {{{1

" Prompt for search term
nnoremap <unique> <Plug>Ri :call Ri('', 0)<CR>
if !hasmapto('<Plug>Ri')
  nmap <unique> <Leader>ri <Plug>Ri
endif

if !hasmapto('<M-i>')
  noremap <M-i> :call Ri('', 0)<CR>
endif

" Expand class/module if possible and prompt
nnoremap <unique> <Plug>Rx :call Ri('', 1)<CR>
if !hasmapto('<Plug>Rx')
  nmap <unique> <Leader>rx <Plug>Rx
endif

if !hasmapto('<M-I>')
  noremap <M-I> :call Ri('', 1)<CR>
endif

" Tag-like greedy invoking
if !hasmapto('<M-]>')
  noremap <M-]> :call Ri(expand('<cWORD>'), 0)<cr>
endif

" Not so greedy invoking. Accept chars up to first dot.
" Unfortunately when cursor is on 'new' in 'Array.new' resolves to 'Array' :(
if !hasmapto('<M-[>')
  noremap <M-[> :call Ri(substitute(expand("<cword>"), '\..*', '', ''), 1)<cr>
endif
