//
//  GameScene.swift
//  SpriteKitTrial
//
//  Created by Jason Miracle Gunawan on 11/07/25.
//

import GameplayKit
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKShapeNode!
    var startJumpPosition: CGPoint?
    var platforms: [SKSpriteNode] = []
    var jumpDirection: CGFloat = 0
    var jumpGuide: SKShapeNode?
    var restartButton: SKLabelNode!
    var lastTapTime: TimeInterval = 0

    let playerCategory: UInt32 = 0x1 << 0
    let platformCategory: UInt32 = 0x1 << 1

    var startTouchLocation: CGPoint?
    var score: UInt32 = 0
    var scoreLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        backgroundColor = .cyan

        let cam = SKCameraNode()
        cam.position = CGPoint(x: frame.midX, y: frame.midY)
        camera = cam
        addChild(cam)

        createPlayer()
        createInitialPlatforms()
        createRestartButton()
        createScoreLabel()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            startTouchLocation = touch.location(in: self)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //        guard let touch = touches.first else { return }
        //        let location = touch.location(in: self)
        //        jumpDirection = location.x < frame.midX ? -1 : 1
        //        showJumpGuide()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Restart button logic
        let nodesAtPoint = nodes(at: location)
        if nodesAtPoint.contains(where: { $0.name == "restartButton" }) {
            print("Restart tapped!")
            restartScene()
            return
        }

        if isPlayerOnPlatform() {
            guard let start = startTouchLocation,
                let touch = touches.first
            else { return }

            let end = touch.location(in: self)
            let dx = start.x - end.x
            let dy = start.y - end.y
            let vector = CGVector(dx: dx, dy: dy)

            let length = sqrt(dx * dx + dy * dy)
            if length == 0 { return }

            let force = CGVector(dx: vector.dx * 0.8, dy: vector.dy * 0.8)
            print("\(force)")
            let velocity = player.physicsBody?.velocity ?? CGVector(dx: 0, dy: 0)
            print("\(velocity)")

            player.physicsBody?.applyImpulse(force)

            var spin = 0.0
            if dx > 0 {
                spin = -length * 0.2
            } else {
                spin = length * 0.2
            }
            player.physicsBody?.angularVelocity = spin

            startTouchLocation = nil
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if player.position.y > frame.midY {
            camera?.position.y = player.position.y

            platforms = platforms.filter {
                $0.position.y > camera!.position.y - 400
            }
            while platforms.count < 10 {
                let x = CGFloat.random(in: 50...frame.width - 50)
                let y = (platforms.last?.position.y ?? 0) + 100
                let newPlatform = createPlatform(at: CGPoint(x: x, y: y))
                platforms.append(newPlatform)
            }
        }

        if player.position.x < -50 {
            player.position.x = frame.width + 50
        } else if player.position.x > frame.width + 50 {
            player.position.x = -50
        }

        //Count Score
        let velocity = player.physicsBody?.velocity ?? .zero
        if abs(velocity.dy) == 0.0 && isPlayerOnPlatform() {
            guard let startY = startJumpPosition?.y else {
                startJumpPosition = player.position
                return
            }

            if (player.position.y - startY) > 20 {
                score += 1
                scoreLabel.text = "\(score)"
                startJumpPosition = player.position
            }
        }
    }

    func showJumpGuide() {
        jumpGuide?.removeFromParent()

        let path = CGMutablePath()
        let start = player.position
        let jumpVelocity = CGVector(dx: 200 * jumpDirection, dy: 800)
        let gravity = physicsWorld.gravity
        let dt: CGFloat = 0.1
        var position = start
        var velocity = jumpVelocity

        path.move(to: position)

        for _ in 0..<30 {
            velocity.dx += gravity.dx * dt
            velocity.dy += gravity.dy * dt
            position.x += velocity.dx * dt
            position.y += velocity.dy * dt
            path.addLine(to: position)
        }

        let arc = SKShapeNode(path: path)
        arc.strokeColor = .orange
        arc.lineWidth = 2
        arc.zPosition = 100

        jumpGuide = arc
        addChild(arc)
    }

    func removeJumpGuide() {
        jumpGuide?.removeFromParent()
        jumpGuide = nil
    }

    func createPlayer() {
        player = SKShapeNode(
            rectOf: CGSize(width: 20, height: 40),
            cornerRadius: 8
        )
        player.fillColor = .gray
        player.position = CGPoint(x: frame.midX, y: frame.midY)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 40))
        body.linearDamping = 1.0
        body.friction = 1.0
        body.restitution = 0.3
        body.allowsRotation = true
        body.categoryBitMask = playerCategory
        body.contactTestBitMask = platformCategory
        body.collisionBitMask = platformCategory

        player.physicsBody = body
        addChild(player)
    }

    func createPlatform(at position: CGPoint) -> SKSpriteNode {
        let platform = SKSpriteNode(
            color: .brown,
            size: CGSize(width: 100, height: 20)
        )
        platform.position = position

        let body = SKPhysicsBody(rectangleOf: platform.size)
        body.isDynamic = false
        body.contactTestBitMask = playerCategory
        //body.collisionBitMask = playerCategory
        body.categoryBitMask = platformCategory
        body.friction = 5

        platform.physicsBody = body
        addChild(platform)

        return platform
    }

    func createInitialPlatforms() {
        for i in 0..<10 {
            let x = CGFloat.random(in: 50...frame.width - 50)
            let y = CGFloat(i) * 200 + 100
            let platform = createPlatform(at: CGPoint(x: x, y: y))
            platforms.append(platform)
        }
    }

    func isPlayerOnPlatform() -> Bool {
        // Batas toleransi untuk perbedaan posisi (karena fisika tidak selalu presisi)
        let verticalTolerance: CGFloat = 2.0

        for platform in platforms {
            let playerBottomY = player.frame.minY
            let platformTopY = platform.frame.maxY

            // Cek apakah posisi horizontal player ada di atas platform
            let isHorizontallyAligned =
                player.frame.maxX > platform.frame.minX
                && player.frame.minX < platform.frame.maxX

            // Cek apakah posisi vertikal player berada di atas platform dengan toleransi
            let isVerticallyOnTop =
                abs(playerBottomY - platformTopY) <= verticalTolerance

            if isHorizontallyAligned && isVerticallyOnTop {
                return true
            }
        }
        return false
    }

    func createRestartButton() {
        restartButton = SKLabelNode(text: "Restart")
        restartButton.fontName = "AvenirNext-Bold"
        restartButton.fontSize = 32
        restartButton.fontColor = .white
        restartButton.position = CGPoint(
            x: frame.midX - 100,
            y: camera!.position.y - 100
        )
        restartButton.zPosition = 1000
        restartButton.name = "restartButton"

        camera?.addChild(restartButton)
    }

    func restartScene() {
        if let currentScene = self.scene {
            let newScene = GameScene(size: currentScene.size)
            newScene.scaleMode = currentScene.scaleMode
            let transition = SKTransition.fade(withDuration: 0.5)
            view?.presentScene(newScene, transition: transition)
        }
    }

    func createScoreLabel() {
        scoreLabel = SKLabelNode(text: "\(score)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 45
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(
            x: frame.midX - 200,
            y: camera!.position.y - 300
        )

        camera?.addChild(scoreLabel)
    }
}
