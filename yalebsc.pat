PAT META 0 1.0
#############################################################################
# Yale Bright Star Catalog
##
name		Yale Bright Star Catalog|BS|YBS

# 0D details
##
points		9010
fields		8
color		spectral spectral_type, magnitude
scale		((6 - magnitude) / 2)
symbol		(type = "SS"), solid circle, (type = "SD"), circle, \
		(type = "SV"), box

# Fields description
#
#	field name	p  w  storage   type     units    format    flags
#       ---------------------------------------------------------------------
field	ra		0  6  double	ra       hour     hhmmss    longitude
field	declination	0  5  double	decl     dd       sddmm     latitude
field	magnitude	0  3  double	vismag   none     mag3      0
field	type		0  2  string	string   none     string    0
field	spectral_type	0  2  ub2	spectral none     spectral  null-ok
field	letter		0  2  string	string   none     string    null-ok
field	constellation	0  3  string	string   none     string    null-ok
field	name		0  0  string	string   none     string    null-ok
