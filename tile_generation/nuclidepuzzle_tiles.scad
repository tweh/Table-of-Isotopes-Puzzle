// NUCLIDE PUZZLE - TILE GENERATOR
// This OpenSCAD file used the plain tiles STL generated with onshape
// to automatically add the text.


// OpenSCAD variable as switches for different styles/variants of tiles
showDecaysText = true;
markSecondDecay = false;

// onshape variables for information about the isotope
ElementSymbol = "Bi";
ElementMass = "212";
ElementProtons = "83";
ElementDecays = "α, β-";

// OpenSCAD variables for information about the isotope
alphaDecay = false;
betaMinusDecay = true;
betaPlusDecay = true;

// onshape variables for geometry etc.
// use the same values as set in onshape
LayerHeight = 0.15;
DecayFrameWidth = 5;
DecayFrameSep = 1;
DecayFrameBorder = 5;
SecondDecayHeight = 2*LayerHeight;
TileSize = 38;
TextHeight = 2*LayerHeight;
FontSizeSymbol = 0.13*TileSize;
FontSizeNumbers = 0.12*TileSize;
FontSizeDecays = FontSizeNumbers;

// additional OpenSCAD variables
fontQuality = 25;
fontAlignFrameBase = -TileSize/2 + DecayFrameBorder/2 + DecayFrameWidth + DecayFrameSep;
fontAlignSymbolBase = 0.3*TileSize;
fontAlignSymbolBaseWithoutDecays = 0.23*TileSize;
actualTextHeight = markSecondDecay ? SecondDecayHeight+TextHeight : TextHeight;
textWidthSymbol = textmetrics(
		ElementSymbol,
		font = "Sofia Sans:style=Bold",
		size = FontSizeSymbol,
		valign = "baseline",
		halign = "left",
		$fn = fontQuality,
	).size.x;
textWidthProtons =  textmetrics(
		ElementProtons,
		font = "Sofia Sans:style=Bold",
		size = FontSizeNumbers,
		valign = "top",
		halign = "right",
		$fn = fontQuality,
	).size.x;
textWidthMass = textmetrics(
		ElementMass,
		font = "Sofia Sans:style=Bold",
		size = FontSizeNumbers,
		valign = "baseline",
		halign = "right",
		$fn = fontQuality,
	).size.x;
textShiftX = (max(textWidthProtons,textWidthMass) - textWidthSymbol)/2;

// create the tile with decay holes
difference() {	
	// import plain tile as base
	color([0.5,0.7,0.7]) // change text color for better visibility of text
	if (markSecondDecay) {
		import("stl_to_import/tile_plain_with2nd.stl");
	} else {
		import("stl_to_import/tile_plain.stl");
	}
	
	// add the decay plug holes
	if (alphaDecay) {
		import("stl_to_import/decay_holes_alpha.stl");
	}
	if (betaMinusDecay) {
		import("stl_to_import/decay_holes_betaminus.stl");
	}
	if (betaPlusDecay) {
		import("stl_to_import/decay_holes_betaplus.stl");
	}
	
}

// add the text
// change the base line for font alignment to lower edge of text area
translate([0, fontAlignFrameBase, 0])
// set same extrusion hight for all text elements
linear_extrude(height = actualTextHeight) {

	// add element symbol
	// if the decays are not printed the symbol can be lowered
	translate([textShiftX,showDecaysText ? fontAlignSymbolBase : fontAlignSymbolBaseWithoutDecays,0])
	text(
		ElementSymbol,
		font = "Sofia Sans:style=Bold",
		size = FontSizeSymbol,
		valign = "baseline",
		halign = "left",
		$fn = fontQuality,
	);
	
	// shift to horizontal mid of symbol to align numbers
		// if the decays are not printed the numbers can be lowered
	translate([0,showDecaysText ? fontAlignSymbolBase : fontAlignSymbolBaseWithoutDecays,0])
	translate([0,FontSizeSymbol/2,0]) {
	
		// add element mass
		translate([textShiftX,0.05*TileSize/2,0])
		text(
			ElementMass,
			font = "Sofia Sans:style=Bold",
			size = FontSizeNumbers,
			valign = "baseline",
			halign = "right",
			$fn = fontQuality,
		);

		// add element protons
		translate([textShiftX,-0.05*TileSize/2,0])
		text(
			ElementProtons,
			font = "Sofia Sans:style=Bold",
			size = FontSizeNumbers,
			valign = "top",
			halign = "right",
			$fn = fontQuality,
		);
		
	}

	// add decays
	if (showDecaysText) {// to be changed later
		translate([0,0.06*TileSize,0])
		text(
			ElementDecays,
			font = "Rounded Mplus 1c Bold:style=Bold",
			size = FontSizeDecays,
			valign = "baseline",
			halign = "center",
			$fn = fontQuality,
		);
	}

}