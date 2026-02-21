package odwm

borderpx  :: 1         /* border pixel of windows */
snap      :: 32        /* snap pixel */
showbar   :: 1         /* 0 means no bar*/
topbar    :: 0         /* 0 means bootom bar */
fonts     :: []cstring{"monospace:size=10"}
dmenufont :: "monospace:size=10"
col_gray1 :: "#222222"
col_gray2 :: "#444444"
col_gray3 :: "#bbbbbb"
col_gray4 :: "#eeeeee"
col_cyan  :: "#005577"
colors    :: [][]cstring{
	/*fg         bg         border   */
	{ col_gray3, col_gray1, col_gray2 },
	{ col_gray4, col_cyan,  col_cyan  },
}

/* tagging */
tags :: []cstring{ "1", "2", "3", "4", "5", "6", "7", "8", "9" }

/* layouts */
mfact          :: 0.70 /* factor of master area size [0.05..0.95] */
nmaster        :: 1    /* number of clients in master area */
resizehints    :: 1    /* 1 means respect size hints in tiled resizals */
lockfullscreen :: 1    /* 1 will force focus on the fullscreen window */
refreshrate    :: 120  /* refresh rate (per second) for client move/resize */

layouts :: []Layout{
	{"[]=", tile_proc},
	{"><>", nil},
	{"[M]", monocle_proc},
}
