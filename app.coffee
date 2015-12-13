express = require 'express'
app = express()
http = require('http')
server = http.createServer(app)
io = require('socket.io')(server);
p2 = require('p2')

randomColor = (min, max) ->
  val = Math.floor(Math.random() * (max-min)) + min
  
  dice = Math.random() * 6
  switch
    when dice < 1 then 0x0000FF + val * 0x000100
    when dice < 2 then 0x0000FF + val * 0x010000
    when dice < 3 then 0x00FF00 + val * 0x000001
    when dice < 4 then 0x00FF00 + val * 0x010000
    when dice < 5 then 0xFF0000 + val * 0x000001
    when dice < 6 then 0xFF0000 + val * 0x000100

app.use(express.static(__dirname + '/app'));

collisionGroupPlayers = null
collisionGroupBalls = null
collisionGroupWalls = null
collisionGroupObstacles = null
world = new p2.World(gravity: [0, 0])
#world.setGlobalRelaxation 10

mapSettings = 
  outOfBoundsMargin: 100
  halfPlayingWidth: 260
  halfPlayingHeight: 200
  halfNetHeight: 80
  netDepth: 40
  ballRadius: 12
  playerRadius: 20
  postRadius: 8
  shootPower: 350
  maxAccel: 300
  shootingAccel: 200

x = mapSettings.halfPlayingWidth
y = mapSettings.halfPlayingHeight
n = mapSettings.halfNetHeight
d = mapSettings.netDepth
w = x + d + mapSettings.outOfBoundsMargin
h = y + mapSettings.outOfBoundsMargin

#world.setBounds -w, -h, 2*w, 2*h
ballMaterial = new p2.Material('ballMaterial')
wallMaterial = new p2.Material('wallMaterial')
playerMaterial = new p2.Material('playerMaterial')
postMaterial = new p2.Material('postMaterial')


walls = new (p2.Body)(
  mass: 0
  position: [0, 0]
)

# top and bottom
walls.addShape new (p2.Line)(length: 2 * x), [0, y], 0
walls.addShape new (p2.Line)(length: 2 * x), [0, -y], 0

# goal lines
len = y - n
cen = y / 2.0 + n / 2.0
walls.addShape new (p2.Line)(length: len), [x, cen], Math.PI / 2.0
walls.addShape new (p2.Line)(length: len), [-x, cen], Math.PI / 2.0
walls.addShape new (p2.Line)(length: len), [x, -cen], Math.PI / 2.0
walls.addShape new (p2.Line)(length: len), [-x, -cen], Math.PI / 2.0

# sides of nets
cx = x + n / 2.0
walls.addShape new (p2.Line)(length: d), [cx, n]
walls.addShape new (p2.Line)(length: d), [-cx, n]
walls.addShape new (p2.Line)(length: d), [cx, -n]
walls.addShape new (p2.Line)(length: d), [-cx, -n]

# backs of nets
walls.addShape new (p2.Line)(length: 2 * n), [x+d, 0], Math.PI / 2.0
walls.addShape new (p2.Line)(length: 2 * n), [-x-d, 0], Math.PI / 2.0

collisionGroups = 
  players: 0x0001
  balls: 0x0002
  walls: 0x0004
  obstacles: 0x0008

for shape in walls.shapes
  shape.material = wallMaterial
  shape.collisionGroup = collisionGroups.walls
  shape.collisionMask = collisionGroups.balls

world.addBody walls
#world.restitution = 0.5

world.addContactMaterial new p2.ContactMaterial(ballMaterial, ballMaterial, restitution: 0.8)
world.addContactMaterial new p2.ContactMaterial(ballMaterial, playerMaterial, (restitution: 0.2, friction: 0))
world.addContactMaterial new p2.ContactMaterial(ballMaterial, postMaterial, restitution: 0.3)
world.addContactMaterial new p2.ContactMaterial(ballMaterial, wallMaterial, restitution: 0.5)

randX = -> (Math.random() * 2 - 1.0) * x
randY = -> (Math.random() * 2 - 1.0) * y

balls = []
players = []

for [1..30]
  ball = new p2.Body(
    position: [randX(), randY()]
    velocity: [(Math.random() * 2 - 1.0) * 500, (Math.random() * 2 - 1.0) * 500]
    mass: 0.3
    damping: 0.5
    fixedRotation: true
  )
  ball.addShape new p2.Circle(
    radius: mapSettings.ballRadius
    material: ballMaterial
    collisionGroup: collisionGroups.balls
    collisionMask: collisionGroups.balls | collisionGroups.walls | collisionGroups.players | collisionGroups.obstacles
  )
  ball.color = randomColor(100,255)
  balls.push ball
  world.addBody ball

for color in [0x0000FF, 0x00FF00, 0xFF0000, 0xFFFF00, 0xFF00FF, 0x00FFFF]
  player = new p2.Body(
    position: [randX(), randY()]
    mass: 1
    damping: 0.9
    fixedRotation: true
  )
  player.addShape new p2.Circle(
    radius: mapSettings.playerRadius
    material: playerMaterial
    collisionGroup: collisionGroups.players
    collisionMask: collisionGroups.players | collisionGroups.balls | collisionGroups.obstacles
  )
  #console.log("Setting color to " + color)
  player.color = color
  player.coolDown = 0
  players.push player
  world.addBody player

for xx in [-1,1] 
  for yy in [-1,1]
    post = new p2.Body(
      position: [x * xx, n * yy]
      mass: 0
    )
    post.addShape new p2.Circle(
      radius: mapSettings.postRadius, 
      material: postMaterial
      collisionGroup: collisionGroups.obstacles
      collisionMask: collisionGroups.balls | collisionGroups.players
    )
    world.addBody post

server.listen 8000;
console.log("Listening on 8000...");

io.on 'connection', (socket) ->
  console.log('a user connected')

timeStep = 1/30

len = (p) ->
  Math.sqrt(p[0]*p[0] + p[1]*p[1])

normal = (p) ->
  d = len(p)
  [p[0] / d, p[1] / d]

mult = (p, scalar) ->
  [p[0] * scalar, p[1] * scalar]

divide = (p, scalar) ->
  mult(p, 1/scalar)

add = (p1, p2) ->
  [p1[0] + p2[0], p1[1] + p2[1]]

subtract = (p1, p2) ->
  add(p1, mult(p2, -1))

rando = (a) ->
  (Math.random() * 2 - 1) * a

cap = (p, max) ->
  d = len(p)
  if (d > max)
    mult(normal(p), max)
  else
    p

setInterval ->
  #console.log "The time is " + new Date().getTime()
  for player in players
    #console.log("new player")
    closestBall = null
    closestDist = 10000000
    for ball in balls
      theDiff = subtract(ball.position, player.position)
      theDist = len(theDiff)
      if theDist - mapSettings.ballRadius - mapSettings.playerRadius < 5 and player.coolDown < new Date().getTime()
        #console.log("kick!")
        player.coolDown = new Date().getTime() + 100
        ball.velocity = add(ball.velocity, mult(normal(theDiff), mapSettings.shootPower))

      if theDist < closestDist
        #console.log("Found new best: " + ball.id + ": " + theDist)
        closestBall = ball
        closestDist = theDist
      
      # if b1.shooting and player.body.coolDown < game.time.totalElapsedSeconds()
      #   for ball in balls.children
      #     b2 = ball.body
      #     diffx = b1.x - (b2.x)
      #     diffy = b1.y - (b2.y)
      #     len = Math.sqrt(diffx * diffx + diffy * diffy)
      #     dist = len - (mapSettings.ballRadius) - (mapSettings.playerRadius)
      #     if dist > 5
      #       continue

      #     didKick = true
      #     b1.coolDown = game.time.totalElapsedSeconds() + 0.1
      #     diffx /= len
      #     diffy /= len
      #     b2.velocity.x -= diffx * mapSettings.shootPower
      #     b2.velocity.y -= diffy * mapSettings.shootPower  
    
    accel = mapSettings.maxAccel
    direction = add(subtract(closestBall.position, player.position), [rando(30), rando(30)])
    player.velocity = add(player.velocity, mult(normal(direction), accel*timeStep))

  # cap the ball speeds
  for ball in balls
    ball.velocity = cap(ball.velocity, mapSettings.ballRadius / timeStep - 10)

  #The step method moves the bodies forward in time.
  world.step timeStep
  #console.log (JSON.stringify(dynamicobjects[0].position))
  packet = 
    balls: ({id: o.id, x: o.position[0], y: o.position[1], c: o.color} for o in balls)
    players: ({id: o.id, x: o.position[0], y: o.position[1], c: o.color} for o in players)
  io.emit 'positions', packet
, 1000 * timeStep
