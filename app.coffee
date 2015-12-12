express = require 'express'
app = express()
http = require('http')
server = http.createServer(app)
io = require('socket.io')(server);
p2 = require('p2')

app.use(express.static(__dirname + '/app'));

collisionGroupPlayers = null
collisionGroupBalls = null
collisionGroupWalls = null
collisionGroupObstacles = null
world = new p2.World(gravity: [0, 0])

mapSettings = 
  outOfBoundsMargin: 100
  halfPlayingWidth: 400
  halfPlayingHeight: 250
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
    radius: mapSettings.ballRadius, 
    material: ballMaterial
    collisionGroup: collisionGroups.balls
    collisionMask: collisionGroups.balls | collisionGroups.walls | collisionGroups.players | collisionGroups.obstacles
  )
  balls.push ball

  world.addBody ball

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

timeStep = 1/60

setInterval ->
  #The step method moves the bodies forward in time. 
  world.step timeStep
  #console.log (JSON.stringify(dynamicobjects[0].position))
  packet = 
    balls: ({id: o.id, x: o.position[0], y: o.position[1]} for o in balls)
    players: ({id: o.id, x: o.position[0], y: o.position[1]} for o in players)
  io.emit 'positions', packet

, 1000 * timeStep
