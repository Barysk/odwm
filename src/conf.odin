package odwm

fonts :: []cstring{"serif", "monospace"}

mfact   :: 0.70
nmaster :: 1
showbar :: 1
topbar  :: 0

layouts := []Layout{
	{"[]=", tile_proc},
	{"><>", nil},
	{"[M]", monocle_proc},
}
