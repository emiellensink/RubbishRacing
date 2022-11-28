//
//  GameScene.swift
//  swiftdemo
//
//  Created by Emiel Lensink on 02/10/2017.
//  Copyright © 2017 Emiel Lensink. All rights reserved.
//

import SpriteKit
import GameplayKit

enum Direction {
	case left
	case right
	case none
}

class GameScene: SKScene {

	private let scrollTime = 10.0
	
	private var trackSections: [SKNode] = []
	private var trackSectionNames = [
		"//trackSection1",
		"//trackSection2",
		"//trackSection3",
		"//trackSection4"
	]
	
	private var player: SKNode?
	private var playerCar: SKNode?
	private var carLayer: SKNode?
	
	private var sectionSize: CGFloat = 2048.0
	private var lastTime: TimeInterval = 0.0
	private var timeToNextCar: TimeInterval = 2.0
	private var invincible = false
	
	private var movingInDirection: Direction = .none {
		didSet {
			if movingInDirection != oldValue {
				switch movingInDirection {
				case .none:
					break
				case .left:
					player?.run(SKAction.rotate(toAngle: 0.5, duration: 0.4))
					camera?.run(SKAction.rotate(toAngle: -0.25, duration: 0.4))
				case .right:
					player?.run(SKAction.rotate(toAngle: -0.5, duration: 0.4))
					camera?.run(SKAction.rotate(toAngle: 0.25, duration: 0.4))
				}
			}
		}
	}
	
	private func randomCarSprite() -> SKNode {
		let colors = ["black", "blue", "green", "red", "yellow"]
		let type = ["1", "2", "3", "4", "5"]
		
		let randomColor = colors[0 <> colors.count]
		let randomType = type[0 <> type.count]

		let randomName = "car_\(randomColor)_\(randomType)"

		let sprite = SKSpriteNode(imageNamed: randomName)
		return sprite
	}
	
	private func crashCar() {
		movingInDirection = .none
		invincible = true
		
		camera?.run(SKAction.rotate(toAngle: 0, duration: 0.3))
		
		let center = SKAction.moveTo(x: 0.0, duration: 0.1)
		let rotate = SKAction.rotate(toAngle: 0, duration: 0.1)

		let scaleUp = SKAction.scale(to: 20.0, duration: 0.3)
		let scaleDown = SKAction.scale(to: 1.0, duration: 0.6)
		
		let sequence = SKAction.sequence([center, rotate])
		let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
		
		carLayer?.removeAllChildren()
		player?.run(sequence)

		playerCar?.run(scaleSequence) {
			self.invincible = false
		}
	}
	
	private func switchDirection() {
		guard invincible == false else { return }		
		movingInDirection = movingInDirection == .left ? .right : .left
	}
	
	override func didMove(to view: SKView) {
		
		for name in trackSectionNames {
			guard let section = self.childNode(withName: name) else { continue }
			trackSections.append(section)
		}

		let size = sectionSize * CGFloat(trackSections.count)
		let scrollAction = SKAction.moveBy(x: 0.0, y: -size, duration: scrollTime)
		let repeater = SKAction.repeatForever(scrollAction)
		
		for section in trackSections { section.run(repeater) }
		
		camera = childNode(withName: "//camera") as? SKCameraNode
		player = childNode(withName: "//player")
		carLayer = childNode(withName: "//carLayer")
		playerCar = childNode(withName: "//hero")

		physicsWorld.contactDelegate = self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		switchDirection()
	}
    
    override func update(_ currentTime: TimeInterval) {
		guard let player = player else { return }

		let interval = currentTime - lastTime
		
		// Player movement
		let position = player.position
		let rotation = player.zRotation
		
		let distanceCovered = CGFloat(interval * (Double(sectionSize) / scrollTime))
		
		let toMove = sin(rotation) * distanceCovered * 4.7
		player.position = CGPoint(x: position.x - toMove, y: position.y)
		
		// Add opponent cars
		timeToNextCar -= interval
		if timeToNextCar < 0.0 {
			let sprite = randomCarSprite()
			
			carLayer?.addChild(sprite)

			let horizontal = -300 <> 300
			sprite.position = CGPoint(x: horizontal, y: 2048)
			sprite.name = "car"
		
			// Set up collisions
			let physics = SKPhysicsBody(rectangleOf: sprite.frame.size)
			physics.contactTestBitMask = 0x01
			physics.isDynamic = false
			physics.affectedByGravity = false
			
			sprite.physicsBody = physics
			
			let drivingSpeed = scrollTime * 1.3
			
			let drive = SKAction.moveBy(x: 0, y: -4096, duration: drivingSpeed)
			let finish = SKAction.removeFromParent()
			let sequence = SKAction.sequence([drive, finish])
			
			sprite.run(sequence)
			
			timeToNextCar = Double(500 <> 1500) / 1000
		}

		// See if we are still on the track
		let over = nodes(at: player.position)
		let roads = over.compactMap { $0.name == "road" ? $0 : nil }
		
		if let road = roads.first as? SKTileMapNode {
			let positionInRoad = player.convert(CGPoint(x: 0, y:0), to: road)
			
			let row = road.tileRowIndex(fromPosition: positionInRoad)
			let column = road.tileColumnIndex(fromPosition: positionInRoad)
			
			if road.tileGroup(atColumn: column, row: row) == nil && !invincible {
				crashCar()
			}
		}
		
		// Update track sections for inifinite scrolling
		for section in trackSections {
			let position = section.position
			if position.y < -sectionSize {
				section.position = CGPoint(x: position.x, y: position.y + 8192.0)
			}
		}
		
		lastTime = currentTime
    }
}

extension GameScene: SKPhysicsContactDelegate {
	
	func didBegin(_ contact: SKPhysicsContact) {
		
		guard invincible == false else { return }
		
		if let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node {
			if nodeA.name == "oil" || nodeB.name == "oil" {
				switchDirection()
			}
			
			if nodeA.name == "car" || nodeB.name == "car" {
				crashCar()
			}
		}
	}
}
