//
//  GameScene.swift
//  Ultimate Hunter
//
//  Created by Sawyer Cherry on 11/22/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var spawnTimer: CFTimeInterval = 0
    var hunter: SKSpriteNode!
    var deer: SKSpriteNode!
    var bullet: SKSpriteNode!
    var obstacleSource: SKNode!
    var obstacleLayer: SKNode!
    let scrollSpeed: CGFloat = 300
    var scrollLayer: SKNode!
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */
    
    private var shootButton: SKButton!
    private var jumpButton: SKButton!
    
    override func didMove(to view: SKView) {
        hunter = (self.childNode(withName: "//hunter") as! SKSpriteNode)
        deer = (self.childNode(withName: "//deer") as! SKSpriteNode)
        shootButton = (self.childNode(withName: "//shootButton") as! SKButton)
        jumpButton = (self.childNode(withName: "//jumpButton") as! SKButton)
        scrollLayer = self.childNode(withName: "scrollLayer")
        obstacleSource = self.childNode(withName: "obstacle")
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        
        hunter.isPaused = false
        deer.isPaused = false
        
        shootButton.touchUpInside = {
            let shootBullet = SKAction.run {
                let bullet = SKSpriteNode(imageNamed: "shot")
                bullet.anchorPoint.x = -0.075
                //let hunterHeight = self.hunter.size.height
                let hunterWidth = self.hunter.size.width
                let hunterPosition = self.hunter.parent!.parent!.position
                // random spawn bullet
                bullet.position.y = hunterPosition.y - 25//+ CGFloat.random(in: 0...hunterHeight)
                bullet.position.x = hunterPosition.x + hunterWidth / 2
                bullet.name = "shot"
                bullet.zPosition = 1
                let bulletWidth = CGFloat(9)
                let bulletHeight = CGFloat(2.5)
                let bulletSize = CGSize(width: bulletWidth, height: bulletHeight)
                bullet.size = bulletSize
                self.addChild(bullet)
                bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
                bullet.physicsBody?.applyImpulse(CGVector(dx: 5, dy: 0))
                bullet.physicsBody?.affectedByGravity = false
            }
            self.run(shootBullet)
        }
        jumpButton.touchUpInside = {
            self.hunter.physicsBody?.applyImpulse(CGVector(dx: 2, dy: 700))
        }
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
    
    func scrollWorld() {
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
        /* Update Obstacles */
        
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= -75 {
                // 26 is one half the width of an obstacle
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
        }
        
        if spawnTimer >= 1.5 {
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            
            let randomPosition =  CGPoint(x: CGFloat.random(in: 953...1653), y: 102.954)
            
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            spawnTimer = 0
        }
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
