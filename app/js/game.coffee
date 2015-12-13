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

collisionGroupPlayers = null
collisionGroupBalls = null
collisionGroupWalls = null
collisionGroupObstacles = null
cursors = null
player = null
balls = null
players = null
walls = null
sounds = null
ballTexture = null
playerTexture = null
ready = false
ballMaterial = null

socket = io()

game = new (Phaser.Game)(800, 600, Phaser.CANVAS, 'haxpark',
  preload: ->
    game.load.image 'white', 'assets/sprites/white.png'
    game.load.image 'mario', 'assets/sprites/mario.gif'
    game.load.image 'ball', 'assets/sprites/white_outline.png', 32, 32
    game.load.image 'grass', 'assets/sprites/grass.jpg'
    game.load.audio 'kick', 'assets/audio/wall.wav'
    game.load.audio 'wall', 'assets/audio/wall.wav'

  createWalls: ->
    walls = new (p2.Body)(
      mass: 0
      position: [0, 0]
    )
    sim = game.physics.p2
    x = mapSettings.halfPlayingWidth
    y = mapSettings.halfPlayingHeight
    n = mapSettings.halfNetHeight
    d = mapSettings.netDepth
    
    # top and bottom
    walls.addShape new (p2.Line)(length: sim.pxmi(2 * x)), [
      0
      sim.pxmi(y)
    ], 0
    walls.addShape new (p2.Line)(length: sim.pxmi(2 * x)), [
      0
      sim.pxmi(-y)
    ], 0
    # goal lines
    len = sim.pxmi(y - n)
    cen = y / 2.0 + n / 2.0
    walls.addShape new (p2.Line)(length: len), [
      sim.pxmi(x)
      sim.pxmi(cen)
    ], Math.PI / 2.0
    walls.addShape new (p2.Line)(length: len), [
      sim.pxmi(x)
      sim.pxmi(-cen)
    ], Math.PI / 2.0
    walls.addShape new (p2.Line)(length: len), [
      sim.pxmi(-x)
      sim.pxmi(cen)
    ], Math.PI / 2.0
    walls.addShape new (p2.Line)(length: len), [
      sim.pxmi(-x)
      sim.pxmi(-cen)
    ], Math.PI / 2.0
    # sides of nets
    cx = sim.pxmi(x + n / 2.0)
    walls.addShape new (p2.Line)(length: sim.pxmi(d)), [
      cx
      sim.pxmi(n)
    ]
    walls.addShape new (p2.Line)(length: sim.pxmi(d)), [
      -cx
      sim.pxmi(n)
    ]
    walls.addShape new (p2.Line)(length: sim.pxmi(d)), [
      cx
      sim.pxmi(-n)
    ]
    walls.addShape new (p2.Line)(length: sim.pxmi(d)), [
      -cx
      sim.pxmi(-n)
    ]
    # backs of nets
    walls.addShape new (p2.Line)(length: sim.pxmi(2 * n)), [
      sim.pxmi(x + d)
      0
    ], Math.PI / 2.0
    walls.addShape new (p2.Line)(length: sim.pxmi(2 * n)), [
      sim.pxmi(-x - d)
      0
    ], Math.PI / 2.0

    graphics = game.add.graphics(0, 0)
    graphics.lineStyle 6, 0xFFFFFF, 0.6
    graphics.drawRect -x, -y, x*2, y*2
    graphics.drawRect -x-d, -n, d, 2*n
    graphics.drawRect x, -n, d, 2*n

    for shape in walls.shapes
      shape.collisionGroup = collisionGroupWalls.mask
      shape.collisionMask = collisionGroupBalls.mask

    game.physics.p2.world.addBody walls
    floorGroup = game.add.group()
    floorGroup.z = 0.5
    floorGroup.add(graphics)
    return

  create: ->
    margin = mapSettings.outOfBoundsMargin
    px = mapSettings.halfPlayingWidth
    py = mapSettings.halfPlayingHeight
    nx = mapSettings.netDepth
    ny = mapSettings.halfNetHeight

    halfWorldWidth = px+margin+nx
    halfWorldHeight = py+margin

    game.world.setBounds -halfWorldWidth, -halfWorldHeight, 2*halfWorldWidth, 2*halfWorldHeight
    game.add.tileSprite(-halfWorldWidth, -halfWorldHeight, 2*halfWorldWidth, 2*halfWorldHeight, 'grass');
    game.physics.startSystem Phaser.Physics.P2JS
    game.physics.p2.setImpactEvents true
    game.physics.p2.restitution = 0.5

    collisionGroupPlayers = game.physics.p2.createCollisionGroup()
    collisionGroupBalls = game.physics.p2.createCollisionGroup()
    collisionGroupWalls = game.physics.p2.createCollisionGroup()
    collisionGroupObstacles = game.physics.p2.createCollisionGroup()
    
    this.createWalls()

    balls = game.add.group()
    players = game.add.group()

    onFieldGroup = game.add.physicsGroup(Phaser.Physics.P2JS)
    onFieldGroup.z = 1

    game.physics.p2.updateBoundsCollisionGroup()
    game.cameraPos = new (Phaser.Point)(0, 0)
    game.cameraLerp = 0.04

    ballMaterial = game.physics.p2.createMaterial('ballMaterial')
    wallMaterial = game.physics.p2.createMaterial('wallMaterial')
    playerMaterial = game.physics.p2.createMaterial('playerMaterial')
    postMaterial = game.physics.p2.createMaterial('postMaterial')
    
    ballBallCM = game.physics.p2.createContactMaterial(ballMaterial, ballMaterial, restitution: 0.8)
    ballPlayerCM = game.physics.p2.createContactMaterial(ballMaterial, playerMaterial, (restitution: 0.2, friction: 0))
    ballPostCM = game.physics.p2.createContactMaterial(ballMaterial, postMaterial, restitution: 0.3)
    
    fieldBounds = new (Phaser.Rectangle)(-px, -py, 2 * px, 2 * py)

    playerTexture = game.add.bitmapData(37,37)
    playerTexture.circle(18,18,17)
    playerTexture.draw('white', 4, 4)
    
    ballTexture = game.add.bitmapData(37,37)
    ballTexture.circle(18,18,17)
    ballTexture.draw('ball', 2, 2)

    for xx in [-1,1] 
      for yy in [-1,1]
        post = onFieldGroup.create(px * xx, ny * yy, ballTexture)
        post.scale.set mapSettings.postRadius / 16.0
        post.body.setCircle mapSettings.postRadius
        post.body.static = true
        post.body.setMaterial postMaterial
        post.body.damping = 0.5
        post.body.setCollisionGroup collisionGroupObstacles
        post.body.collides [
          collisionGroupPlayers
          collisionGroupBalls
        ]

    sounds = 
      kick: game.add.audio('kick')
      wall: game.add.audio('wall')

    cursors = game.input.keyboard.addKeys(
      'up': Phaser.KeyCode.UP
      'down': Phaser.KeyCode.DOWN
      'left': Phaser.KeyCode.LEFT
      'right': Phaser.KeyCode.RIGHT
      'shoot': Phaser.KeyCode.X)

    ready = true

  update: ->
    # didKick = false
    for player in players.children
      # if cursors.shoot.isDown
      #   player.body.isShooting = true
      #   player.tint = 0xFFFFFF
      # else
      #   player.body.isShooting = false
      #   player.tint = player.originalTint
      # accel = if player.body.isShooting then shootingAccel else maxAccel

      if player.shooting
        player.tint = 0xFFFFFF
      else
        player.tint = player.originalTint

      # if cursors.left.isDown
      #   player.body.force.x = -accel
      # else if cursors.right.isDown
      #   player.body.force.x = accel
      # if cursors.up.isDown
      #   player.body.force.y = -accel
      # else if cursors.down.isDown
      #   player.body.force.y = accel

      # b1 = player
      
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
    
    # if didKick 
    #   sounds.kick.play()
    # game.cameraPos.x += (player.x - (game.cameraPos.x)) * game.cameraLerp
    # # smoothly adjust the x position
    # game.cameraPos.y += (player.y - (game.cameraPos.y)) * game.cameraLerp
    # # smoothly adjust the y position
    # game.camera.focusOnXY game.cameraPos.x, game.cameraPos.y
    # apply smoothed virtual positions to actual camera
    return

)

    
spawnBall = (id,x,y,c) ->
  ball = balls.create(x, y, ballTexture)
  ball.id = id
  ball.anchor.x = 0.5
  ball.anchor.y = 0.5
  ball.tint = c
  ball.scale.set mapSettings.ballRadius / 16.0
  # ball.body.setCircle mapSettings.ballRadius
  # ball.body.mass = 0.3
  # ball.body.setMaterial ballMaterial
  # ball.body.damping = 0.5
  # ball.body.fixedRotation = true
  # ball.body.setCollisionGroup collisionGroupBalls
  # ball.body.collides [
  #   collisionGroupPlayers
  #   collisionGroupBalls
  #   collisionGroupWalls
  #   collisionGroupObstacles
  # ]

spawnPlayer = (id,x,y,c) ->
  player = players.create(x, y, playerTexture)
  player.id = id
  player.anchor.x = 0.5
  player.anchor.y = 0.5
  player.originalTint = c
  player.tint = player.originalTint
  player.inner_image = game.add.sprite(0, 0, 'mario')
  player.inner_image.anchor.setTo 0.5
  player.inner_image.scale.set 1.3
  player.addChild player.inner_image
  player.smoothed = true
  player.scale.set mapSettings.playerRadius / 16.0

  # game.physics.p2.enable player, false
  # player.body.fixedRotation = true
  # player.body.setCircle mapSettings.playerRadius
  # player.body.damping = 0.9
  # player.body.restitution = 0.2
  # player.body.setCollisionGroup collisionGroupPlayers
  # player.body.collides [
  #   collisionGroupPlayers
  #   collisionGroupBalls
  #   collisionGroupObstacles
  # ]
  # player.body.setMaterial playerMaterial
  # player.body.coolDown = 0
  return


socket.on 'positions', (packet) ->
  if not ready 
    return

  #console.log JSON.stringify packet
  for ball in packet.balls
    matchedBall = balls.children.find((b) -> b.id == ball.id)
    if not matchedBall
      spawnBall ball.id, ball.x, ball.y, ball.c
    else
      matchedBall.x = ball.x
      matchedBall.y = ball.y
  
  for player in packet.players
    matchedPlayer = players.children.find((p) -> p.id == player.id)
    if not matchedBall
      spawnPlayer player.id, player.x, player.y, player.c
    else
      matchedPlayer.x = player.x
      matchedPlayer.y = player.y
      matchedPlayer.shooting = player.shooting
      #matchedPlayer.originalTint = player.c

  return