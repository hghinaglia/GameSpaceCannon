//
//  HGMyScene.m
//  Game-Space Cannon
//
//  Created by Hector Ghinaglia on 7/30/14.
//  Copyright (c) 2014 Hector Ghinaglia. All rights reserved.
//

#import "HGMyScene.h"
#import "HGMenu.h"
#import "HGBall.h"
#import <AVFoundation/AVFoundation.h>


@implementation HGMyScene
{
    /* Se crean estas variables debido a que es preferible preparar unas capas con todos los elementos
     que se requieran para cierta ocasión y ocultarlos y mostrarlos cuando sean necesarios en ves de
     colocarlos todo directo sobre la scene, en este caso se refiere a lo que respecta el cannon */
    SKNode *_mainLayer;
    
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKSpriteNode *_pauseButton;
    SKSpriteNode *_resumeButton;
    
    SKLabelNode *_scoreLabel;
    SKLabelNode *_pointLabel;
    
    BOOL _didShoot;
    BOOL _gameOver;
    
    SKAction *_bounceSound;
    SKAction *_deepExplosionSound;
    SKAction *_explosionSound;
    SKAction *_laserSound;
    SKAction *_zapSound;
    SKAction *_shieldUpSound;
    
    AVAudioPlayer *_audioPlayer;
    
    HGMenu *_menu;
    
    NSUserDefaults *_userDefaults;
    
    NSMutableArray *_shieldPool;
    
    int _killCount;
}

#pragma mark - Static Consts
// constante de velocidad del tiro
static const CGFloat SHOOT_SPEED = 1000.0;

// constantes que se utilizan para calcular trayectoria y velocidad de un halo
static const CGFloat kHGHaloLowAngle = 200.0 * M_PI / 180.0;
static const CGFloat kHGHaloHighAngle = 340.0 * M_PI / 180.0;
static const CGFloat kHGHaloSpeed = 100.0;

// constantes que se utilizan para establecer la categoria dentro del bit mask (posiciones de memoria)
static const uint32_t kHGHaloCategory = 0x1 << 0;   // 0x00000001
static const uint32_t kHGBallCategory = 0x1 << 1;   // 0x00000010
static const uint32_t kHGEdgeCategory = 0x1 << 2;   // 0x00000100
static const uint32_t kHGShieldCategory = 0x1 << 3; // 0x00001000
static const uint32_t kHGLifeBarCategory = 0x1 << 4; // 0x00010000
static const uint32_t kHGShieldUpCategory = 0x1 << 5; // 0x00100000
static const uint32_t kHGMultiUpCategory = 0x1 << 6; // 0x01000000

// constante para almacenar el top score en el user defaults
static NSString *const kHGTopScoreKey = @"TopScore";

#pragma mark - Static Functions
// static inline (metodos de esta clase que se llaman sin hacer referencia a self)
static inline CGVector radiansToVector(CGFloat radians)
{
    // método estatico que permite convertir radianes en vectores dado un valor en radian
    
    // creamos variable tipo vector que maneja valores X,Y
    CGVector vector;
    // convertimos los valores de radianes a sus respectivos X,Y aplicando matematica de seno y cosenos
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

static inline CGFloat randomInRange(CGFloat min, CGFloat max)
{
    // generamos numero aleatorio entre 0 y 1
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value  * (max - min) + min;
}

#pragma mark - Event Methods
-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size])
    {
        // asignamos el delegado de las colisiones
        self.physicsWorld.contactDelegate = self;
        
        /* DESCATIVANDO LA GRAVEDAD */
        
        // como en este ejemplo estamos en el espacio, no queremos gravedad, entonces la desactivamos
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        
        /* AGREGANDO EL FONDO */
        
        // instanciamos el fondo con la imagen deseada
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
        // posicionando el fondo
        background.position = CGPointZero;
        // cambiando el punto de anclaje al borde inferior izquierdo = (0,0)
        background.anchorPoint = CGPointZero;
        /* Cambiamos el modo en que se muestra la imagen, por defecto las imagenes siempre se muestran en modo
         alpha para permitir transparencias, debido a que no necesitamos que el fondo sea transparente
         lo cambiamos para que pinte los px tal cual como son, y así se torna un poco menos pesado de 
         dibujar y por lo tanto mas eficiente que con el modo alpha */
        background.blendMode = SKBlendModeReplace;
        // agregamos el fondo al scene
        [self addChild:background];
        
        /* AGREGANDO LIMITES (EDGES) */
        
        // como los bordes estan pintados en el background no creamos un sprite node sino un nodo normal y lo instanciamos
        SKNode *leftEdge = [[SKNode alloc] init];
        // definimos el cuerpo
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0, self.size.height + 100)];
        // le damos la posicion en este caso el izquierdo seria (0,0)
        leftEdge.position = CGPointZero;
        // asignamos la categoria
        leftEdge.physicsBody.categoryBitMask = kHGEdgeCategory;
        
        // como los bordes estan pintados en el background no creamos un sprite node sino un nodo normal y lo instanciamos
        SKNode *rightEdge = [[SKNode alloc] init];
        // definimos el cuerpo
        rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0, self.size.height + 100)];
        // le damos la posicion en este caso el izquierdo seria (ancho pantalla ,0)
        rightEdge.position = CGPointMake(self.size.width, 0);
        // asignamos la categoria
        rightEdge.physicsBody.categoryBitMask = kHGEdgeCategory;
        
        // agregamos ambos bordes a la escena
        [self addChild:leftEdge];
        [self addChild:rightEdge];
        
        /* AGREGANDO EL MAIN LAYER */
        
        // instanciamos la main layer
        _mainLayer = [[SKNode alloc] init];
        // agregamos la main layer a la escena
        [self addChild:_mainLayer];
        
        /* AGREGANDO EL CANNON */
        
        // instanciamos el cannon con la imagen deseada
        _cannon= [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        // posicionamos el cannon abajo en el centro
        _cannon.position = CGPointMake(size.width * 0.5, 0.0);
        // agregamos el cannon a la main layer
        [self addChild:_cannon];
        
        /* NOTA: la imagen del cannon esta apuntando a la derecha porq en las medidas angulares
         el valor 0 esta completamente a la derecha */
        
        /* CREANDO ACCIONES DE ROTACION DEL CANNON */
        
        /* La rotación el cannon será automatica, irá de izquierda a derecha y viceversa a cierta
         velocidad, para ello la accion que vamos a ejecutar para rotar sera una secuencia de acciones
         es decir un array de SKActions que se ejecuta uno despues de otro, en este caso usamos solo dos
         accinoes, una que rote de derecha a izquierda en 2 segundo, y otra que rote de izquierda a derecha
         en otros 2 segundos, y el angulo de rotación vendra dado por la mitad de PI, es decir, medio circulo */
        SKAction *rotateCannon = [SKAction sequence:@[ [SKAction rotateByAngle:M_PI duration:2],
                                                       [SKAction rotateByAngle:-M_PI duration:2] ]];
        // Asignamos la acción de rotacion al cannon mediante otra accion que repetira el proceso infinitamente
        [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
        
        /* CREANDO ACCIONES DE GENERACION DE HALOS */
        
        // creamos un nuevo halo con la secuenca de accion de aparecer 1 halo cada 2 segundos
        SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                                   [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
        // agregamos la accion al scene con otra accion de repetir siempre
        [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:@"SpawnHalo"];
        
        /* AGEGANDO ACCION DE APARICION DE SHIELD POWER UP*/
        
        SKAction *spawnShieldPowerUp = [SKAction sequence:@[[SKAction waitForDuration:15 withRange:4],
                                                            [SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnShieldPowerUp]];
        
        /* AGREGANDO INDICADOR DE MUNICIONES */
        
        // creamos indicador de municiones
        _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
        // cambiamos el punto de anclaje
        _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
        // obtiene la misma posicion que el cannon
        _ammoDisplay.position = _cannon.position;
        
        // creamos la accion de recargar cada segundo
        SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1],
                                                       [SKAction runBlock:^{
            // aumentamos ammo siempre y cuando no este en multimode
            if (!self.multiMode)
                self.ammo++;
        }]]];
        // ejecutamos la accion siempre
        [self runAction:[SKAction repeatActionForever:incrementAmmo]];
        // agregamos el indicador al escene
        [self addChild:_ammoDisplay];
        
        /* AGREGANDO SHIELD POOL */
        
        _shieldPool = [[NSMutableArray alloc] init];
        
        /* AGREGANDO LOS 6 ESCUDOS DE PROTECCION */
        
        for (int i = 0; i < 6; i++)
        {
            // creamos el escudo
            SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
            // establecemos el nombre del nodo
            shield.name = @"shield";
            // lo posicionamos dependiendo de i
            shield.position = CGPointMake(35 + (50 * i), 90);
            // le creamos el cuerpo fisico
            shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
            // le asignamos la nueva categoria
            shield.physicsBody.categoryBitMask = kHGShieldCategory;
            // no queremos que se muevan entonces la colision se pasa a cero
            shield.physicsBody.collisionBitMask = 0;
            // agregamos los escudos al shield pool
            [_shieldPool addObject:shield];
        }
        
        /* AGREGANDO BOTON DE PAUSE */
        
        _pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"PauseButton"];
        _pauseButton.position = CGPointMake(self.size.width - 30, 20);
        [self addChild:_pauseButton];
        
        /* AGREGANDO BOTON DE RESUME */
        
        _resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"ResumeButton"];
        _resumeButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
        [self addChild:_resumeButton];
        
        /* AGREGANDO ETIQUETA DE PUNTAJE */
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.position = CGPointMake(15, 10);
        _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _scoreLabel.fontSize = 15;
        [self addChild:_scoreLabel];
        
        /* AGREGANDO ETIQUETA DE MULTIPLICADOR DE PUNTAJE */
        
        _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _pointLabel.position = CGPointMake(15, 30);
        _pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _pointLabel.fontSize = 15;
        [self addChild:_pointLabel];
        
        /* PRE CARGANDO LOS SONIDOS */
        
        _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
        _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
        _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
        _laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
        _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
        _shieldUpSound = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
        
        /* AGREGANDO EL MENU */
        
        _menu = [[HGMenu alloc] init];
        _menu.position = CGPointMake(self.size.width * 0.5, self.size.height - 220);
        [self addChild:_menu];
        
        /* CONFIGURANDO VALORES INICIALES */
        
        self.ammo = 5;
        self.score = 0;
        self.pointValue = 1;
        _gameOver = YES;
        _scoreLabel.hidden = YES;
        _pointLabel.hidden = YES;
        _pauseButton.hidden = YES;
        _resumeButton.hidden = YES;
        _menu.playMusic = YES;
        
        /* CARGANDO TOP SCORE */
        
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _menu.topScore = [_userDefaults integerForKey:kHGTopScoreKey];
        
        /* CARGANDO MUSICA DE FONDO */
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"ObservingTheStar" withExtension:@"caf"];
        NSError *error = nil;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        
        if (!_audioPlayer)
        {
            NSLog(@"Error loading audio player: %@", error);
        }
        else
        {
            _audioPlayer.numberOfLoops = -1;
            [_audioPlayer play];
        }
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches)
    {
        if (!_gameOver && !self.gamePaused)
        {
            if (![_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]])
            {
                _didShoot = YES;
            }
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {   // estamos en game over y ya podemos tocar el menu
        if (_gameOver && _menu.touchable)
        {
            // encuentra el nodo que se toco en menu en la posicion donde se toco y se guarda en n
            SKNode *n = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            // si el nodo que toque se llama playbutton
            if ([n.name isEqualToString:@"PlayButton"])
            {
                // instanciamos el juego
                [self newGame];
            }
            // el nodo que toca es el de musica
            else if ([n.name isEqualToString:@"MusicOnOffButton"])
            {
                // cambia el valor de musica
                [_menu setPlayMusic:!_menu.playMusic];
                // ajusta volumen musica
                _audioPlayer.volume = (_menu.playMusic) ? 0.8 : 0.0;
            }
        }
        else if (!_gameOver)
        {
            if (self.gamePaused)
            {
                if ([_resumeButton containsPoint:[touch locationInNode:_resumeButton.parent]])
                {
                    [self setGamePaused:NO];
                }
            }
            else if ([_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]])
            {
                [self setGamePaused:YES];
            }
        }
    }
}

-(void)didSimulatePhysics
{
    /* se coloca aca por cuestion de timing, en vez de llamarlo al tocar la pantalla, llamas al metodo al
     finalizar la simulacion de la fisica, por lo que parace que la bala esta saliendo del cannon apropiadamente*/
    if (_didShoot)
    {
        // si hay balas disponible, puede disparar
        if (self.ammo > 0)
        {
            // disminuimos el valor de las balas y disparamos
            self.ammo--;
            [self shoot];
            
            // estamos en multimodo, debo disparar 4 veces mas
            if (self.multiMode)
            {
                for (int i = 1; i < 5; i++)
                {
                    [self performSelector:@selector(shoot) withObject:nil afterDelay:0.1 * i];
                }
                // me quede sin balas, apagamos el multimode y recargamos 5 balas
                if (self.ammo == 0)
                {
                    self.multiMode = NO;
                    self.ammo = 5;
                }
            }
        }
        
        _didShoot = NO;
    }
    
    /* Aun cuando los nodos no se encuentren en la pantalla, la fisica sigue calculandose
     para cada nodo (en este caso bala) que se dispare, por lo tanto tendremos que eliminar
     los nodos que ya no se encuentren en la pantalla por cuestiones de rendimiento. */
    
    // obtenemos la lista de todos los nodos llamados bullet y ejecutamos un bloque con ellos
    [_mainLayer enumerateChildNodesWithName:@"bullet" usingBlock:^(SKNode *node, BOOL *stop) {
        
        // si el dono posee el metodo updateTrail entonces se ejecuta
        if ([node respondsToSelector:@selector(updateTrail)])
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0.0];
        
        
        // la posicion del nodo no esta contenida dentro del frame del juego, entonces se remueve
        if (!CGRectContainsPoint(self.frame, node.position))
        {
            [node removeFromParent];
            self.pointValue = 1;
        }
    }];
    
    // obtenemos la lista de todos los nodos llamados shieldUp y ejecutamos un bloque con ellos
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        // si el escudo salio de la pantalla
        if (node.frame.size.width + node.position.x < 0)
        {
            [node removeFromParent];
        }
    }];
    
    // obtenemos la lista de todos los nodos llamados multiUp y ejecutamos un bloque con ellos
    [_mainLayer enumerateChildNodesWithName:@"multiUp" usingBlock:^(SKNode *node, BOOL *stop) {
        // si el multi up salio de la pantalla
        if (node.position.x - node.frame.size.width > self.size.width)
        {
            [node removeFromParent];
        }
    }];
    
    // obtenemos la lista de todos los nodos llamados halo y ejecutamos un bloque con ellos
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        // la posicion del nodo no esta contenida dentro del frame del juego
        if (node.position.y + node.frame.size.height < 0)
            // removemos el nodo
            [node removeFromParent];
    }];
}

-(void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
}

#pragma mark - Setup Methods
-(void)gameOver
{
    // funcion que permite parar y resetear el juego
    
    // al iniciar gameover queremos que TODO EXPLOTE!!!!
    
    // explotando todos los halos
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosionAt:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    // explotando todos los cannon balls
    [_mainLayer enumerateChildNodesWithName:@"bullet" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    // explotando todos los shields
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        // antes de remover un escudo, lo guardamos en la shield pool
        [_shieldPool addObject:node];
        [node removeFromParent];
    }];
    // eliminando todos los power ups de multi shoot
    [_mainLayer enumerateChildNodesWithName:@"multiUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    // eliminando todos los powerups de shield
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    // seteamos los scores
    _menu.score = _score;
    if(_score > _menu.topScore)
    {
        _menu.topScore = _score;
        [_userDefaults setInteger:self.score forKey:kHGTopScoreKey];
        [_userDefaults synchronize];
    }
    
    
    // si perdimos mostramos el menu y decimos que es game over
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    _pauseButton.hidden = YES;
    _gameOver = YES;
    [self runAction:[SKAction waitForDuration:1] completion:^{
        [_menu show];
    }];
    
}

-(void)newGame
{
    [_mainLayer removeAllChildren];
    
    // agregando los shield al main layer y sacandolos de la shield pool
    while (_shieldPool.count > 0)
    {
        [_mainLayer addChild:[_shieldPool objectAtIndex:0]];
        [_shieldPool removeObjectAtIndex:0];
    }
    
    /* AGREGANDO BARRA DE VIDA */
    
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0)
                                                       toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
    lifeBar.physicsBody.categoryBitMask = kHGLifeBarCategory;
    [_mainLayer addChild:lifeBar];
    
    /* CONFIGURANDO VALORES INICIALES */
    
    // si iniciamos el juego decimos que no estamos en game over y ocultamos el menu
    _gameOver = NO;
    [_menu hide];
    // mostramos el scoreLabel y el multiplicador al iniciar el juego y el pause button
    _scoreLabel.hidden = NO;
    _pointLabel.hidden = NO;
    _pauseButton.hidden = NO;
    // la propiedad ammo se inicia en 5
    self.ammo = 5;
    // El puntaje se inicializa en 0
    self.score = 0;
    // el multiplicador empieza en 1
    self.pointValue = 1;
    // cada nuevo juego killcount va a ser cero
    _killCount = 0;
    // apagamos multimode
    self.multiMode = NO;
    
    // iniciamos la velocidad de aparicion de halos a 1 segundo
    [self actionForKey:@"SpawnHalo"].speed = 1.0;
}

#pragma mark - Helper Methods
-(void)setAmmo:(int)ammo
{
    if (ammo >= 0 && ammo <= 5)
    {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d",ammo]];
    }
}

-(void)setScore:(int)score
{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d",score];
}

-(void)setPointValue:(int)pointValue
{
    _pointValue = pointValue;
    _pointLabel.text = [NSString stringWithFormat:@"Points: x%d",pointValue];
}

-(void)setGamePaused:(BOOL)gamePaused
{
    if (!_gameOver)
    {
        _gamePaused = gamePaused;
        _pauseButton.hidden = gamePaused;
        _resumeButton.hidden = !gamePaused;
        self.paused = gamePaused;
    }
}

-(void)setMultiMode:(BOOL)multiMode
{
    _multiMode = multiMode;
    if (multiMode)
    {
        _cannon.texture = [SKTexture textureWithImageNamed:@"GreenCannon"];
    }
    else
    {
        _cannon.texture = [SKTexture textureWithImageNamed:@"Cannon"];
    }
}

-(void)shoot
{
    // método que permite activar un disparo (si tiene disponible)
    
    // instanciamos la bala con la imagen deseada
    HGBall *ball = [HGBall spriteNodeWithImageNamed:@"Ball"];
    // agregamos un nombre al nodo ball
    ball.name = @"bullet";
    // creamos un vector que obtiene los valores de la posicion a traves de la rotacion actual del cannon
    CGVector rotationVector = radiansToVector(_cannon.zRotation);
    // Calcula la posicion de aparicion de la bala dependiendo de la rotacion actual del cannon y su tamano
    ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                                _cannon.position.y + (_cannon.size.width * 0.5 * rotationVector.dy));
    // Agregamos cuerpo físico a la bala
    
    /* El Diametro de la bala en pixeles es 24 pero lo necesitamos en puntos
     El diametro de la bala en puntos es 24/2 = 12 pero necesitamos el radio
     El radio de la bala en puntos es 12/2 = 6.
     al tener un cuerpo fisico, la bala ya recibe interacciones como la gravedad*/
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6];
    // aplicamos velocidad a la bala multiplicando la rotación por otra fuente de atraccion, es decir la velocidad de disparo
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
    // establecemos la "rebotacion" de la bala a un factor 1 para q no disminuya velocidad
    ball.physicsBody.restitution = 1.0;
    // modificamos la friccion del aire como estamos en el espacio, no hay friccion
    ball.physicsBody.linearDamping = 0.0;
    // modificamos la friccon contra objetos a cero
    ball.physicsBody.friction = 0.0;
    // asignamos la categoria
    ball.physicsBody.categoryBitMask = kHGBallCategory;
    // al asignar eso la bola reacciona ante la colision con los bordes, pero no reacciona con los halos
    ball.physicsBody.collisionBitMask = kHGEdgeCategory;
    // explosion al tocar el borde
    ball.physicsBody.contactTestBitMask = kHGEdgeCategory | kHGShieldUpCategory | kHGMultiUpCategory;
    
    // agregamos la bala al main layer
    [_mainLayer addChild:ball];
    
    // sonido de disparo
    [self runAction:_laserSound];
    
    /* CREANDO ESTELA */
    
    // cargamos el sks
    NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
    // asignamos el archivo un nodo
    SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
    // su posicion es afectada en el main layer por la bala
    ballTrail.targetNode = _mainLayer;
    // lo agregamos al main layer
    [_mainLayer addChild:ballTrail];
    // asignamos el trail a la clase ball
    ball.trail = ballTrail;
    // actualizando el trail
    [ball updateTrail];
    
}

-(void)spawnShieldPowerUp
{
    // creando escudo de bono
    
    if (_shieldPool.count > 0)
    {
        SKSpriteNode *shieldUp = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shieldUp.name = @"shieldUp";
        shieldUp.position = CGPointMake(self.size.width + shieldUp.size.width, randomInRange(150, self.size.height - 100));
        shieldUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shieldUp.physicsBody.categoryBitMask = kHGShieldUpCategory;
        shieldUp.physicsBody.collisionBitMask = 0;
        shieldUp.physicsBody.velocity = CGVectorMake(-100, randomInRange(-40, 40));
        shieldUp.physicsBody.angularVelocity = M_PI;
        shieldUp.physicsBody.linearDamping = 0.0;
        shieldUp.physicsBody.angularDamping = 0.0;
        [_mainLayer addChild:shieldUp];
    }
}

-(void)spawnMultiShotPowerUp
{
    SKSpriteNode *multiUp = [SKSpriteNode spriteNodeWithImageNamed:@"MultiShotPowerUp"];
    multiUp.name = @"multiUp";
    multiUp.position = CGPointMake(-multiUp.size.width, randomInRange(150, self.size.height - 100));
    multiUp.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:12];
    multiUp.physicsBody.categoryBitMask = kHGMultiUpCategory;
    multiUp.physicsBody.collisionBitMask = 0.0;
    multiUp.physicsBody.velocity = CGVectorMake(100, randomInRange(-40, 40));
    multiUp.physicsBody.angularVelocity = M_PI;
    multiUp.physicsBody.linearDamping = 0.0;
    multiUp.physicsBody.angularDamping = 0.0;
    [_mainLayer addChild:multiUp];
}

-(void)spawnHalo
{
    // incrementando la velocidad de aparicion de halos
    SKAction *spawnHaloAction = [self actionForKey:@"SpawnHalo"];
    // aumentamos la velocidad de la accion siempre y cuando la velocidad no sobrepase los 1.5 segundos
    spawnHaloAction.speed += (spawnHaloAction.speed < 1.5) ? 0.01 : 0;
    
    // creando nodo halo
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    // especificamos el nombre del nodo
    halo.name = @"halo";
    // utilizamos los metodos ya creados para generar aleatoreamente la posicion de aparicio del halo
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)),
                                self.size.height + (halo.size.height * 0.5));
    // activamos y configuramos la fisica del halo, estableciendo su cuerpo
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];
    // le damos una direccion al momento de aparecer utilizando las constantes establecidas
    CGVector direction = radiansToVector(randomInRange(kHGHaloLowAngle, kHGHaloHighAngle));
    // aplicamos la velocidad multiplicando una constante por la direccion obtenida
    halo.physicsBody.velocity = CGVectorMake(direction.dx * kHGHaloSpeed, direction.dy * kHGHaloSpeed);
    // establecemos los mismo valores fisicos que la bala en cuanto a friccion y rebote
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    // asignamos la categoria
    halo.physicsBody.categoryBitMask = kHGHaloCategory;
    // los halo reaccionan a la colision contra el edge pero no reaccionan contra los ball
    halo.physicsBody.collisionBitMask = kHGEdgeCategory;
    // notifica cuando ocurre una colision con la categoria especificada
    halo.physicsBody.contactTestBitMask = kHGBallCategory | kHGShieldCategory | kHGLifeBarCategory | kHGEdgeCategory;
    
    /* POWER UPS */
    
    // variable que cuenta cuantos halos hay en pantalla
    int haloCount = 0;
    // recorremos todos los nodos en pantalla
    for (SKNode *node in _mainLayer.children)
        // encontramos nodo con nombre halo
        if ([node.name isEqualToString:@"halo"])
            // aumentamos el contador
            haloCount++;
    
    // hay 4 halos en pantalla
    if (haloCount == 4)
    {
        // cargamos la nueva textura
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        // instanciamos el direccionario de userData (userData esta en todos los nodos)
        halo.userData = [[NSMutableDictionary alloc] init];
        // agregamos el valor @YES (NSNumner with bool) y el key
        [halo.userData setValue:@YES forKey:@"Bomb"];
    }
    else if (!_gameOver && arc4random_uniform(6) == 0)
    {
        // estamos jugando, y ocurra un probabilidad de 1 en 6
        
        // cargamos la nueva textura
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        // instanciamos el direccionario de userData (userData esta en todos los nodos)
        halo.userData = [[NSMutableDictionary alloc] init];
        // agregamos el valor @YES (NSNumner with bool) y el key
        [halo.userData setValue:@YES forKey:@"Multiplier"];
    }
    
    // agregamos el halo a la main layer
    [_mainLayer addChild:halo];
}

-(void)addExplosionAt:(CGPoint)position withName:(NSString *)name
{
    // creamos el path al archivo sks de la explosion
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    // con el path instanciamos el nodo tipo emitter
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    // asignamos la posición
    explosion.position = position;
    // creamos una secuencia de acciones, primero esperar por la animacion, y luego removerlo del escene
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    // ejecutamos la accion
    [explosion runAction:removeExplosion];
    // se introduce en el escene
    [_mainLayer addChild:explosion];
}


#pragma mark - SKPhysicsContact Delegate
-(void)didBeginContact:(SKPhysicsContact *)contact
{
    /* En este metodo se sabe que dos cuerpos han colisionado, y se definen como bodyA y bodyB pero
     no se conoce cual cuerpo es cual, para ellos aplicamos logica de categoryBitMask, se definen dos cuerpos
     primero y segundo, posterior a esto se evalua cual cuerpo A o B tiene la menor categoria y se le asigna
     al firstBody, y el de mayor categoria se le asigna al secondBody, como Halo tiene la menor categoria
     podemos saber que halo siempre estará en el firstBody, pero para ello debemos evaluar que ciertamente
     los objetos que estan colisionando son el Halo y la Bala y se remueven ambos de la escena*/
    
    SKPhysicsBody *firstBody; // aca guardamos el halo
    SKPhysicsBody *secondBody; // aca guardamos la bala
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask == kHGHaloCategory && secondBody.categoryBitMask == kHGBallCategory)
    {
        self.score += self.pointValue;
        
        // llamamos al metodo exlosion cuando se detecto la colision y se le pasa la posicion del halo golpeado.
        [self addExplosionAt:firstBody.node.position withName:@"HaloExplosion"];
        
        // sonido de explosion
        [self runAction:_explosionSound];
        
        // si golpeo un multiplicador
        if ([[firstBody.node.userData valueForKeyPath:@"Multiplier"] boolValue])
        {
            self.pointValue ++;
        }
        // si golepo la bomba
        else if ([[firstBody.node.userData valueForKeyPath:@"Bomb"] boolValue])
        {
            // se coloca nil para que el siguiente algoritmo no lo detecte, este igual se elimina al final
            firstBody.node.name = nil;
            
            // obtenemos la lista de todos los nodos llamados halo y ejecutamos un bloque con ellos
            [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
                self.score += self.pointValue;
                [self addExplosionAt:node.position withName:@"HaloExplosion"];
                [node removeFromParent];
            }];
        }
        
        // aumentamos la cantidad de halos destruida
        _killCount++;
        
        // killcount es multiplo de 10
        if (_killCount % 10 == 0)
        {
            // creamos un bono de multishoot
            [self spawnMultiShotPowerUp];
        }
        
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        
    }
    
    // notificacion de colision entre halo y shield, explota el halo y se remueven ambis
    if (firstBody.categoryBitMask == kHGHaloCategory && secondBody.categoryBitMask == kHGShieldCategory)
    {
        // llamamos al metodo exlosion cuando se detecto la colision y se le pasa la posicion del halo golpeado.
        [self addExplosionAt:firstBody.node.position withName:@"HaloExplosion"];
        
        // sonido de explosion
        [self runAction:_explosionSound];
        
        // si un halo colisiona con 2 shield al mismo tiempo, solo elimina 1
        firstBody.categoryBitMask = 0;
        
        // si bomba golpea escudo
        if ([[firstBody.node.userData valueForKeyPath:@"Bomb"] boolValue])
        {
            // obtenemos la lista de todos los nodos llamados shield y ejecutamos un bloque con ellos
            [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
                // agregamos los shield al pool antes de eliminarlos
                [_shieldPool addObject:node];
                [node removeFromParent];
            }];
        }
        
        [firstBody.node removeFromParent];
        // antes de remover un escudo, lo guardamos en la shield pool
        [_shieldPool addObject:secondBody.node];
        [secondBody.node removeFromParent];
    }
    
    // notificacion de colision entre halo y la barra de vida
    if (firstBody.categoryBitMask == kHGHaloCategory && secondBody.categoryBitMask == kHGLifeBarCategory)
    {
        [self addExplosionAt:secondBody.node.position withName:@"LifeBarExplosion"];
        [secondBody.node removeFromParent];
        
        // sonido de explosion
        [self runAction:_deepExplosionSound];
        
        // listo se acabo el juego
        [self gameOver];
    }
    
    // notificacion de colision entre bala y los edges
    if (firstBody.categoryBitMask == kHGBallCategory && secondBody.categoryBitMask == kHGEdgeCategory)
    {
        // sonido de rebote
        [self runAction:_bounceSound];
        // explosion minima al tocar bordes
        [self addExplosionAt:contact.contactPoint withName:@"BounceExplosion"];
        
        // nos aseguramos que el firstbody sea de clase Ball
        if ([firstBody.node isKindOfClass:[HGBall class]])
        {
            // aumentamos el numero de rebote
            ((HGBall *) firstBody.node).bounces ++;
            // si rebota mas de 3 veces
            if (((HGBall *) firstBody.node).bounces > 3)
            {
                [firstBody.node removeFromParent];
                self.pointValue = 1;
            }
        }
    }
    
    // notificacion de colision entre halo y los edges
    if (firstBody.categoryBitMask == kHGHaloCategory && secondBody.categoryBitMask == kHGEdgeCategory)
    {
        // sonido de rebote
        [self runAction:_zapSound];
    }
    
    // notificacion de colision ball y shield power up
    if (firstBody.categoryBitMask == kHGBallCategory && secondBody.categoryBitMask == kHGShieldUpCategory)
    {
        // hay escudos en el pool
        if (_shieldPool.count > 0)
        {
            // numero aletario (para tomar un escudo aleatoreamente
            int randomIndex = arc4random_uniform((int)_shieldPool.count);
            // agregamos el escudo de nuevo en el juego
            [_mainLayer addChild:[_shieldPool objectAtIndex:randomIndex]];
            // removemos el escudo agregado al juego del shield pool
            [_shieldPool removeObjectAtIndex:randomIndex];
            // reproducimos sonido
            [self runAction:_shieldUpSound];
        }

        // removemos la ball
        [firstBody.node removeFromParent];
        // removemos el shield power up
        [secondBody.node removeFromParent];
    }
    
    // notificacion de colision ball y multi mode power up
    if (firstBody.categoryBitMask == kHGBallCategory && secondBody.categoryBitMask == kHGMultiUpCategory)
    {
        // entramos a multimode
        [self setMultiMode:YES];
        // reproducimos sonido (por ahora el del escudo)
        [self runAction:_shieldUpSound];
        
        // recargamos el ammo
        self.ammo = 5;
        
        // removemos la ball
        [firstBody.node removeFromParent];
        // removemos el multimode power up
        [secondBody.node removeFromParent];
    }
    
    
    
}






@end
