" Universal Vim templates
" Author: Mikolaj Machowski ( mikmach AT wp DOT pl )
" License: GPL v. 2.0
" Version: 1.0
" Last_change: 30 aug 2004
" 
" Replica of DreamWeaver(tm) templates and libraries.

" Initialization {{{

if exists("loaded_vut")
 finish
endif
let g:loaded_vut = 1

" }}}
" Set default comment strings {{{
let b:vut_bcom = '/*'
let b:vut_ecom = '*/'

" }}}

" ======================================================================
" Commands
" ======================================================================
" Templates {{{
command! -nargs=? VHTcommit call VUT_Commit(<q-args>)
command! -nargs=? VHTupdate call VUT_Update(<q-args>)
command! -nargs=? VHTcheckout call VUT_Checkout(<q-args>)
command! -nargs=? VHTstrip call VUT_Strip(<q-args>)
command! -nargs=? VHTinsert call VUT_Insert(<q-args>)

" }}}
" Libraries {{{
command! -nargs=? VHLcommit call VUL_Commit(<q-args>)
command! -nargs=? VHLupdate call VUL_Update(<q-args>)
command! -nargs=? VHLcheckout call VUL_Checkout(<q-args>)
command! -nargs=? VHLstrip call VUL_Strip(<q-args>)
command! -nargs=? VHLinsert call VUL_Insert(<q-args>)

" }}}
" Show available templates/libraries {{{
command! -nargs=0 VHTshow call VUT_Show("templates")
command! -nargs=0 VHLshow call VUT_Show("libraries")

" }}}
" Check if editable regions are properly declared {{{
command! -nargs=0 VHTcheck echo VUT_Check()

" }}}

" VUT versions {{{
" Templates {{{
command! -nargs=? VUTcommit call VUT_Commit(<q-args>)
command! -nargs=? VUTupdate call VUT_Update(<q-args>)
command! -nargs=? VUTcheckout call VUT_Checkout(<q-args>)
command! -nargs=? VUTstrip call VUT_Strip(<q-args>)
command! -nargs=? VUTinsert call VUT_Insert(<q-args>)

" }}}
" Libraries {{{
command! -nargs=? VULcommit call VUL_Commit(<q-args>)
command! -nargs=? VULupdate call VUL_Update(<q-args>)
command! -nargs=? VULcheckout call VUL_Checkout(<q-args>)
command! -nargs=? VULstrip call VUL_Strip(<q-args>)
command! -nargs=? VULinsert call VUL_Insert(<q-args>)

" }}}
" Show available templates/libraries {{{
command! -nargs=0 VUTshow call VUT_Show("templates")
command! -nargs=0 VULshow call VUT_Show("libraries")

" }}}
" Check if editable regions are properly declared {{{
command! -nargs=0 VUTcheck echo VUT_Check()

" }}}
" }}}

" ======================================================================
" Main functions
" ======================================================================
" VUT_Commit: write noneditable area to .vht file {{{
" Description: Write file line by line to register, skipping editable
" 		areas, then overwriting .vht file. Meantime it will extract
" 		links and change them to fullpaths ":p".
function! VUT_Commit(tmplname)

	" Check the most important thing about templates: is a storage place
	" for them?
	let vutlevel = VUT_GetMainFileName(":p:h")
	if isdirectory(vutlevel.'/Templates/') != 0
		let vutdir = vutlevel.'/Templates/'
	else
		echomsg "VUT: Templates directory doesn't exist. Create it!"
		return
	endif


	" Check if all regions are safely declared
	let vutcheck = VUT_Check()
	if vutcheck != 'Did not detect anything wrong.'
		echo vutcheck
		return
	endif
		
	let g:asdf = "asdf"

	" Save current position
	let sline = line('.')
	let cpos = line(".") . " | normal!" . virtcol(".") . "|"

	let curd = getcwd()
	let filedir = expand('%:p:h')
	" change to dir where is file to get proper extension of relative
	" filenames
	call VUT_CD(filedir)

	normal! gg
	let editable = 0
	let z_rez = @z
	let @z = ''
	while line('.') <= line('$')
		let line = getline('.')
		if editable == 1 && line !~ VUT_Ebcom().'\s*#EndEditable.*'.VUT_Eecom()
			normal! j
			continue
		endif
		if line =~ VUT_Ebcom().'\s*#BeginEditable.*'.VUT_Eecom()
			let editable = 1
		endif
		if line =~ VUT_Ebcom().'\s*#EndEditable.*'.VUT_Eecom()
			let editable = 0
		endif

		" Check if in line are links, when positive expand them to full
		" paths
		let line = VUT_ExpandLinks(line)

		" Prevent inserting blank line at the beginning
		if @z == ''
			let @z = line
		else
			let @z = @z."\n".line
		endif

		" Service last line without infinite loop
		if line('.') == line('$')
			break
		endif

		normal! j
	endwhile

	" Put contents of @z to template file. Find .vutmain to check where
	" Templates is dir for them - following Dreamweaver.
	" Let check if argument exists or name of template was previously
	" set. This will enable use of multiply templates in one project. 
	if a:tmplname != ''
		let vutfile = vutdir.a:tmplname.'.vht'
		let b:vutemplate = a:tmplname

	elseif exists("b:vutemplate") && a:tmplname == ''
		let vutfile = vutdir.b:vutemplate.'.vht'

	else
		let vutname = input("You didn't specify Template name.\n".
				   \   "Enter name of existing template -\n".
				   \   VUT_ListFiles(vutdir, 'vht').
				   \   "\nOr a new one (<Enter> to abandon action): ")

		if vutname != ''
			let b:vutemplate = vutname
			let vutfile = vutdir.b:vutemplate.'.vht'
		else

			silent! exe cpos
			echo "I do not know template name."
			return
		endif

	endif

	silent! exe "below 1split ".vutfile
	silent! normal! gg"_dG
	silent! put! z
	silent! write
	silent! exe "bwipe ".vutfile
	let @z = z_rez

	" Return to current dir
	call VUT_CD(curd)

	if getline('$') == ''
		silent! $d
	endif

	silent! exe cpos

endfunction

" }}}
" VUT_Checkout: 0read in template to current file {{{
" Description: Locate template and read in to the current file. Also
" 		correct links. It assumes file is empty!
function! VUT_Checkout(tmplname)
	" Check the most important thing about templates: is a storage place
	" for them?
	let vutlevel = VUT_GetMainFileName(":p:h")
	if isdirectory(vutlevel.'/Templates/') != 0
		let vutdir = vutlevel.'/Templates/'
	else
		echomsg "VUT: Templates directory doesn't exist. Create it!"
		return
	endif

	" Put contents of @z to template file. Find .vutmain to check where
	" Templates is dir for them - following Dreamweaver.
	" Let check if argument exists or name of template was previously
	" set. This will enable use of multiply templates in one project. 
	if a:tmplname != ''
		let vutfile = vutdir.a:tmplname.'.vht'
		let b:vutemplate = a:tmplname

	elseif exists("b:vutemplate") && a:tmplname == ''
		let vutfile = vutdir.b:vutemplate.'.vht'

	else
		let vutname = input("You didn't specify Template name.\n".
				   \   "Enter name of template -\n".
				   \   VUT_ListFiles(vutdir, 'vht').
				   \   "\n(<Enter> to abandon action): ")

		if vutname != ''
			let b:vutemplate = vutname
			let vutfile = vutdir.b:vutemplate.'.vht'

		else
			return

		endif

	endif

	exe 'silent 0read '.vutfile

	let curd = getcwd()
	let filedir = expand('%:p:h')
	" change to dir where is file to get proper extension of relative
	" filenames
	call VUT_CD(filedir)

	normal! gg

	while line('.') <= line('$')

		call VUT_CollapseLinks(getline('.'))

		" Service last line without infinite loop
		if line('.') == line('$')
			break
		endif

		normal! j

	endwhile

	" Return to current dir
	call VUT_CD(curd)

	if getline('$') == ''
		silent $d
	endif

	normal! gg

endfunction

" }}}
" VUT_Update: update template area preserving changes in Editable {{{
" Description: Save editable areas to variables/registers/temporary
" 		files, remove file, checkout template, paste editables into
" 		proper places.
function! VUT_Update(tmplname)

	" Check the most important thing about templates: is a storage place
	" for them?
	let vutlevel = VUT_GetMainFileName(":p:h")
	if isdirectory(vutlevel.'/Templates/') != 0
		let vutdir = vutlevel.'/Templates/'
	else
		echomsg "VUT: Templates directory doesn't exist. Create it!"
		return
	endif

	" Check if all regions are safely declared
	let vutcheck = VUT_Check()
	if vutcheck != 'Did not detect anything wrong.'
		echo vutcheck
		return
	endif

	let sline = line('.')
	let cpos = line(".") . " | normal!" . virtcol(".") . "|"

	let z_rez = @z

	normal! gg

	while search(VUT_Ebcom().'\s*#BeginEditable .*'.VUT_Eecom(), 'W')
		let regname = matchstr(getline('.'), VUT_Ebcom().'\s*#BeginEditable\s*"\zs.\{-}\ze"')
		if getline(line('.')+1) !~ VUT_Ebcom().'\s*#EndEditable ' 
			exe ':silent .+1,/'.VUT_Ebcom().'\s*#EndEditable /-1 y z'
		else
			continue
		endif
		let b:vut_{regname} = @z

	endwhile

	silent normal! gg"_dG

	call VUT_Checkout(a:tmplname)

	while search(VUT_Ebcom().'\s*#BeginEditable .*'.VUT_Eecom(), 'W')
		let regname = matchstr(getline('.'), VUT_Ebcom().'\s*#BeginEditable\s*"\zs.\{-}\ze"')
		if exists("b:vut_".regname)
			let @z = b:vut_{regname}
			silent put z
		endif

	endwhile

	let @z = z_rez

	if getline('$') == ''
		silent $d
	endif

	silent exe cpos

endfunction
" }}}
" VUT_Strip: remove current/last/all editable areas tags from file {{{
" Description: Go to last opening tag, s/// it, go to the first closing
"              tag, s/// it and return to start position.
"              Use s/// and not g// to preserve line numbering
function! VUT_Strip(all)

	let cpos = line(".") . " | normal!" . virtcol(".") . "|"

	if a:all == ''
		normal! j

		if search(VUT_Ebcom().'\s*#BeginEditable .*'.VUT_Eecom(), 'bW')
			exe 'silent! s/'.VUT_Ebcom().'\s*#BeginEditable.\{-}'.VUT_Eecom().'//e'
			call search(VUT_Ebcom().'\s*#EndEditable ', 'W')
			exe 'silent! %s/'.VUT_Ebcom().'\s*#EndEditable.\{-}'.VUT_Eecom().'//e'
			silent! exe cpos
			return

		else
			echo "Could't find editable region, exit."
			silent! exe cpos
			return

		endif
		
	elseif a:all == 'all'
		exe 'silent! s/'.VUT_Ebcom().'\s*#BeginEditable.\{-}'.VUT_Eecom().'//ge'
		exe 'silent! %s/'.VUT_Ebcom().'\s*#EndEditable.\{-}'.VUT_Eecom().'//ge'

	else
		echo "Argument not supported, exit."

	endif

	silent! exe cpos
	return

endfunction
" }}}
" VUT_Insert: insert template of editable region {{{
" Description: 
function! VUT_Insert(name)

	if a:name == '' || !exists("a:name")
		let name = ''

	else
		if a:name =~ '^[A-Za-z_][A-Za-z0-9_]*'
			let name = a:name
		else
			echo "Declared region name contains illegal characters, check help for details"
			return
		endif

	endif

	let beginline = b:vut_bcom.' #BeginEditable "'.name.'" '.b:vut_ecom
	let endline = b:vut_bcom.' #EndEditable '.b:vut_ecom

	put =beginline
	put =endline

	normal! k

	return

endfunction
" }}}

" VUL_Commit: commit current/last library to repository {{{
" Description: Find last BeginLibraryItem and put whole area between
" tags to file described in argument of start tag
function! VUL_Commit(libitem)

	let vullevel = VUT_GetMainFileName(":p:h")

	" Save current position
	let sline = line('.')
	let cpos = line(".") . " | normal!" . virtcol(".") . "|"

	if a:libitem == 'all'
		normal! gg
	    while search(VUT_Ebcom().'\s*#BeginLibraryItem ', 'W')
			call VUL_Commit('')
		endwhile
		silent exe cpos
		return
	endif


	" If we start on BeginLibraryItem make sure to include it
	normal! j

	let line = search(VUT_Ebcom().'\s*#BeginLibraryItem ', 'bW')

	if line == 0
		silent exe cpos
		return
	endif

	let curd = getcwd()
	let filedir = expand('%:p:h')
	" change to dir where is file to get proper extension of relative
	" filenames
	call VUT_CD(filedir)

	let z_rez = @z
	let @z = ''

	let libname = matchstr(getline('.'), VUT_Ebcom().'\s*#BeginLibraryItem\s*"\zs.\{-}\ze"')

	" Add extension to library name if user forgot about that
	if libname !~ '\.vhl'
		"call substitute(getline('.'), libname, libname.'\.vhl', '')
		silent! exe 's+BeginLibraryItem\s*"'.libname.'+\0\.vhl+e'
		let libname = libname.'.vhl'
		echo "Don't forget to add .vhl extension to Library Item name!"
	endif

	if libname[0] == '~'
		let vulfile = fnamemodify(libname, ':p')
	elseif libname[0] !~ '[\/]'
		let vulfile = vullevel.'/'.libname
	else
		let vulfile = vullevel.libname
	endif

	silent normal! j

	while getline('.') !~ VUT_Ebcom().'\s*#EndLibraryItem '

		" Check if in line are links, when positive expand them to full
		" paths
		let curline = VUT_ExpandLinks(getline('.'))

		" Prevent inserting blank line at the beginning
		if @z == ''
			let @z = curline
		else
			let @z = @z."\n".curline
		endif

		silent normal! j

	endwhile

	if filewritable(vulfile) == 0
		" Hmm. Maybe this is new Lib?
		if filewritable(fnamemodify(vulfile, ":p:h")) == 2
			" OK. Directory exists, just file isn't there. Proceed.
			exe 'silent below 1split '.vulfile
			silent put! z
			silent $d
			silent write!
			exe 'bwipe '.vulfile

		else
			" Something is wrong with pathname. Abort! Abort! Abort!
			echomsg "VHL: Can't write to or create Library with this path."

		endif

	else
		" Library already exist, we need to update its contents with @z
		let g:lfile = vulfile
		exe 'silent below 1split '.vulfile
		silent normal! gg"_dG
		silent put! z
		silent $d
		silent write!
		exe 'bwipe '.vulfile

	endif

	let @z = z_rez

	call VUT_CD(curd)

	silent exe cpos

endfunction
"
" }}}
" VUL_Update: update contents of current/last library in file. {{{
" Description: Find last BeginLibraryItem and update area between tags
" tags to file described in argument of start tag
function! VUL_Update(libitem)

	let vullevel = VUT_GetMainFileName(":p:h")

	" Save current position
	let sline = line('.')
	let cpos = line(".") . " | normal!" . virtcol(".") . "|"

	if a:libitem == 'all'
		normal! gg
	    while search(VUT_Ebcom().'\s*#BeginLibraryItem ', 'W')
			call VUL_Update('')
		endwhile
		silent exe cpos
		return
	elseif a:libitem =~ '\.vhl$'
		normal! gg
	    if search(VUT_Ebcom().'\s*#BeginLibraryItem "'.a:libitem, 'W')
			call VUL_Update('')
		endif
		silent exe cpos
		return
	endif

	" If we start on BeginLibraryItem make sure to include it
	normal! j

	let curd = getcwd()
	let filedir = expand('%:p:h')
	" change to dir where is file to get proper extension of relative
	" filenames
	call VUT_CD(filedir)

	" First we have to find if LibItem exists.
	let line = search(VUT_Ebcom().'\s*#BeginLibraryItem ', 'bW')

	" End if there is no LibItem above
	if line == 0
		silent exe cpos
		return
	endif

	let libname = matchstr(getline('.'), VUT_Ebcom().'\s*#BeginLibraryItem\s*"\zs.\{-}\ze"')
	if libname !~ '^[\/]'
		let libname = '/'.libname
	endif

	let vulfile = vullevel.libname

	if filewritable(vulfile) == 0
		" Something is wrong with pathname. Abort now!
		call VUT_CD(curd)
		silent exe cpos
		echomsg "VHL: Can't find this Library - check path."

		return

	endif

	" When we know LibItem exists we can remove current lib.
	if getline(line('.')+1) !~ VUT_Ebcom().'\s*#EndLibraryItem ' 
		exe 'silent .+1,/'.VUT_Ebcom().'\s*#EndLibraryItem /-1 d _'
	endif
	" Make sure we are back at the line with BeginLibraryItem
	exe line
	exe 'silent read '.vulfile

	" Change links in Library from full to relative
	while getline('.') !~ VUT_Ebcom().'\s*#EndLibraryItem '
		call VUT_CollapseLinks(getline('.'))
		normal! j

	endwhile

	call VUT_CD(curd)
	silent exe cpos

endfunction
"
" }}}
" VUL_Checkout: put at cursor position contents of library {{{
" Description: Find Library and put chosen snippet into cursor position
" 	(with links parsing)
function! VUL_Checkout(libitem)
	let vullevel = VUT_GetMainFileName(":p:h")
	" need to create local variable independent of buffor
	let bcom = b:vut_bcom
	let ecom = b:vut_ecom

	let sline = line('.')
	let cpos = line(".") . " | normal!" . virtcol(".") . "|"

	" Put contents of @z to template file. Find .vutmain to check where
	" Templates is dir for them - following Dreamweaver.
	" Let check if argument exists or name of template was previously
	" set. This will enable use of multiply templates in one project. 
	if a:libitem != ''

		let vulname = a:libitem

		if a:libitem[0] == '~'
			let vulfile = fnamemodify(a:libitem, ':p')

		elseif a:libitem[0] != '/'
			let vulfile = vullevel.'/'.a:libitem

		endif

	else
		let vulname = input("You didn't specify Library path.\n".
				   \   "Enter path to existing library -\n".
				   \   VUT_ListFiles(vullevel, 'vhl').
				   \   "\n(<Enter> to abandon action): ")

		if vulname != ''
			let vulfile = vullevel.'/'.vulname

		else
			return

		endif

	endif

	if filereadable(vulfile) != 1
		echomsg "VUL: Not correct path to Library. Try Again!"
		exe sline
		silent exe cpos
		return

	else
		exe 'silent below 1split '.vulfile
		let z_rez = @z
		silent normal! gg"zyG
		let @z = bcom.' #BeginLibraryItem "'.vulname.'" '.ecom."\n".@z."\n".
			\    bcom.' #EndLibraryItem '.ecom
		exe 'bwipe '.vulfile
		exe sline
		silent put z
		let @z = z_rez

	endif

	let curd = getcwd()
	let filedir = expand('%:p:h')
	" change to dir where is file to get proper extension of relative
	" filenames
	call VUT_CD(filedir)

	" Make sure we are back at the beginning of Library content
	exe sline + 1

	" Change links in Library from full to relative
	while getline('.') !~ VUT_Ebcom().'\s*#EndLibraryItem '
		call VUT_CollapseLinks(getline('.'))
		normal! j

	endwhile

	call VUT_CD(curd)
	silent exe cpos

endfunction
"
" }}}
" VUL_Strip: remove current/last/all library tags from file {{{
" Description: Go to last opening tag, s/// it, go to the first closing
"              tag, s/// it and return to start position.
"              Use s/// and not g// to preserve line numbering
function! VUL_Strip(all)

	let cpos = line(".") . " | normal!" . virtcol(".") . "|"

	if a:all == ''
		normal! j

		if search(VUT_Ebcom().'\s*#BeginLibraryItem .*'.VUT_Eecom(), 'bW')
			exe 'silent! s/'.VUT_Ebcom().'\s*#BeginLibraryItem.\{-}'.VUT_Eecom().'//e'
			call search(VUT_Ebcom().'\s*#EndLibraryItem ', 'W')
			exe 'silent! %s/'.VUT_Ebcom().'\s*#EndLibraryItem.\{-}'.VUT_Eecom().'//e'
			silent! exe cpos
			return

		else
			echo "Could't find library item, exit."
			silent! exe cpos
			return

		endif
		
	elseif a:all == 'all'
		exe 'silent! s/'.VUT_Ebcom().'\s*#BeginLibraryItem.\{-}'.VUT_Eecom().'//ge'
		exe 'silent! %s/'.VUT_Ebcom().'\s*#EndLibraryItem.\{-}'.VUT_Eecom().'//ge'

	else
		echo "Argument not supported, exit."

	endif

	silent! exe cpos
	return

endfunction
" }}}
" VUL_Insert: insert template of editable region {{{
" Description: 
function! VUL_Insert(name)

	if a:name != '' && a:name !~ '\.vhl$'
		let name = a:name.'.vhl'

	else
		let name = a:name

	endif

	let beginline = b:vut_bcom.' #BeginLibraryItem "'.name.'" '.b:vut_ecom
	let endline = b:vut_bcom.' #EndLibraryItem '.b:vut_ecom

	put =beginline
	put =endline

	normal! k

	return

endfunction
" }}}

" VUT_Show: Show templates/libraries available in project {{{
" Description: Find files through ListFiles function depending on
" profile
function! VUT_Show(profile)

	let projname = VUT_GetMainFileName(":p:h")

	if a:profile == 'templates'

		" Check if Templates directory exists
		let vutlevel = VUT_GetMainFileName(":p:h")
		if isdirectory(vutlevel.'/Templates/') != 0
			let vutdir = vutlevel.'/Templates/'
		else
			echomsg "VUT: Templates directory doesn't exist. Create it!"
			return
		endif

		" Check if current file has template assigned
		if exists("b:vutemplate")
			let curtmpl = b:vutemplate
		else
			let curtmpl = 'NONE'
		endif

		echo 'Current template: '.curtmpl."\n".
		   \ 'Templates available in project '.projname." :\n".
		   \ VUT_ListFiles(vutdir, 'vht')

	elseif a:profile == 'libraries'

		let vullevel = VUT_GetMainFileName(":p:h")

		echo "Libraries available in project ".projname." :\n".
			  \ VUT_ListFiles(vullevel, 'vhl')

	endif

endfunction

" }}}

" VUT_Check: check if templates were properly declared {{{
" Description: Go through the file and check if tags around editable
"              regions match rigid regexps.
function! VUT_Check()

	" Save position
	let cpos = line(".") . " | normal!" . virtcol(".") . "|"

	normal! gg

	let badline = ''

	while search(VUT_Ebcom().'\s*#BeginEditable.*'.VUT_Ebcom(), 'W')
		if getline('.') !~ '^\s*'.VUT_Ebcom().'\s*#BeginEditable\s\+"[A-Za-z_][A-Za-z0-9_]*"\s*'.VUT_Eecom().'\s*$'
			let badline = badline." ".line('.').":    ".getline('.')."\n"
		endif
	endwhile

	normal! gg

	while search(VUT_Ebcom().'\s*#EndEditable.*'.VUT_Eecom(), 'W')
		if getline('.') !~ '^\s*'.VUT_Ebcom().'\s*#EndEditable\s*'.VUT_Eecom().'\s*$'
			let badline = badline." ".line('.').":    ".getline('.')."\n"
		endif
	endwhile

	silent exe cpos

	let g:badl = badline

	if badline != ''
		return "Not all editable regions were safely declared. List of them:\n"
					\ .badline."End of operation."
	else
		return 'Did not detect anything wrong.'

	endif

endfunction

" }}}
" ======================================================================
" Support for taglist.vim
" ======================================================================
" Sets Tlist_Ctags_Cmd for taglist.vim and regexps for ctags {{{
if !exists("g:tlist_html_settings") 
	let g:tlist_html_settings = 'html;a:Anchors;e:Editable regions;l:Libraries'
endif

if exists("Tlist_Ctags_Cmd")
	let s:html_ctags = g:Tlist_Ctags_Cmd
else
	let s:html_ctags = 'ctags' " Configurable?
endif

if exists("Tlist_Ctags_Cmd") && g:Tlist_Ctags_Cmd !~ '#BeginEditable' || !exists("Tlist_Ctags_Cmd")
	let g:Tlist_Ctags_Cmd = s:html_ctags .' --langdef=html --langmap=html:.html.htm'
	\.' --regex-html="/ #BeginEditable \"([A-Za-z_][A-Za-z0-9_]*)\"/\1/e,editable/"'
	\.' --regex-html="/ #BeginLibraryItem \"([^\"]*)\"/\1/l,library/"'
endif

" }}}
" ======================================================================
" Auxiliary functions
" ======================================================================
" VUT_ListFiles: give list of templates or libraries {{{
" Description: cd to template/library dir and get list of files, remove
" extensions
function! VUT_ListFiles(vutdir, ext)
	let curd = getcwd()
	call VUT_CD(a:vutdir)
	if a:ext == 'vht'
		let filelist = glob("*")
		let filelist = substitute(filelist, '\.vht', '', 'ge')
	elseif a:ext == 'vhl'
		let filelist = globpath(".,Library,$HOME/Library/", '*.\(vhl\|lbi\)')
		let filelist = substitute(filelist, '\(^\|\n\)\..', '\1', 'ge')
	endif
	call VUT_CD(curd)
	return filelist
endfunction

" }}}
" VUT_CollapseLinks: Change full paths of links to relative {{{
" Description: go through read file up to End LibraryItem and change
" links
function! VUT_CollapseLinks(line)
	" Update links in read file - up to EndLibraryItem
	if a:line =~? '\(\(href\|src\|location\)\s*=\|\(window\.open\|url\)(\)'
		if a:line =~? '\(window\.open\|url\)('
			let link = matchstr(a:line, "\\(window\\.open\\|url\\)(\\('\\|\"\\)\\?\\zs.\\{-}\\ze\\2)")
		else
			let link = matchstr(a:line, "\\(href\\|src\\|location\\)\\s\*=\\s\*\\('\\|\"\\)\\zs.\\{-}\\ze\\2")
		endif
		" Check for protocols and # or filereadable() is enough?
		if !filereadable(link)
			return
		endif
		let rellink = VUT_RelPath(link, expand('%:p'))
		" What chars should be escaped?
		let esclink = escape(link, ' \.?')
		let escrellink = escape(rellink, ' \.?')
		" Should changing of paths be 'g'lobal or not?
		exe 'silent s+'.esclink.'+'.escrellink.'+e'
	endif

endfunction

" }}}
" VUT_ExpandLinks: Change names in links from relative to full path {{{
" Description: take line and change names if necessary
function! VUT_ExpandLinks(line)

	let line = a:line

	if line =~? '\(\(href\|src\|location\)\s*=\|\(window\.open\|url\)(\)'
		if line =~? '\(window\.open\|url\)('
			let link = matchstr(line, "\\(window\\.open\\|url\\)(\\('\\|\"\\)\\?\\zs.\\{-}\\ze\\2)")
		else
			let link = matchstr(line, "\\(href\\|src\\|location\\)\\s\*=\\s\*\\('\\|\"\\)\\zs.\\{-}\\ze\\2")
		endif
		if !filereadable(link)
			return line
		endif
		let fulllink = fnamemodify(link, ':p')
		" What chars should be escaped?
		let esclink = escape(link, ' \.?')
		let escfulllink = escape(fulllink, ' \.?')
		let line = substitute(line, link, escfulllink, 'e')
	endif

	return line

endfunction

" }}}
" VUT_Ebcom: Escape special chars in opening comment string {{{
" Description: use escape() function
function! VUT_Ebcom()
	let esc = escape(b:vut_bcom, '/*')
	return esc
endfunction
" }}}
" VUT_Eecom: Escape special chars in closing comment string {{{
" Description: use escape() function
function! VUT_Eecom()
	let esc = escape(b:vut_ecom, '/*')
	return esc
endfunction
" }}}
" ----------------------------------------------------------------------
" These functions (with cosmetic changes) are coming from vim-latexSuite
" project - http://vim-latex.sourceforge.net
" VUT_GetMainFileName: gets the name of the root html file. {{{
" Description:  returns the full path name of the main file.
"               This function checks for the existence of a .vutmain file
"               which might point to the location of a "main" html file.
"               If .vutmain exists, then return the full path name of the
"               file being pointed to by it.
"
"               Otherwise, return the full path name of the current buffer.
"
"               You can supply an optional "modifier" argument to the
"               function, which will optionally modify the file name before
"               returning.
"               NOTE: From version 1.6 onwards, this function always trims
"               away the .vutmain part of the file name before applying the
"               modifier argument.
function! VUT_GetMainFileName(...)
	if a:0 > 0
		let modifier = a:1
	else
		let modifier = ':p'
	endif

	" If the user wants to use his own way to specify the main file name, then
	" use it straight away.
	if VUT_GetVarValue('VUT_MainFileExpression', '') != ''
		exec 'let retval = '.VUT_GetVarValue('VUT_MainFileExpression', '')
		return retval
	endif

	let curd = getcwd()

	let dirmodifier = '%:p:h'
	let dirLast = expand(dirmodifier)
	call VUT_CD(dirLast)

	" move up the directory tree until we find a .vutmain file.
	" TODO: Should we be doing this recursion by default, or should there be a
	"       setting?
	while glob('*.vutmain') == ''
		let dirmodifier = dirmodifier.':h'
		" break from the loop if we cannot go up any further.
		if expand(dirmodifier) == dirLast
			break
		endif
		let dirLast = expand(dirmodifier)
		call VUT_CD(dirLast)
	endwhile

	let lheadfile = glob('*.vutmain')
	if lheadfile != ''
		" Remove the trailing .vutmain part of the filename... We never want
		" that.
		let lheadfile = fnamemodify(substitute(lheadfile, '\.vutmain$', '', ''), modifier)
	else
		" If we cannot find any main file, just modify the filename of the
		" current buffer.
		let lheadfile = expand('%'.modifier)
	endif

	call VUT_CD(curd)

	" NOTE: The caller of this function needs to escape spaces in the
	"       file name as appropriate. The reason its not done here is that
	"       escaping spaces is not safe if this file is to be used as part of
	"       an external command on certain platforms.
	return lheadfile
endfunction 
" }}}
" VUT_CD: cds to given directory escaping spaces if necessary {{{
" Description: 
function! VUT_CD(dirname)
	exec 'cd '.VUT_EscapeSpaces(a:dirname)
endfunction " }}}
" VUT_EscapeSpaces: escapes unescaped spaces from a path name {{{
" Description:
function! VUT_EscapeSpaces(path)
	return substitute(a:path, '[^\\]\(\\\\\)*\zs ', '\\ ', 'g')
endfunction " }}}
" VUT_GetVarValue: gets the value of the variable {{{
" Description: 
" 	See if a window-local, buffer-local or global variable with the given name
" 	exists and if so, returns the corresponding value. Otherwise return the
" 	provided default value.
function! VUT_GetVarValue(varname, default)
	if exists('w:'.a:varname)
		return w:{a:varname}
	elseif exists('b:'.a:varname)
		return b:{a:varname}
	elseif exists('g:'.a:varname)
		return g:{a:varname}
	else
		return a:default
	endif
endfunction " }}}
" VUT_Common: common part of strings {{{
function! s:VUT_Common(path1, path2)
	" Assume the caller handles 'ignorecase'
	if a:path1 == a:path2
		return a:path1
	endif
	let n = 0
	while a:path1[n] == a:path2[n]
		let n = n+1
	endwhile
	return strpart(a:path1, 0, n)
endfunction " }}}
" VUT_NormalizePath:  {{{
" Description: 
function! VUT_NormalizePath(path)
	let retpath = a:path
	if has("win32") || has("win16") || has("dos32") || has("dos16")
		let retpath = substitute(retpath, '\\', '/', 'ge')
	endif
	if isdirectory(retpath) && retpath !~ '/$'
		let retpath = retpath.'/'
	endif
	return retpath
endfunction " }}}
" VUT_RelPath: ultimate file name {{{
function! VUT_RelPath(explfilename,texfilename)
	let path1 = VUT_NormalizePath(a:explfilename)
	let path2 = VUT_NormalizePath(a:texfilename)

	let n = matchend(<SID>VUT_Common(path1, path2), '.*/')
	let path1 = strpart(path1, n)
	let path2 = strpart(path2, n)
	if path2 !~ '/'
		let subrelpath = ''
	else
		let subrelpath = substitute(path2, '[^/]\{-}/', '../', 'ge')
		let subrelpath = substitute(subrelpath, '[^/]*$', '', 'ge')
	endif
	let relpath = subrelpath.path1
	return escape(VUT_NormalizePath(relpath), ' ')
endfunction " }}}

" vim:fdm=marker:ff=unix:noet:ts=4:sw=4:nowrap
