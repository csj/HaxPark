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
maxAccel = 300
shootingAccel = 200

collisionGroupPlayers = null
collisionGroupBalls = null
collisionGroupWalls = null
collisionGroupObstacles = null
cursors = null
ship = null
balls = null

game = new (Phaser.Game)(800, 600, Phaser.CANVAS, 'phaser-example',
  preload: ->
    #game.load.spritesheet 'ship', 'assets/sprites/humstar.png', 32, 32
    #game.load.spritesheet 'veggies', 'assets/sprites/fruitnveg32wh37.png', 32, 32
    #game.load.image 'ball', 'assets/sprites/shinyball.png'
    game.load.image 'white', 'assets/sprites/white.png'
    game.load.image 'clown', 'assets/sprites/clown.png'
    game.load.image 'ball', 'assets/sprites/white_outline.png', 32, 32

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

    for shape in walls.shapes
      shape.collisionGroup = collisionGroupWalls.mask
      shape.collisionMask = collisionGroupBalls.mask

    game.physics.p2.world.addBody walls
    return
  
  randomColor: ->
    val = Math.floor(Math.random() * 180) + 30
    
    dice = Math.random() * 6
    switch
      when dice < 1 then 0x0000FF + val * 0x000100
      when dice < 2 then 0x0000FF + val * 0x010000
      when dice < 3 then 0x00FF00 + val * 0x000001
      when dice < 4 then 0x00FF00 + val * 0x010000
      when dice < 5 then 0xFF0000 + val * 0x000001
      when dice < 6 then 0xFF0000 + val * 0x000100


  create: ->
    game.stage.backgroundColor = 0x336644
    margin = mapSettings.outOfBoundsMargin
    px = mapSettings.halfPlayingWidth
    py = mapSettings.halfPlayingHeight
    nx = mapSettings.netDepth
    ny = mapSettings.halfNetHeight
    
    game.world.setBounds -px - margin - nx, -py - margin, 2 * px + 2 * margin + 2 * nx, 2 * py + 2 * margin
    game.physics.startSystem Phaser.Physics.P2JS
    game.physics.p2.restitution = 0.5
    
    floorGroup = game.add.group()
    floorGroup.z = 0.5

    balls = game.add.physicsGroup(Phaser.Physics.P2JS)

    onFieldGroup = game.add.physicsGroup(Phaser.Physics.P2JS)
    onFieldGroup.z = 1

    collisionGroupPlayers = game.physics.p2.createCollisionGroup()
    collisionGroupBalls = game.physics.p2.createCollisionGroup()
    collisionGroupWalls = game.physics.p2.createCollisionGroup()
    collisionGroupObstacles = game.physics.p2.createCollisionGroup()

    game.physics.p2.updateBoundsCollisionGroup()
    game.cameraPos = new (Phaser.Point)(0, 0)
    game.cameraLerp = 0.04
    this.createWalls()

    ballMaterial = game.physics.p2.createMaterial('ballMaterial')
    wallMaterial = game.physics.p2.createMaterial('wallMaterial')
    playerMaterial = game.physics.p2.createMaterial('playerMaterial')
    postMaterial = game.physics.p2.createMaterial('postMaterial')
    
    ballBallCM = game.physics.p2.createContactMaterial(ballMaterial, ballMaterial, restitution: 0.8)
    ballPlayerCM = game.physics.p2.createContactMaterial(ballMaterial, playerMaterial, restitution: 0.2)
    ballPostCM = game.physics.p2.createContactMaterial(ballMaterial, postMaterial, restitution: 0.3)
    
    fieldBounds = new (Phaser.Rectangle)(-px, -py, 2 * px, 2 * py)
    for [1..20]
      ball = balls.create(fieldBounds.randomX, fieldBounds.randomY, 'ball')
      ball.tint = this.randomColor()
      ball.scale.set mapSettings.ballRadius / 16.0
      ball.body.setCircle mapSettings.ballRadius
      ball.body.mass = 0.3
      ball.body.setMaterial ballMaterial
      ball.body.damping = 0.5
      ball.body.fixedRotation = true
      ball.body.setCollisionGroup collisionGroupBalls
      ball.body.collides [
        collisionGroupPlayers
        collisionGroupBalls
        collisionGroupWalls
        collisionGroupObstacles
      ]
    for xx in [-1,1] 
      for yy in [-1,1]
        post = onFieldGroup.create(px * xx, ny * yy, 'white')
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
    ship = game.add.sprite(fieldBounds.centerX, fieldBounds.centerY, 'white')
    ship.tint = 0xFF9900
    ship.inner_image = game.add.sprite(0, 0, 'clown')
    ship.inner_image.anchor.setTo 0.5
    ship.inner_image.scale.set 0.7
    ship.addChild ship.inner_image
    ship.smoothed = false
    #ship.animations.add('fly', [0,1,2,3,4,5], 10, true);
    #ship.play('fly');
    #  Create our physics body. A circle assigned the playerCollisionGroup
    game.physics.p2.enable ship, false
    ship.scale.set mapSettings.playerRadius / 16.0
    ship.body.fixedRotation = true
    ship.body.setCircle mapSettings.playerRadius
    ship.body.damping = 0.9
    ship.body.restitution = 0.2
    ship.body.setCollisionGroup collisionGroupPlayers
    ship.body.collides [
      collisionGroupPlayers
      collisionGroupBalls
      collisionGroupObstacles
    ]
    ship.body.coolDown = 0
    ship.body.setMaterial playerMaterial
    #  Just to display the bounds
    
    graphics = game.add.graphics(0, 0)
    graphics.lineStyle 4, 0xffd900, 1
    graphics.drawRect -px, -py, px*2, py*2
    floorGroup.add(graphics)
    
    cursors = game.input.keyboard.addKeys(
      'up': Phaser.KeyCode.UP
      'down': Phaser.KeyCode.DOWN
      'left': Phaser.KeyCode.LEFT
      'right': Phaser.KeyCode.RIGHT
      'shoot': Phaser.KeyCode.X)

  update: ->
    if cursors.shoot.isDown
      ship.body.isShooting = true
    else
      ship.body.isShooting = false
    accel = if ship.body.isShooting then shootingAccel else maxAccel
    
    if cursors.left.isDown
      ship.body.force.x = -accel
    else if cursors.right.isDown
      ship.body.force.x = accel
    if cursors.up.isDown
      ship.body.force.y = -accel
    else if cursors.down.isDown
      ship.body.force.y = accel
    b1 = ship.body
    if b1.isShooting and ship.body.coolDown < game.time.totalElapsedSeconds()
      k = 0
      while k < balls.children.length
        b2 = balls.children[k].body
        diffx = b1.x - (b2.x)
        diffy = b1.y - (b2.y)
        len = Math.sqrt(diffx * diffx + diffy * diffy)
        dist = len - (mapSettings.ballRadius) - (mapSettings.playerRadius)
        if dist > 5
          k++
          continue
        b1.coolDown = game.time.totalElapsedSeconds() + 0.1
        diffx /= len
        diffy /= len
        b2.velocity.x -= diffx * mapSettings.shootPower
        b2.velocity.y -= diffy * mapSettings.shootPower
        k++
    game.cameraPos.x += (ship.x - (game.cameraPos.x)) * game.cameraLerp
    # smoothly adjust the x position
    game.cameraPos.y += (ship.y - (game.cameraPos.y)) * game.cameraLerp
    # smoothly adjust the y position
    game.camera.focusOnXY game.cameraPos.x, game.cameraPos.y
    # apply smoothed virtual positions to actual camera
    return

)


