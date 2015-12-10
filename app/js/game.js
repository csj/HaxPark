// Generated by CoffeeScript 1.10.0
var balls, collisionGroupBalls, collisionGroupObstacles, collisionGroupPlayers, collisionGroupWalls, cursors, game, mapSettings, maxAccel, ship, shootingAccel, walls;

mapSettings = {
  outOfBoundsMargin: 100,
  halfPlayingWidth: 400,
  halfPlayingHeight: 250,
  halfNetHeight: 80,
  netDepth: 40,
  ballRadius: 12,
  playerRadius: 20,
  postRadius: 8,
  shootPower: 350
};

maxAccel = 300;

shootingAccel = 200;

collisionGroupPlayers = null;

collisionGroupBalls = null;

collisionGroupWalls = null;

collisionGroupObstacles = null;

cursors = null;

ship = null;

balls = null;

walls = null;

game = new Phaser.Game(800, 600, Phaser.CANVAS, 'phaser-example', {
  preload: function() {
    game.load.image('white', 'assets/sprites/white.png');
    game.load.image('player', 'assets/sprites/mario.gif');
    game.load.image('ball', 'assets/sprites/white_outline.png', 32, 32);
    return game.load.image('grass', 'assets/sprites/grass.jpg');
  },
  createWalls: function() {
    var cen, cx, d, floorGroup, graphics, i, len, len1, n, ref, shape, sim, x, y;
    walls = new p2.Body({
      mass: 0,
      position: [0, 0]
    });
    sim = game.physics.p2;
    x = mapSettings.halfPlayingWidth;
    y = mapSettings.halfPlayingHeight;
    n = mapSettings.halfNetHeight;
    d = mapSettings.netDepth;
    walls.addShape(new p2.Line({
      length: sim.pxmi(2 * x)
    }), [0, sim.pxmi(y)], 0);
    walls.addShape(new p2.Line({
      length: sim.pxmi(2 * x)
    }), [0, sim.pxmi(-y)], 0);
    len = sim.pxmi(y - n);
    cen = y / 2.0 + n / 2.0;
    walls.addShape(new p2.Line({
      length: len
    }), [sim.pxmi(x), sim.pxmi(cen)], Math.PI / 2.0);
    walls.addShape(new p2.Line({
      length: len
    }), [sim.pxmi(x), sim.pxmi(-cen)], Math.PI / 2.0);
    walls.addShape(new p2.Line({
      length: len
    }), [sim.pxmi(-x), sim.pxmi(cen)], Math.PI / 2.0);
    walls.addShape(new p2.Line({
      length: len
    }), [sim.pxmi(-x), sim.pxmi(-cen)], Math.PI / 2.0);
    cx = sim.pxmi(x + n / 2.0);
    walls.addShape(new p2.Line({
      length: sim.pxmi(d)
    }), [cx, sim.pxmi(n)]);
    walls.addShape(new p2.Line({
      length: sim.pxmi(d)
    }), [-cx, sim.pxmi(n)]);
    walls.addShape(new p2.Line({
      length: sim.pxmi(d)
    }), [cx, sim.pxmi(-n)]);
    walls.addShape(new p2.Line({
      length: sim.pxmi(d)
    }), [-cx, sim.pxmi(-n)]);
    walls.addShape(new p2.Line({
      length: sim.pxmi(2 * n)
    }), [sim.pxmi(x + d), 0], Math.PI / 2.0);
    walls.addShape(new p2.Line({
      length: sim.pxmi(2 * n)
    }), [sim.pxmi(-x - d), 0], Math.PI / 2.0);
    graphics = game.add.graphics(0, 0);
    graphics.lineStyle(6, 0xFFFFFF, 0.6);
    graphics.drawRect(-x, -y, x * 2, y * 2);
    graphics.drawRect(-x - d, -n, d, 2 * n);
    graphics.drawRect(x, -n, d, 2 * n);
    ref = walls.shapes;
    for (i = 0, len1 = ref.length; i < len1; i++) {
      shape = ref[i];
      shape.collisionGroup = collisionGroupWalls.mask;
      shape.collisionMask = collisionGroupBalls.mask;
    }
    game.physics.p2.world.addBody(walls);
    floorGroup = game.add.group();
    floorGroup.z = 0.5;
    floorGroup.add(graphics);
  },
  randomColor: function() {
    var dice, val;
    val = Math.floor(Math.random() * 180) + 30;
    dice = Math.random() * 6;
    switch (false) {
      case !(dice < 1):
        return 0x0000FF + val * 0x000100;
      case !(dice < 2):
        return 0x0000FF + val * 0x010000;
      case !(dice < 3):
        return 0x00FF00 + val * 0x000001;
      case !(dice < 4):
        return 0x00FF00 + val * 0x010000;
      case !(dice < 5):
        return 0xFF0000 + val * 0x000001;
      case !(dice < 6):
        return 0xFF0000 + val * 0x000100;
    }
  },
  create: function() {
    var ball, ballBallCM, ballMaterial, ballPlayerCM, ballPostCM, bmd, bmd2, fieldBounds, halfWorldHeight, halfWorldWidth, i, j, l, len1, len2, margin, nx, ny, onFieldGroup, playerMaterial, post, postMaterial, px, py, ref, ref1, wallMaterial, xx, yy;
    margin = mapSettings.outOfBoundsMargin;
    px = mapSettings.halfPlayingWidth;
    py = mapSettings.halfPlayingHeight;
    nx = mapSettings.netDepth;
    ny = mapSettings.halfNetHeight;
    halfWorldWidth = px + margin + nx;
    halfWorldHeight = py + margin;
    game.world.setBounds(-halfWorldWidth, -halfWorldHeight, 2 * halfWorldWidth, 2 * halfWorldHeight);
    game.add.tileSprite(-halfWorldWidth, -halfWorldHeight, 2 * halfWorldWidth, 2 * halfWorldHeight, 'grass');
    game.physics.startSystem(Phaser.Physics.P2JS);
    game.physics.p2.restitution = 0.5;
    collisionGroupPlayers = game.physics.p2.createCollisionGroup();
    collisionGroupBalls = game.physics.p2.createCollisionGroup();
    collisionGroupWalls = game.physics.p2.createCollisionGroup();
    collisionGroupObstacles = game.physics.p2.createCollisionGroup();
    this.createWalls();
    balls = game.add.physicsGroup(Phaser.Physics.P2JS);
    onFieldGroup = game.add.physicsGroup(Phaser.Physics.P2JS);
    onFieldGroup.z = 1;
    game.physics.p2.updateBoundsCollisionGroup();
    game.cameraPos = new Phaser.Point(0, 0);
    game.cameraLerp = 0.04;
    ballMaterial = game.physics.p2.createMaterial('ballMaterial');
    wallMaterial = game.physics.p2.createMaterial('wallMaterial');
    playerMaterial = game.physics.p2.createMaterial('playerMaterial');
    postMaterial = game.physics.p2.createMaterial('postMaterial');
    ballBallCM = game.physics.p2.createContactMaterial(ballMaterial, ballMaterial, {
      restitution: 0.8
    });
    ballPlayerCM = game.physics.p2.createContactMaterial(ballMaterial, playerMaterial, {
      restitution: 0.2,
      friction: 0
    });
    ballPostCM = game.physics.p2.createContactMaterial(ballMaterial, postMaterial, {
      restitution: 0.3
    });
    fieldBounds = new Phaser.Rectangle(-px, -py, 2 * px, 2 * py);
    bmd2 = game.add.bitmapData(37, 37);
    bmd2.circle(18, 18, 17);
    bmd2.draw('ball', 2, 2);
    for (i = 1; i <= 20; i++) {
      ball = balls.create(fieldBounds.randomX, fieldBounds.randomY, bmd2);
      ball.tint = this.randomColor();
      ball.scale.set(mapSettings.ballRadius / 16.0);
      ball.body.setCircle(mapSettings.ballRadius);
      ball.body.mass = 0.3;
      ball.body.setMaterial(ballMaterial);
      ball.body.damping = 0.5;
      ball.body.fixedRotation = true;
      ball.body.setCollisionGroup(collisionGroupBalls);
      ball.body.collides([collisionGroupPlayers, collisionGroupBalls, collisionGroupWalls, collisionGroupObstacles]);
    }
    ref = [-1, 1];
    for (j = 0, len1 = ref.length; j < len1; j++) {
      xx = ref[j];
      ref1 = [-1, 1];
      for (l = 0, len2 = ref1.length; l < len2; l++) {
        yy = ref1[l];
        post = onFieldGroup.create(px * xx, ny * yy, 'white');
        post.scale.set(mapSettings.postRadius / 16.0);
        post.body.setCircle(mapSettings.postRadius);
        post.body["static"] = true;
        post.body.setMaterial(postMaterial);
        post.body.damping = 0.5;
        post.body.setCollisionGroup(collisionGroupObstacles);
        post.body.collides([collisionGroupPlayers, collisionGroupBalls]);
      }
    }
    bmd = game.add.bitmapData(37, 37);
    bmd.circle(18, 18, 17);
    bmd.draw('white', 4, 4);
    ship = game.add.sprite(fieldBounds.centerX, fieldBounds.centerY, bmd);
    ship.originalTint = 0xFF9900;
    ship.inner_image = game.add.sprite(0, 0, 'player');
    ship.inner_image.anchor.setTo(0.5);
    ship.inner_image.scale.set(1.3);
    ship.addChild(ship.inner_image);
    ship.smoothed = true;
    game.physics.p2.enable(ship, false);
    ship.scale.set(mapSettings.playerRadius / 16.0);
    ship.body.fixedRotation = true;
    ship.body.setCircle(mapSettings.playerRadius);
    ship.body.damping = 0.9;
    ship.body.restitution = 0.2;
    ship.body.setCollisionGroup(collisionGroupPlayers);
    ship.body.collides([collisionGroupPlayers, collisionGroupBalls, collisionGroupObstacles]);
    ship.body.coolDown = 0;
    ship.body.setMaterial(playerMaterial);
    return cursors = game.input.keyboard.addKeys({
      'up': Phaser.KeyCode.UP,
      'down': Phaser.KeyCode.DOWN,
      'left': Phaser.KeyCode.LEFT,
      'right': Phaser.KeyCode.RIGHT,
      'shoot': Phaser.KeyCode.X
    });
  },
  update: function() {
    var accel, b1, b2, diffx, diffy, dist, k, len;
    if (cursors.shoot.isDown) {
      ship.body.isShooting = true;
      ship.tint = 0xFFFFFF;
    } else {
      ship.body.isShooting = false;
      ship.tint = ship.originalTint;
    }
    accel = ship.body.isShooting ? shootingAccel : maxAccel;
    if (cursors.left.isDown) {
      ship.body.force.x = -accel;
    } else if (cursors.right.isDown) {
      ship.body.force.x = accel;
    }
    if (cursors.up.isDown) {
      ship.body.force.y = -accel;
    } else if (cursors.down.isDown) {
      ship.body.force.y = accel;
    }
    b1 = ship.body;
    if (b1.isShooting && ship.body.coolDown < game.time.totalElapsedSeconds()) {
      k = 0;
      while (k < balls.children.length) {
        b2 = balls.children[k].body;
        diffx = b1.x - b2.x;
        diffy = b1.y - b2.y;
        len = Math.sqrt(diffx * diffx + diffy * diffy);
        dist = len - mapSettings.ballRadius - mapSettings.playerRadius;
        if (dist > 5) {
          k++;
          continue;
        }
        b1.coolDown = game.time.totalElapsedSeconds() + 0.1;
        diffx /= len;
        diffy /= len;
        b2.velocity.x -= diffx * mapSettings.shootPower;
        b2.velocity.y -= diffy * mapSettings.shootPower;
        k++;
      }
    }
    game.cameraPos.x += (ship.x - game.cameraPos.x) * game.cameraLerp;
    game.cameraPos.y += (ship.y - game.cameraPos.y) * game.cameraLerp;
    game.camera.focusOnXY(game.cameraPos.x, game.cameraPos.y);
  }
});
