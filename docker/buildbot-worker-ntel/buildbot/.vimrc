"compatible     behave very Vi compatible (not advisable)
"       set nocp        cp
set nocp

"wrapscan       search commands wrap around the end of the buffer
"       set ws  nows
set wrapscan

"incsearch      show match for partly typed search command
"       set nois        is
set incsearch

"wrap   long lines wrap
"       set wrap        nowrap
set nowrap

"number show the line number for each line
"       (local to window)
"       set nonu        nu
set nu

"background     "dark" or "light"; the background color brightness
"       set bg=light
set bg=dark

"filetype       type of file; triggers the FileType event when set
"       (local to buffer)
"       set ft=vim
filetype plugin indent on

"syntax name of syntax highlighting used
"       (local to buffer)
"       set syn=vim
syntax on

"hlsearch       highlight all matches for the last used search pattern
"       set nohls       hls
set hls

"cursorline     highlight the screen line of the cursor
"       (local to window)
"       set nocul       cul
set cursorline

"showcmd        show (partial) command keys in the status line
"       set nosc        sc
set showcmd

"showmode       display the current mode in the status line
"       set smd nosmd
set showmode

"ruler  show cursor position below each window
"       set ru  noru
set ruler

"backspace      specifies what <BS>, CTRL-W, etc. can do in Insert mode
"       set bs=indent,eol,start
set backspace=indent,eol,start

"tabstop        number of spaces a <Tab> in the text stands for
"       (local to buffer)
"       set ts=8
set ts=8

"shiftwidth     number of spaces used for each step of (auto)indent
"       (local to buffer)
"       set sw=8
set sw=4

"smarttab       a <Tab> in an indent inserts 'shiftwidth' spaces
"       set nosta       sta
set smarttab

"softtabstop    if non-zero, number of spaces to insert for a <Tab>
"       (local to buffer)
"       set sts=0
set softtabstop=-1

"shiftround     round to 'shiftwidth' for "<<" and ">>"
"       set nosr        sr
set shiftround

"expandtab      expand <Tab> to spaces in Insert mode
"       (local to buffer)
"       set noet        et
set expandtab

"autoindent     automatically set the indent of a new line
"       (local to buffer)
"       set noai        ai
set autoindent

"smartindent    do clever autoindenting
"       (local to buffer)
"       set nosi        si
set smartindent

"fileformats    list of file formats to look for when editing a file
"       set ffs=unix,dos
set fileformats=unix,dos

"backup keep a backup after overwriting a file
"       set nobk        bk
set nobackup

"Key Maps
map! <S-Insert> <C-r>+
