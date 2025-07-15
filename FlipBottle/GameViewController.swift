//
//  GameViewController.swift
//  FlipBottle2
//
//  Created by Wardatul Amalia Safitri on 14/07/25.
//

import GameplayKit
import SpriteKit
import UIKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            let scene = GameScene(size: view.bounds.size)
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill

            // Present the scene
            view.presentScene(scene)

            view.ignoresSiblingOrder = true

            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = true
        }
    }
}
