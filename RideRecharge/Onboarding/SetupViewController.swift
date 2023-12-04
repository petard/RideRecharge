//
//  SetupViewController.swift
//  CarRemote
//
//  Created by pluto on 22.12.20.
//

import UIKit

class SetupViewController: UIViewController {

    @IBAction func laterBtnTapped(_ sender: Any) {
        User.shared.isOnboarded = true
        let destination = UIStoryboard.init(name: StoryboardIdentifiers.main.rawValue, bundle: nil).instantiateViewController(identifier: MainMapViewController.storyboardIdentifier)
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(destination)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
