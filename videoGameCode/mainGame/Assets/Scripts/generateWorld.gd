extends Node2D

var rng:RandomNumberGenerator = RandomNumberGenerator.new()
@export var mapHeight: int = 7
@export var mapWidth: int = 7
var minSolutionPath: int = 0
var maxSolutionPath: int = 0
@export var branchProb: float = 0.4
var maxBranchLength: int = 3
@export var difficultyModifier: float = 1.0 # easy = 0.5, normal = 1.0, hard = 1.5

var map: Array = Array()

# Add generation attempt tracking
var maxGenerationAttempts: int = 100
var currentAttempt: int = 0

var roomTemplate: Dictionary = {
	"coords": null,
	"explored": false,
	"cleared": false,
	"type": "",
	"onSolutionPath": false,
	"order": 0,
	"active": false
}

var corridorTemplate: Dictionary = {
	"coords": null,
	"explored": false,
	"type": null,
	"onSolutionPath": false,
	"emergent": false,
	"compassDirection": -1,
	"active": false
}

var compassDirections: Dictionary[String, int] = {
	"NORTH": 0,
	"SOUTH": 1,
	"EAST": 2,
	"WEST": 3
}

# atlas info
var corridorTypeTiles: Dictionary[String, Vector2i] = {
	"straightVertical": Vector2i(2,1),
	"straightHorizontal": Vector2i(1,0),
	"rightDownTurn": Vector2i(2,0),
	"upRightTurn": Vector2i(0,0),
	"downLeftTurn": Vector2i(2,2),
	"leftUpTurn": Vector2i(0,2),
	"verticalLeftJunction": Vector2i(4,0),
	"verticalRightJunction": Vector2i(3,0),
	"horizontalUpJunction": Vector2i(4,1),
	"horizontalDownJunction": Vector2i(3,1),
	# crossroads
	"northDeadend": Vector2i(),
	"southDeadend": Vector2i(),
	"eastDeadend": Vector2i(),
	"westDeadend": Vector2i()
}

var roomTypeTiles: Dictionary[String, Vector2i] = {
	"basicArena": Vector2i(0,3),
	"advancedArena": Vector2i(0,3),
	"puzzleRoom": Vector2i(0,3),
	"Start": Vector2i(1,1),
	"Centre": Vector2i(1,1)
}

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func generate_map_data() -> void:
	rng.randomize()
	
	mapWidth = GameData.map_width
	mapHeight = GameData.map_height
	branchProb = GameData.branch_prob
	difficultyModifier = GameData.game_difficulty
	print("setting constraints")
	scaleConstraints()
	
	# try generation multiple times with progressively relaxed constraints
	currentAttempt = 0
	var success: bool = false
	
	while currentAttempt < maxGenerationAttempts and not success:
		currentAttempt += 1
		print("Generation attempt ", currentAttempt)
		
		print("initialising map")
		initMap()
		print("choosing start")
		var startCoords: Vector2i = chooseStart()
		print("setting centre")
		var centreCoords: Vector2i = setCentre()
		print("creating solution path")
		var solutionPath: Array[Vector2i] = generateSolutionPath(startCoords, centreCoords)
		
		if solutionPath.size() > 0:
			print("generating branches")
			var branches: Array = generateBranches(solutionPath)
			print("placing rooms")
			placeRooms(solutionPath, branches)
			
			# Store the data
			GameData.maze_map = map.duplicate(true)
			print("Map generation successful!")
			success = true
		else:
			print("Failed to generate path, retrying...")
			# relax constraints for next attempt
			if currentAttempt % 10 == 0:
				minSolutionPath = max(int(minSolutionPath * 0.9), int((mapWidth + mapHeight) * 0.5))
				print("Relaxing min path length to: ", minSolutionPath)
	
	if not success:
		print("Failed to generate maze after ", maxGenerationAttempts, " attempts")
		get_tree().reload_current_scene()

func scaleConstraints() -> void:
	var totalArea: int = mapWidth * mapHeight
	
	if mapHeight <= 7:
		minSolutionPath = int(totalArea * 0.35 * difficultyModifier)  
		maxSolutionPath = int(totalArea * 0.50)
	else: # more lenient for larger mazes
		minSolutionPath = int(totalArea * 0.25 * difficultyModifier)  
		maxSolutionPath = int(totalArea * 0.55)
	 
	# manhatten distance from edge of maze to centre
	var minPossibleDistance: int = max(mapWidth, mapHeight) / 2
	
	if minSolutionPath < minPossibleDistance:
		minSolutionPath = minPossibleDistance + 2  # Reduced from +3
	
	# half of map width or height
	maxBranchLength = int(max(mapWidth, mapHeight) / 2)
	
	print("Path constraints: min=", minSolutionPath, " max=", maxSolutionPath)

func initMap() -> void:
	map.resize(mapHeight)
	for i in range(mapHeight):
		map[i] = Array()
		map[i].resize(mapWidth)
		for j in range(mapWidth):
			var emptyRoom: Dictionary = roomTemplate.duplicate()
			emptyRoom["coords"] = Vector2i(j, i)
			map[i][j] = emptyRoom

# choose location of start room in maze, only spawns on outer edges of maze and not in corners of maze
func chooseStart() -> Vector2i:
	var randY: int
	var randX: int
	
	var side: int = rng.randi_range(1,4)
	
	match side:
		# Top
		1:
			randY = 0
			randX = rng.randi_range(1, mapWidth - 2)
		# Bottom
		2:
			randY = mapHeight - 1
			randX = rng.randi_range(1, mapWidth - 2)
		# Left
		3:
			randY = rng.randi_range(1, mapHeight - 2)
			randX = 0
		# Right
		4:
			randY = rng.randi_range(1, mapHeight - 2)
			randX = mapWidth - 1
	
	if randX < map.size() and randY < map[0].size():
		var startRoom: Dictionary = roomTemplate.duplicate()
		startRoom["coords"] = Vector2i(randX, randY)
		startRoom["explored"] = true
		startRoom["type"] = "Start"
		startRoom["onSolutionPath"] = true
		map[randY][randX] = startRoom
	
	return Vector2i(randX, randY)

func setCentre() -> Vector2i:
	var centreRoom: Dictionary = roomTemplate.duplicate()
	var centreY: int = mapHeight / 2
	var centreX: int = mapWidth / 2
	centreRoom["coords"] = Vector2i(centreX, centreY)
	centreRoom["explored"] = false
	centreRoom["type"] = "Centre"
	centreRoom["onSolutionPath"] = true
	map[centreY][centreX] = centreRoom   
	
	return Vector2i(centreX, centreY)

func generateSolutionPath(startCoords:Vector2i, targetCoords:Vector2i) -> Array[Vector2i]:
	# Try multiple times with different random seeds
	for attempt in range(20):
		var solutionPath: Array[Vector2i] = windingPath(startCoords, targetCoords, [], 0)
		if solutionPath.size() > 0:
			# draw corridors from generated soln path onto the map
			var currIndex: int = 1 # starting from first corridor in path not from start room
			var corridorNum: int = 1 
			
			for coords in solutionPath:
				if map[coords.y][coords.x].type == "Start": continue
				
				var direction: Vector2i = coords - solutionPath.get(currIndex - 1)
				
				var corridor: Dictionary = corridorTemplate.duplicate()
				corridor["coords"] = coords
				corridor["onSolutionPath"] = true
				corridor["order"] = corridorNum
				if rng.randf() > 0.8: corridor["emergent"] = true
				
				# direction of current cell relevant to previous cell in solution path
				match direction:
					Vector2i.DOWN: corridor["compassDirection"] = compassDirections.SOUTH
					Vector2i.UP: corridor["compassDirection"] = compassDirections.NORTH
					Vector2i.RIGHT: corridor["compassDirection"] = compassDirections.EAST
					Vector2i.LEFT: corridor["compassDirection"] = compassDirections.WEST
				
				map[coords.y][coords.x] = corridor
				var prevCoords: Vector2i = solutionPath.get(currIndex - 1)
				var corridorTypes: Array[String] = setCorridorType(map[coords.y][coords.x], map[prevCoords.y][prevCoords.x], solutionPath.size())
				if corridorTypes.size() == 1: corridor["type"] = corridorTypes[0]
				else:
					corridor["type"] = corridorTypes[0]
					map[prevCoords.y][prevCoords.x].set("type", corridorTypes[1]) 
				corridorNum += 1
				currIndex += 1
			
			return solutionPath
	
	return []

func windingPath(current: Vector2i, target: Vector2i, path: Array[Vector2i], depth: int) -> Array[Vector2i]:
	# depth limit to prevent excessive recursion
	if depth > mapWidth * mapHeight * 2:
		return []
	
	path.append(current)
	var solutionPathLength: int = path.size() - 2 # dont include start and centre rooms
	
	if current == target:
		# dont include start and centre rooms
		if solutionPathLength >= minSolutionPath: 
			return path
		else:
			path.pop_back()
			return []
	
	if solutionPathLength > maxSolutionPath:
		path.pop_back()
		return []
	
	# manhattan distance to target for biased direction selection
	var toTarget: Vector2i = target - current
	var manhattanDist: int = abs(toTarget.x) + abs(toTarget.y)
	
	# bias toward target more when we're far from min length or close to max length
	var targetBias: float = 0.3  # base 30% chance to move toward target
	if solutionPathLength < minSolutionPath * 0.7:
		targetBias = 0.5  # 50% when we need more length
	elif solutionPathLength > maxSolutionPath * 0.8:
		targetBias = 0.7  # 70% when approaching max length
	
	var neighbours: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
	
	# Sort directions with bias toward target
	if rng.randf() < targetBias:
		neighbours.sort_custom(func(a, b): 
			var distA = abs((current + a - target).x) + abs((current + a - target).y)
			var distB = abs((current + b - target).x) + abs((current + b - target).y)
			return distA < distB
		)
	else:
		neighbours.shuffle()
	
	# check direction valid
	for direction in neighbours:
		var nextCell: Vector2i = current + direction
		
		if nextCell.y < 0 or nextCell.y >= mapHeight or nextCell.x < 0 or nextCell.x >= mapWidth: 
			continue
		
		if nextCell in path: 
			continue
		
		# dont allow soln path to intersect with centre or start room
		var nextCellType: String = map[nextCell.y][nextCell.x].get("type")
		if nextCellType != "" and nextCell != target: 
			continue
		
		var result: Array[Vector2i] = windingPath(nextCell, target, path, depth + 1)
		if result.size() > 0: 
			return result
	
	# no valid direction
	path.pop_back()
	return []

func generateBranches(solutionPath:Array[Vector2i]) -> Array:
	var copyOfSolutionPath: Array[Vector2i] = solutionPath.duplicate(true)
	copyOfSolutionPath.pop_back() # dont include centre room
	copyOfSolutionPath.shuffle()
	var branches: Array = Array()
	branches.resize(copyOfSolutionPath.size())
	
	for cell in copyOfSolutionPath:
		if rng.randf() < branchProb:
			var branch: Array[Vector2i] = generateBranch(cell, copyOfSolutionPath)
			branches.append(branch)
	return branches

func generateBranch(currentCell:Vector2i, solutionPath: Array[Vector2i]) -> Array[Vector2i]:
	var branch: Array[Vector2i] = windingPathWithNoTarget(currentCell, 0, [])
	
	if branch.size() > 1:
		
		var rootCoords: Vector2i = branch[0] # coords of corridor on solutionPath
		var firstStepCoords: Vector2i = branch[1] # coords of first corridor in branch
		var rootCell: Dictionary = map[rootCoords.y][rootCoords.x]
		var branchDirection: Vector2i = firstStepCoords - rootCoords
		
		var newJunctionType: String = setJunctionType(rootCell.get("type"), branchDirection)
		if newJunctionType != "": rootCell["type"] = newJunctionType 
		
		for i in range(1, branch.size()):
			var coords: Vector2i = branch[i]
			var prevCoords: Vector2i = branch.get(i - 1)
			var direction: Vector2i = coords - prevCoords
			
			var existingCell: Dictionary = map[coords.y][coords.x]
			if existingCell.get("type") != "": continue
			
			var corridor: Dictionary = corridorTemplate.duplicate()
			corridor["coords"] = coords
			corridor["onSolutionPath"] = false
			corridor["order"] = i
			if rng.randf() > 0.8: corridor["emergent"] = true
			
			# direction of current cell relevant to previous cell in solution path
			match direction:
				Vector2i.DOWN: corridor["compassDirection"] = compassDirections.SOUTH
				Vector2i.UP: corridor["compassDirection"] = compassDirections.NORTH
				Vector2i.RIGHT: corridor["compassDirection"] = compassDirections.EAST
				Vector2i.LEFT: corridor["compassDirection"] = compassDirections.WEST
			
			map[coords.y][coords.x] = corridor
			
			if i == 1: # corridor after junction
				match direction:
					Vector2i.DOWN: corridor["type"] = "straightSouth"
					Vector2i.UP: corridor["type"] = "straightNorth"
					Vector2i.RIGHT:  corridor["type"] = "straightEast"
					Vector2i.LEFT: corridor["type"] = "straightWest"
				if i == branch.size() - 1: # last corridor in branch
					corridor["type"] += "Deadend"
			else:
				var corridorTypes: Array[String] = setCorridorType(map[coords.y][coords.x], map[prevCoords.y][prevCoords.x], solutionPath.size())
				if corridorTypes.size() == 1: corridor["type"] = corridorTypes[0]
				else:
					corridor["type"] = corridorTypes[0]
					map[prevCoords.y][prevCoords.x].set("type", corridorTypes[1])
				if i == branch.size() - 1: # last corridor in branch
					corridor["type"] += "Deadend"
	return branch

func windingPathWithNoTarget(currentCell:Vector2i, currentLen: int, branch:Array[Vector2i]) -> Array[Vector2i]:
	branch.append(currentCell)
	
	if currentLen > maxBranchLength: return branch
	
	# random direction
	var neighbours: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
	neighbours.shuffle()
	
	for direction in neighbours:
		var nextCell: Vector2i = currentCell + direction
		
		if nextCell.y < 0 or nextCell.y >= mapHeight or nextCell.x < 0 or nextCell.x >= mapWidth: continue
		
		if nextCell in branch: continue
		
		if map[nextCell.y][nextCell.x].get("type") == "":
			if countOccupiedNeighbours(nextCell) == 1:
				var result: Array[Vector2i] = windingPathWithNoTarget(nextCell, currentLen + 1, branch)
				if result.size() > 0:
					return result 
	
	if currentLen > 0: return branch # reached dead end, return what we have as a branch
	else:
		branch.pop_back()
		return []

func countOccupiedNeighbours(currentCell: Vector2i) -> int:
	var count: int = 0
	var directions: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
	for direction in directions:
		var nextCell: Vector2i = currentCell + direction
		if nextCell.y >= 0 and nextCell.y < mapHeight and nextCell.x >= 0 and nextCell.x < mapWidth:
			if not map[nextCell.y][nextCell.x].get("type") == "":
				count += 1
	return count

# return format is [currentCellType, previousCellType] or [currentCellType]
func setCorridorType(currentCell: Dictionary, previousCell: Dictionary, solutionPathLength: int) -> Array[String]:
	var currentCelldirection: int = currentCell.get("compassDirection")
	
	# start room connections
	if previousCell.get("type") == "Start":
		match currentCelldirection:
			compassDirections.NORTH: return ["straightNorth"]
			compassDirections.SOUTH: return ["straightSouth"]
			compassDirections.EAST: return ["straightEast"]
			compassDirections.WEST: return ["straightWest"]
	# centre room connection
	elif previousCell.get("order") == solutionPathLength - 2: # corridor before centre room
		var previousCellCoords: Vector2i = previousCell.get("coords")
		var centreCoords: Vector2i = currentCell.get("coords")
		var previousCellDirection: int = previousCell.get("compassDirection")
		
		var aboveCentre: bool = previousCellCoords == centreCoords - Vector2i.DOWN
		var belowCentre: bool = previousCellCoords == centreCoords + Vector2i.DOWN
		var leftOfCentre: bool = previousCellCoords == centreCoords - Vector2i.RIGHT
		var rightOfCentre: bool = previousCellCoords == centreCoords + Vector2i.RIGHT
		
		match previousCellDirection: 
				compassDirections.NORTH:
					if aboveCentre or belowCentre: return ["Centre", "straightNorth"]
					elif leftOfCentre: return ["Centre", "northToEastTurn"]
					else: return ["Centre", "northToWestTurn"]
				compassDirections.SOUTH:
					if aboveCentre or belowCentre: return ["Centre", "straightSouth"]
					elif leftOfCentre: return ["Centre", "southToEastTurn"]
					else: return ["Centre", "southToWestTurn"]
				compassDirections.EAST:
					if leftOfCentre or rightOfCentre: return ["Centre", "straightEast"]
					elif aboveCentre: return ["Centre", "eastToSouthTurn"]
					else: return ["Centre", "eastToNorthTurn"]
				compassDirections.WEST:
					if leftOfCentre or rightOfCentre: return ["Centre", "straightWest"]
					elif aboveCentre: return ["Centre", "westToSouthTurn"]
					else: return ["Centre", "westToNorthTurn"]
	# solution path and branches
	else:
		var previousCellDirection: int = previousCell.get("compassDirection")
		if currentCelldirection == previousCellDirection: 
			match currentCelldirection:
				compassDirections.NORTH: return ["straightNorth"]
				compassDirections.SOUTH: return ["straightSouth"]
				compassDirections.EAST: return ["straightEast"]
				compassDirections.WEST: return ["straightWest"]
		else:
			match previousCellDirection:
				compassDirections.NORTH:
					if currentCelldirection == compassDirections.WEST: return ["straightWest", "northToWestTurn"]
					else: return ["straightEast", "northToEastTurn"]
				compassDirections.SOUTH:
					if currentCelldirection == compassDirections.WEST: return ["straightWest", "southToWestTurn"]
					else: return ["straightEast", "southToEastTurn"]
				compassDirections.EAST:
					if currentCelldirection == compassDirections.NORTH: return ["straightNorth", "eastToNorthTurn"]
					else: return ["straightSouth", "eastToSouthTurn"]
				compassDirections.WEST:
					if currentCelldirection == compassDirections.NORTH: return ["straightNorth", "westToNorthTurn"]
					else: return ["straightSouth", "westToSouthTurn"]
	return []

func setJunctionType(currentType: String, branchDir: Vector2i) -> String:
	
	match currentType:
		"straightNorth", "straightSouth":
			if branchDir == Vector2i(1, 0): return "verticalRightJunction"
			if branchDir == Vector2i(-1, 0): return "verticalLeftJunction"
		
		"straightEast", "straightWest":
			if branchDir == Vector2i(0, 1): return "horizontalDownJunction"
			if branchDir == Vector2i(0, -1): return "horizontalUpJunction"
		
		"northToWestTurn":
			if branchDir == Vector2i(1, 0): return "horizontalDownJunction"
			if branchDir == Vector2i(0, -1): return "verticalLeftJunction"
		
		"northToEastTurn":
			if branchDir == Vector2i(-1, 0): return "horizontalDownJunction"
			if branchDir == Vector2i(0, -1): return "verticalRightJunction"  
		
		"southToWestTurn":
			if branchDir == Vector2i(1, 0): return "horizontalUpJunction"  
			if branchDir == Vector2i(0, 1): return "verticalLeftJunction" 
		
		"southToEastTurn":
			if branchDir == Vector2i(-1, 0): return "horizontalUpJunction"  
			if branchDir == Vector2i(0, 1): return "verticalRightJunction"
		
		"eastToNorthTurn":
			if branchDir == Vector2i(0, 1): return "verticalLeftJunction"  
			if branchDir == Vector2i(1, 0): return "horizontalUpJunction"
		
		"eastToSouthTurn":
			if branchDir == Vector2i(0, -1): return "verticalLeftJunction"
			if branchDir == Vector2i(1, 0): return "horizontalDownJunction" 
		
		"westToNorthTurn":
			if branchDir == Vector2i(0, 1): return "verticalRightJunction" 
			if branchDir == Vector2i(-1, 0): return "horizontalUpJunction" 
		
		"westToSouthTurn":
			if branchDir == Vector2i(0, -1): return "verticalRightJunction"
			if branchDir == Vector2i(-1, 0): return "horizontalDownJunction"
	
	return ""

# calculate advanced room probability based on progress made in traversing solution path
func calculateAdvancedRoomChance(order: int, totalCorridors: int) -> float:
	var progress: float = float(order) / float(totalCorridors)
	
	# first 20% = 0% advanced rooms
	if progress < 0.2:
		return 0.0
	
	# gradually increase from 20% onwards every 5% of progress adds some chance
	var adjustedProgress: float = (progress - 0.2) / 0.8 
	
	return adjustedProgress

# place rooms along corridors with spacing and difficulty scaling
func placeRooms(solutionPath: Array[Vector2i], branches: Array) -> void:
	var totalCorridors: int = solutionPath.size() - 2
	
	var corridorsSinceLastRoom: int = 0
	for coords in solutionPath:
		var cell: Dictionary = map[coords.y][coords.x]
		
		if cell.get("type") == "Start" or cell.get("type") == "Centre":
			continue
		
		if cell.get("emergent") == true:
			continue
		
		corridorsSinceLastRoom += 1
		
		var order: int = cell.get("order")
		
		#dont let room be adjacent to centre
		if order == totalCorridors:
			continue
		
		var mustPlaceRoom: bool = corridorsSinceLastRoom >= 3
		
		var shouldPlaceRoom: bool = mustPlaceRoom or (corridorsSinceLastRoom >= 2 and rng.randf() < 0.5)
		
		if shouldPlaceRoom:
			var advancedChance: float = calculateAdvancedRoomChance(order, totalCorridors)
			var isAdvanced: bool = rng.randf() < advancedChance
			
			if isAdvanced:
				cell["type"] = "advancedArena"
			else:
				cell["type"] = "basicArena"
			
			corridorsSinceLastRoom = 0
	
	for branch in branches:
		if branch == null or branch.size() < 2:
			continue
		
		# get the order of the root
		var rootCoords: Vector2i = branch[0]
		var rootCell: Dictionary = map[rootCoords.y][rootCoords.x]
		var branchRootOrder: int = rootCell.get("order")
		
		# determine branch difficulty based on where it branches off
		var branchAdvancedChance: float = calculateAdvancedRoomChance(branchRootOrder, totalCorridors)
		
		var corridorsSinceLastRoomBranch: int = 0 
		
		# skip root and first cell to stop 2 rooms being adjacent
		for i in range(2, branch.size()):
			var coords: Vector2i = branch[i]
			var cell: Dictionary = map[coords.y][coords.x]
			
			if cell.get("emergent") == true:
				continue
			
			corridorsSinceLastRoomBranch += 1
			
			var mustPlaceRoom: bool = corridorsSinceLastRoomBranch >= 3
			
			var shouldPlaceRoom: bool = mustPlaceRoom or (corridorsSinceLastRoomBranch >= 2 and rng.randf() < 0.5)
			
			if shouldPlaceRoom:
				var isAdvanced: bool = rng.randf() < branchAdvancedChance
				
				if isAdvanced:
					cell["type"] = "advancedArena"
				else:
					cell["type"] = "basicArena"
				corridorsSinceLastRoomBranch = 0
