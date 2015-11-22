
var game = new Phaser.Game(800, 600, Phaser.CANVAS, 'phaser-example', { preload: preload, create: create, update: update });

function preload() {

    game.load.spritesheet('ship', 'assets/sprites/humstar.png', 32, 32);
    game.load.spritesheet('veggies', 'assets/sprites/fruitnveg32wh37.png', 32, 32);
    game.load.image('ball', 'assets/sprites/shinyball.png');
    game.load.image('yellow', 'assets/sprites/yellow_ball.png');
    game.load.image('clown', 'assets/sprites/clown.png');
}

var ship;
var cursors;
var customBounds;
var collisionGroupBalls;
var balls;
var collisionGroupPlayers;
var collisionGroupWalls;
var wallMaterial;

function create() {
    game.world.setBounds(-600, -400, 1200, 800);

    //  The bounds of our physics simulation
    var bounds = new Phaser.Rectangle(-500, -300, 1000, 600);

    game.physics.startSystem(Phaser.Physics.P2JS);

    game.physics.p2.restitution = 0.6;
    game.physics.p2.setImpactEvents(true);

    //  Some balls to collide with
    balls = game.add.physicsGroup(Phaser.Physics.P2JS);

    collisionGroupPlayers = game.physics.p2.createCollisionGroup();
    collisionGroupBalls = game.physics.p2.createCollisionGroup();
    collisionGroupWalls = game.physics.p2.createCollisionGroup();

    game.physics.p2.updateBoundsCollisionGroup();
    game.cameraPos = new Phaser.Point(0,0);
    game.cameraLerp = 0.02;

    //  Create a new custom sized bounds, within the world bounds
    createPreviewBounds(bounds.x, bounds.y, bounds.width, bounds.height);
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

    for (var i = 0; i < 20; i++)
    {
        var ball = balls.create(bounds.randomX, bounds.randomY, 'ball');
        ball.scale.set(1.3);
        ball.body.setCircle(16 * 1.3);
        ball.body.mass = 0.5;
        ball.body.setMaterial(ballMaterial);
        ball.body.damping = 0.5;
        ball.body.setCollisionGroup(collisionGroupBalls);
        ball.body.collides([collisionGroupPlayers, collisionGroupBalls, collisionGroupWalls]);
    }

    ship = game.add.sprite(bounds.centerX, bounds.centerY, 'yellow');
    ship.inner_image = game.add.sprite(0,0,'clown');
    ship.inner_image.anchor.setTo(0.5);
    ship.inner_image.scale.set(0.4);
    ship.addChild(ship.inner_image);

    ship.scale.set(3.5);
    ship.smoothed = false;
    //ship.animations.add('fly', [0,1,2,3,4,5], 10, true);
    //ship.play('fly');

    //  Create our physics body. A circle assigned the playerCollisionGroup
    game.physics.p2.enable(ship, false);

    ship.body.fixedRotation = true;
    ship.body.setCircle(28);
    ship.body.damping = 0.9;
    ship.body.restitution = 0.2;
    ship.body.setCollisionGroup(collisionGroupPlayers);
    ship.body.collides([collisionGroupPlayers, collisionGroupBalls]);
    ship.body.coolDown = 0;
    ship.body.setMaterial(playerMaterial);

    //  Just to display the bounds
    var graphics = game.add.graphics(bounds.x, bounds.y);
    graphics.lineStyle(4, 0xffd900, 1);
    graphics.drawRect(0, 0, bounds.width, bounds.height);

    cursors = game.input.keyboard.addKeys({ 
    	'up': Phaser.KeyCode.UP, 
    	'down': Phaser.KeyCode.DOWN, 
    	'left': Phaser.KeyCode.LEFT, 
    	'right': Phaser.KeyCode.RIGHT,
    	'shoot': Phaser.KeyCode.X
   	});

}

function createPreviewBounds(x, y, w, h) {

    customBounds = { left: null, right: null, top: null, bottom: null };
    var sim = game.physics.p2;

    //  If you want to use your own collision group then set it here and un-comment the lines below
    //var mask = sim.boundsCollisionGroup.mask;
    var mask = collisionGroupWalls.mask;



    customBounds.left = new p2.Body({ mass: 0, position: [ sim.pxmi(x), sim.pxmi(y) ], angle: 1.5707963267948966 });
    customBounds.left.addShape(new p2.Plane());
    //customBounds.left.setMaterial(wallMaterial);
    customBounds.left.shapes[0].collisionGroup = mask;
    customBounds.left.shapes[0].collisionMask = collisionGroupBalls.mask;

    customBounds.right = new p2.Body({ mass: 0, position: [ sim.pxmi(x + w), sim.pxmi(y) ], angle: -1.5707963267948966 });
    customBounds.right.addShape(new p2.Plane());
    //customBounds.right.setMaterial(wallMaterial);
    customBounds.right.shapes[0].collisionGroup = mask;
    customBounds.right.shapes[0].collisionMask = collisionGroupBalls.mask;

    customBounds.top = new p2.Body({ mass: 0, position: [ sim.pxmi(x), sim.pxmi(y) ], angle: -3.141592653589793 });
    customBounds.top.addShape(new p2.Plane());
    //customBounds.top.setMaterial(wallMaterial);
    customBounds.top.shapes[0].collisionGroup = mask;
    customBounds.top.shapes[0].collisionMask = collisionGroupBalls.mask;

    customBounds.bottom = new p2.Body({ mass: 0, position: [ sim.pxmi(x), sim.pxmi(y + h) ] });
    customBounds.bottom.addShape(new p2.Plane());
    //customBounds.bottom.setMaterial(wallMaterial);
    customBounds.bottom.shapes[0].collisionGroup = mask;
    customBounds.bottom.shapes[0].collisionMask = collisionGroupBalls.mask;

    sim.world.addBody(customBounds.left);
    sim.world.addBody(customBounds.right);
    sim.world.addBody(customBounds.top);
    sim.world.addBody(customBounds.bottom);
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
			if (len > 57) continue;
			b1.coolDown = game.time.totalElapsedSeconds() + 0.2;
			
			diffx /= len;
			diffy /= len;

			var power = 400;
			b2.velocity.x -= diffx * power;
			b2.velocity.y -= diffy * power;
	    }
	}

	game.cameraPos.x += (ship.x - game.cameraPos.x) * game.cameraLerp; // smoothly adjust the x position
	game.cameraPos.y += (ship.y - game.cameraPos.y) * game.cameraLerp; // smoothly adjust the y position
	game.camera.focusOnXY(game.cameraPos.x, game.cameraPos.y); // apply smoothed virtual positions to actual camera
}
