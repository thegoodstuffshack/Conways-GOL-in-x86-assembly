GAME CHANGE - code wrap-around borders
ISSUE (RESOLVED) - adjusting frame size works however grid is incompatible with different values for width
		  - without losing the configured pattern in the grid
		  - frame_width cannot be adjusted
LIMITATION	- current code uses video memory as the grid to read from
				- adding a 'world' outside of it is currently not possible
	SOLUTION - use another grid


Speed increases are relative to previous version, optimizations with effects are in implementation order 
with each optimisation representing a new version - tested using default qemu with resolution 320x31
measuring the time it takes for a c/2 glider (64P2H1V0) to travel 312 units (624 generations)
take results with a grain of salt as modifications are made that arent listed
OPTIMISATION - shorten functions called more often than others
				- i.e. lengthen less used functions, e.g. keep es set
				- es -> video_memory_address, bx -> 0
IMPLEMENTED -> EFFECT = 28% increase in speed
OPTIMISATION - use lea for math (along with cleaning code (major part))
				- also rearranged parts of code to reduce jumping
IMPLEMENTED -> EFFECT = 55% increase in speed
OPTIMISATION - saving memory with functions increases compute time -> integrate functions
				- not reusing code will make it faster, bake EVERYTHING
				- somewhat implemented, havent done get_bit_state yet
				  as it would be a bit extreme (for now)
Half IMPLEMENTED -> EFFECT = 61% increase in speed

OPTIMISATION - use register for storing neighbour count
IMPLEMENTED -> EFFECT = 88.5% increase in speed
OPTIMISATION - replace the rep movs when refreshing screen
IMPLEMENTED -> EFFECT = no effect on speed, however can now use different values for frame_width

OPTIMISATION - only check cells in each iteration that either changed or had neighbours that changed
OPTIMISATION - use lookup tables 
OPTIMISATION - conditional checking of neighbours to prevent same byte grab