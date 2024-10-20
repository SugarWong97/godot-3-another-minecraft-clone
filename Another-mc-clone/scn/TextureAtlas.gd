#Set PADDING to 0 if you want to see what the purpose of this code is. It's all to fix mipmap bleeding.
extends Node
onready var oWorldGen = get_node(Nodelist.oWorldGen)

const ATLAS_SIZE_X = 4
const ATLAS_SIZE_Y = 4
const TEXTURE_WIDTH = 24
const TEXTURE_HEIGHT = 24
const PADDING = 24 #sometimes 16 isn't enough, depending on the computer

var textureArray = [
	preload("res://tex/sidegrass.png"),
	preload("res://tex/grasstop.png"),
	preload("res://tex/dirt.png"),
	preload("res://tex/stone.png"),
	preload("res://tex/orange.png"),
	preload("res://tex/blue.png"),
]

#blockFaces numbers: refers to array index in textureFiles array.
#blockFaces array index: must match those defined in WorldGen.
var blockFaces = [
	[], #EMPTY
	[0,0,0,0,1,2], #GRASS - sides are sidegrass.png, top side is grasstop.png, bottom is dirt.png
	[2,2,2,2,2,2], #DIRT
	[3,3,3,3,3,3], #STONE
]

var texUV = []
func _ready():
	var atlasItemsCount = textureArray.size()
	var imageData = Image.new()
	imageData.create((TEXTURE_WIDTH+PADDING)*ATLAS_SIZE_X, (TEXTURE_HEIGHT+PADDING)*ATLAS_SIZE_Y, false, Image.FORMAT_RGBA8) #Set compress mode Lossless. Imported Images NEED to exactly match this format for this to work,
	placeTextures(imageData,atlasItemsCount)
	UVs(atlasItemsCount)
	finalize(imageData)

func placeTextures(imageData,atlasItemsCount):
	var i = 0
	var destination	
	for y in ATLAS_SIZE_Y:
		for x in ATLAS_SIZE_X:
			if i >= atlasItemsCount:
				return
			var tex = textureArray[i].get_data()
			destination = Vector2(x*(TEXTURE_WIDTH+PADDING), y*(TEXTURE_HEIGHT+PADDING)) + Vector2(PADDING*0.5,PADDING*0.5)
			imageData.blit_rect(tex, Rect2(0,0,TEXTURE_WIDTH,TEXTURE_HEIGHT), destination)
			i += 1

func finalize(imageData):
	imageData.generate_mipmaps() # Important
	imageData.fix_alpha_edges() # Fixes some seams. Do after generate_mipmaps().
	var finalTexture = ImageTexture.new()
	finalTexture.create_from_image(imageData,ImageTexture.FLAG_MIPMAPS) #+ImageTexture.FLAG_ANISOTROPIC_FILTER) #set to 0 to remove all flags
	oWorldGen.TERRAIN_MAT.set_shader_param('texture_albedo', finalTexture)

func UVs(atlasItemsCount):
	texUV.resize(atlasItemsCount)
	var sepX = (1.0/ATLAS_SIZE_X)
	var sepY = (1.0/ATLAS_SIZE_Y)
	var padPixelX = 0
	var padPixelY = 0
	if PADDING > 0:
		padPixelX = 1.0 / ((ATLAS_SIZE_X*(TEXTURE_WIDTH+PADDING)) / (PADDING * 0.5))
		padPixelY = 1.0 / ((ATLAS_SIZE_Y*(TEXTURE_HEIGHT+PADDING)) / (PADDING * 0.5))
	var i = 0
	for y in ATLAS_SIZE_Y:
		for x in ATLAS_SIZE_X:
			if i >= atlasItemsCount:
				break
			var UVx1 = padPixelX+(x*sepX)
			var UVx2 = padPixelX+(x*sepX)+sepX-(padPixelX*2.0)
			var UVy1 = padPixelY+(y*sepY)
			var UVy2 = padPixelY+(y*sepY)+sepY-(padPixelY*2.0)
			texUV[i] = [
				Vector2(UVx1, UVy1),
				Vector2(UVx2, UVy1),
				Vector2(UVx2, UVy2),
				Vector2(UVx1, UVy2),
			]
			i += 1
