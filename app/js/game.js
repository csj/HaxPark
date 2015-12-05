
var game = new Phaser.Game(800, 600, Phaser.CANVAS, 'phaser-example', { preload: preload, create: create, update: update });

function preload() {

    game.load.spritesheet('ship', 'assets/sprites/humstar.png', 32, 32);
    game.load.spritesheet('veggies', 'assets/sprites/fruitnveg32wh37.png', 32, 32);
    game.load.image('ball', 'assets/sprites/shinyball.png');
    game.load.image('white', 'assets/sprites/white.png');
    game.load.image('clown', 'assets/sprites/clown.png');
}

var ship;
var cursors;
var customBounds;
var balls;
var obstacles;
var collisionGroupBalls;
var collisionGroupPlayers;
var collisionGroupWalls;
var collisionGroupObstacles;
var wallMaterial;

var mapSettings = {
    outOfBoundsMargin: 100,
    halfPlayingWidth: 500,
    halfPlayingHeight: 300,
    halfNetHeight: 100,
    netDepth: 20,
    ballRadius: 20,
    playerRadius: 32,
    postRadius: 8,
    shootPower: 400
};

function create() {
    var margin = mapSettings.outOfBoundsMargin;
    var px = mapSettings.halfPlayingWidth;
    var py = mapSettings.halfPlayingHeight;
    var nx = mapSettings.netDepth;
    var ny = mapSettings.halfNetHeight;

    game.world.setBounds(
        -px - margin - nx,
        -py - margin,
        2*px + 2*margin + 2*nx,
        2*py + 2*margin
    );

    game.physics.startSystem(Phaser.Physics.P2JS);
    game.physics.p2.restitution = 0.6;

    balls = game.add.physicsGroup(Phaser.Physics.P2JS);
    obstacles = game.add.physicsGroup(Phaser.Physics.P2JS);

    collisionGroupPlayers = game.physics.p2.createCollisionGroup();
    collisionGroupBalls = game.physics.p2.createCollisionGroup();
    collisionGroupWalls = game.physics.p2.createCollisionGroup();
    collisionGroupObstacles = game.physics.p2.createCollisionGroup();

    game.physics.p2.updateBoundsCollisionGroup();
    game.cameraPos = new Phaser.Point(0,0);
    game.cameraLerp = 0.04;

    createWalls();

    var ballMaterial = game.physics.p2.createMaterial('ballMaterial');
    var wallMaterial = game.physics.p2.createMaterial('wallMaterial');
    var playerMaterial = game.physics.p2.createMaterial('wallMaterial');

    var ballBallCM = game.physics.p2.createContactMaterial(
    	ballMaterial, ballMaterial,
    	{restitution: 0.8}
    );

    var ballPlayerCM = game.physics.p2.createContactMaterial(
    	ballMaterial, playerMaterial,
    	{restitution: 0.3}
    );

    var fieldBounds = new Phaser.Rectangle(-px, -py, 2*px, 2*py);

    for (var i = 0; i < 20; i++)
    {
        var ball = balls.create(fieldBounds.randomX, fieldBounds.randomY, 'ball');
        ball.scale.set(mapSettings.ballRadius / 16.0);
        ball.body.setCircle(mapSettings.ballRadius);
        ball.body.mass = 0.5;
        ball.body.setMaterial(ballMaterial);
        ball.body.damping = 0.5;
        ball.body.setCollisionGroup(collisionGroupBalls);
        ball.body.collides([collisionGroupPlayers, collisionGroupBalls, collisionGroupWalls, collisionGroupObstacles]);
    }

    for (var xx = -1; xx <= 1; xx += 2) for (var yy = -1; yy <= 1; yy += 2) {    
        var post = obstacles.create(px*xx, ny*yy, 'white');
        console.log("creating post at " + nx*xx + "," + ny*yy);
        post.scale.set(mapSettings.postRadius / 16.0);
        post.body.setCircle(mapSettings.postRadius);
        post.body.static = true;
        post.body.setMaterial(ballMaterial);
        post.body.damping = 0.5;
        post.body.setCollisionGroup(collisionGroupObstacles);
        post.body.collides([collisionGroupPlayers, collisionGroupBalls]);
    }

    ship = game.add.sprite(fieldBounds.centerX, fieldBounds.centerY, 'white');
    ship.tint = 0xdd8822;
    ship.inner_image = game.add.sprite(0,0,'clown');
    ship.inner_image.anchor.setTo(0.5);
    ship.inner_image.scale.set(0.7);
    ship.addChild(ship.inner_image);

    ship.smoothed = false;
    //ship.animations.add('fly', [0,1,2,3,4,5], 10, true);
    //ship.play('fly');

    //  Create our physics body. A circle assigned the playerCollisionGroup
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

    //  Just to display the bounds
    var graphics = game.add.graphics(fieldBounds.x, fieldBounds.y);
    graphics.lineStyle(4, 0xffd900, 1);
    graphics.drawRect(0, 0, fieldBounds.width, fieldBounds.height);

    cursors = game.input.keyboard.addKeys({ 
    	'up': Phaser.KeyCode.UP, 
    	'down': Phaser.KeyCode.DOWN, 
    	'left': Phaser.KeyCode.LEFT, 
    	'right': Phaser.KeyCode.RIGHT,
    	'shoot': Phaser.KeyCode.X
   	});

}

function createWalls() {
    var x = mapSettings.halfPlayingWidth;
    var y = mapSettings.halfPlayingHeight;

    customBounds = { left: null, right: null, top: null, bottom: null };
    var sim = game.physics.p2;

    var mask = collisionGroupWalls.mask;

    var left = new p2.Body({ 
        mass: 0, 
        position: [ sim.pxmi(-x), sim.pxmi(-y) ], 
        angle: Math.PI / 2.0 
    });
    left.addShape(new p2.Plane());
    //left.setMaterial(wallMaterial);
    left.shapes[0].collisionGroup = mask;
    left.shapes[0].collisionMask = collisionGroupBalls.mask;

    var right = new p2.Body({
        mass: 0, 
        position: [ sim.pxmi(x), sim.pxmi(y) ], 
        angle: -Math.PI / 2.0 
    });
    right.addShape(new p2.Plane());
    //right.setMaterial(wallMaterial);
    right.shapes[0].collisionGroup = mask;
    right.shapes[0].collisionMask = collisionGroupBalls.mask;

    var top = new p2.Body({ 
        mass: 0, 
        position: [ sim.pxmi(-x), sim.pxmi(-y) ], 
        angle: -Math.PI 
    });
    top.addShape(new p2.Plane());
    //top.setMaterial(wallMaterial);
    top.shapes[0].collisionGroup = mask;
    top.shapes[0].collisionMask = collisionGroupBalls.mask;

    var bottom = new p2.Body({ 
        mass: 0, 
        position: [ sim.pxmi(x), sim.pxmi(y) ],
        angle: 0
    });
    bottom.addShape(new p2.Plane());
    //bottom.setMaterial(wallMaterial);
    bottom.shapes[0].collisionGroup = mask;
    bottom.shapes[0].collisionMask = collisionGroupBalls.mask;

    sim.world.addBody(left);
    sim.world.addBody(right);
    sim.world.addBody(top);
    sim.world.addBody(bottom);


}

var maxAccel = 400;
var shootingAccel = 200;

function update() {
	if (cursors.shoot.isDown) {
		ship.body.isShooting = true;
	}
	else {
		ship.body.isShooting = false;
	}

	var accel = ship.body.isShooting ? shootingAccel : maxAccel;

    if (cursors.left.isDown)
    {
    	ship.body.force.x = -accel;
    }
    else if (cursors.right.isDown)
    {
        ship.body.force.x = accel;
    }

    if (cursors.up.isDown)
    {
    	ship.body.force.y = -accel;
    }
    else if (cursors.down.isDown)
    {
        ship.body.force.y = accel;
    }

    var b1 = ship.body;
    if (b1.isShooting && ship.body.coolDown < game.time.totalElapsedSeconds()) {
	    for (var k=0; k<balls.children.length; k++) {
	    	var b2 = balls.children[k].body;
		    var diffx = b1.x - b2.x;
			var diffy = b1.y - b2.y;
			var len = Math.sqrt(diffx*diffx + diffy*diffy);
            var dist = len
              - mapSettings.ballRadius
              - mapSettings.playerRadius;
			if (dist > 5) continue;
			b1.coolDown = game.time.totalElapsedSeconds() + 0.1;
			
			diffx /= len;
			diffy /= len;

			b2.velocity.x -= diffx * mapSettings.shootPower;
			b2.velocity.y -= diffy * mapSettings.shootPower;
	    }
	}

	game.cameraPos.x += (ship.x - game.cameraPos.x) * game.cameraLerp; // smoothly adjust the x position
	game.cameraPos.y += (ship.y - game.cameraPos.y) * game.cameraLerp; // smoothly adjust the y position
	game.camera.focusOnXY(game.cameraPos.x, game.cameraPos.y); // apply smoothed virtual positions to actual camera
}
