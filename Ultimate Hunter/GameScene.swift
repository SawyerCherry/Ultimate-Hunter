//
//  GameScene.swift
//  Ultimate Hunter
//
//  Created by Sawyer Cherry on 11/22/21.
//

import SpriteKit
import GameplayKit

enum GameSceneState {
    case active, gameOver, gameWon
}

struct PhysicsCategory {
    static let None:    UInt32 = 0       // 0000000 0
    static let Bush:    UInt32 = 0b1     // 0000001 1
    static let Deer:    UInt32 = 0b10    // 0000010 2
    static let Player:  UInt32 = 0b100   // 0000100 4
    static let Bullet:  UInt32 = 0b1000  // 0001000 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var spawnTimer: CFTimeInterval = 0
    var hunter: SKSpriteNode!
    var deer: SKSpriteNode!
    var deerHP: Int = 100
    var bullet: SKSpriteNode!
    var obstacleSource: SKNode!
    var obstacleLayer: SKNode!
    let scrollSpeed: CGFloat = 600
    var scrollLayer: SKNode!
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */
    var randomJumpTime = CFTimeInterval.random(in: 3..<10)
    var gameState: GameSceneState = .active
    
    private var shootButton: SKButton!
    private var jumpButton: SKButton!
    var buttonRestart: MSButtonNode!
    
    override func didMove(to view: SKView) {
        hunter = (self.childNode(withName: "//hunter") as! SKSpriteNode)
        deer = (self.childNode(withName: "//deer") as! SKSpriteNode)
        shootButton = (self.childNode(withName: "//shootButton") as! SKButton)
        jumpButton = (self.childNode(withName: "//jumpButton") as! SKButton)
        buttonRestart = (self.childNode(withName: "buttonRestart") as! MSButtonNode)
        scrollLayer = self.childNode(withName: "scrollLayer")
        obstacleSource = self.childNode(withName: "//obstacle") 
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        physicsWorld.contactDelegate = self
        
        hunter.name = "hunter"
        hunter.isPaused = false
        deer.isPaused = false
        
        deer.physicsBody?.categoryBitMask = PhysicsCategory.Deer
        deer.physicsBody?.collisionBitMask = PhysicsCategory.Bullet
        deer.physicsBody?.contactTestBitMask = PhysicsCategory.Bullet
        
        
        obstacleSource.physicsBody?.categoryBitMask = PhysicsCategory.Bush
        obstacleSource.physicsBody?.collisionBitMask = PhysicsCategory.Player
        obstacleSource.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
        
        shootButton.touchUpInside = {
            let shootBullet = SKAction.run {
                let bullet = SKSpriteNode(imageNamed: "shot")
                bullet.anchorPoint.x = -0.075
                //let hunterHeight = self.hunter.size.height
                let hunterWidth = self.hunter.size.width
                let hunterPosition = self.hunter.parent!.parent!.position
                // random spawn bullet
                bullet.position.y = hunterPosition.y - 25
                bullet.position.x = hunterPosition.x + hunterWidth / 2
                bullet.name = "bullet"
                bullet.zPosition = 1
                let bulletWidth = CGFloat(9)
                let bulletHeight = CGFloat(2.5)
                let bulletSize = CGSize(width: bulletWidth, height: bulletHeight)
                bullet.size = bulletSize
                self.addChild(bullet)
                bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
                bullet.physicsBody?.applyImpulse(CGVector(dx: 5, dy: 0))
                bullet.physicsBody?.affectedByGravity = false
                bullet.physicsBody?.categoryBitMask = PhysicsCategory.Bullet
                bullet.physicsBody?.collisionBitMask = PhysicsCategory.Deer
                bullet.physicsBody?.contactTestBitMask = PhysicsCategory.Deer
                //     debris.physicsBody = SKPhysicsBody(circleOfRadius: radius)
                //     debris.physicsBody?.categoryBitMask = PhysicsCategory.Debris
                //     debris.physicsBody?.collisionBitMask = PhysicsCategory.Ship | PhysicsCategory.Debris
                //     debris.physicsBody?.contactTestBitMask = PhysicsCategory.Ship | PhysicsCategory.Debris
            }
            
            self.run(shootBullet)
        }
        jumpButton.touchUpInside = {
            self.hunter.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 700))
        }
    
        
        
        buttonRestart.selectedHandler = {
          let skView = self.view as SKView?
          let scene = GameScene(fileNamed:"GameScene") as GameScene?
          scene?.scaleMode = .aspectFill
          skView?.presentScene(scene)
        }
        buttonRestart.state = .MSButtonNodeStateHidden
        self.run(jumpTheDeer())
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        //make the hunter jump
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        buttonTap(at: location)
    }
    
    private func buttonTap(at location: CGPoint) {
        let node = atPoint(location)
        
        if let button = node as? SKButton {
            button.touchUpInside()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {

        // get the hunter velocity
        let velocityY = hunter.physicsBody?.velocity.dy ?? 0
        
        // cap the velocity
        if velocityY > 900 {
            hunter.physicsBody?.velocity.dy = 400
        }

        scrollWorld()
        updateObstacles()
        
        spawnTimer += fixedDelta
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactAMask = contact.bodyA.contactTestBitMask
        let contactBMask =  contact.bodyB.contactTestBitMask
        
        let collision = contactAMask | contactBMask
        print("its here")
        if collision == PhysicsCategory.Player | PhysicsCategory.Bush {
            print("collided")
            displayGameOver()
            
            
        } else if collision == PhysicsCategory.Bullet | PhysicsCategory.Player {
            print("shot collided with player")
        }
            
            
    }
    
    func scrollWorld() {  /// this works!
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            if obstaclePosition.x <= -75 {
                obstacle.removeFromParent()
            }
        }
        
        if spawnTimer >= 2.5 {
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            
            let randomPosition =  CGPoint(x: CGFloat.random(in: 1200...1653), y: 102.954) // this is good
            
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            spawnTimer = 0
        }
    }
    
    func jumpTheDeer() -> SKAction {
        let jumpDeer = SKAction.run {
            self.deer.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 700))
        }
        let action = SKAction.repeatForever(
            
            .sequence(
                [
                    jumpDeer,
                    .wait(forDuration:
                            TimeInterval(1)
                    )
                ]
            )
        )
        return action
    }
    
    func displayGameOver() {
        let gameOverScene = GameConditionScene(fileNamed: "GameOver")!
        gameOverScene.scaleMode = .aspectFill
        view?.presentScene(gameOverScene)
    }
    
    func displayGameWon() {
        let gameWonScene = GameConditionScene(fileNamed: "GameWon")!
        gameWonScene.scaleMode = .aspectFill
        view?.presentScene(gameWonScene)
    }
    
    
}

class GameConditionScene: SKScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let game =  GameScene(fileNamed: "GameScene")!
        game.scaleMode = .aspectFill
        view?.presentScene(game)
    }
}

class SKButton: SKSpriteNode {
    var touchUpInside: () -> Void = {}
}

class SKButtonLabel: SKLabelNode {
    var touchUpInside: () -> Void = {}
}





//    func displayLoseGame() {
//        let gameOverScene = GameOverScene(fileNamed: "GameOver")!
//        gameOverScene.scaleMode = .aspectFill
//        view?.presentScene(gameOverScene)
//    }
