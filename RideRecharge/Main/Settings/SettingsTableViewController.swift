//
//  SettingsTableViewController.swift
//  CarRemote
//
//  Created by pluto on 08.12.20.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var label: UILabel!
    
    private let defaultText: String = "No home address set"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.label.text = User.shared.home?.subtitle ?? defaultText
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).font = UIFont.boldSystemFont(ofSize: 17)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.label.text = User.shared.home?.subtitle ?? defaultText
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        guard let vc = segue.destination as? SettingsHomeTableViewController else {
            return
        }
        
        vc.delegate = self
    }
    

}

extension SettingsTableViewController: SettingsHomeTableViewControllerDelegate {
    
    func didUpdateHomeLocation() {
        self.label.text = User.shared.home?.subtitle ?? defaultText
    }
    
}
