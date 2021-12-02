//
//  GameScene.swift
//  Ultimate Hunter
//
//  Created by Sawyer Cherry on 11/22/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var hunter: SKSpriteNode!
    var deer: SKSpriteNode!
    var bullet: SKSpriteNode!
    
 
    private var shootButton: SKButton!
    private var jumpButton: SKButton!
    
    
    
    override func didMove(to view: SKView) {
        hunter = (self.childNode(withName: "//hunter") as! SKSpriteNode)
        deer = (self.childNode(withName: "//deer") as! SKSpriteNode)
        shootButton = (self.childNode(withName: "//shootButton") as! SKButton)
        jumpButton = (self.childNode(withName: "//jumpButton") as! SKButton)
        
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
                let bulletWidth = CGFloat(9)
                let bulletHeight = CGFloat(2.5)
                let bulletSize = CGSize(width: bulletWidth, height: bulletHeight)
                bullet.size = bulletSize
                self.addChild(bullet)
                bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
                bullet.physicsBody?.applyImpulse(CGVector(dx: 15, dy: 0))
                bullet.physicsBody?.affectedByGravity = false
            
                
            }
            self.run(shootBullet)
            
        }
        jumpButton.touchUpInside = {
            self.hunter.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 700))
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
    }
}

class SKButton: SKSpriteNode {
    var touchUpInside: () -> Void = {}
}

class SKButtonLabel: SKLabelNode {
    var touchUpInside: () -> Void = {}
}
