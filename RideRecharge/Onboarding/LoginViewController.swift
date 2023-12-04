//
//  LoginViewController.swift
//  CarRemote
//
//  Created by pluto on 22.12.20.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var vin: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var username: UITextField!
    
    @IBAction func usernameDoneTapped(_ sender: Any) {
        self.username.resignFirstResponder()
    }
    @IBAction func passwordDoneTapped(_ sender: Any) {
        self.password.resignFirstResponder()
    }
    @IBAction func vinDoneTapped(_ sender: Any) {
        self.vin.resignFirstResponder()
    }
    
    
    @IBAction func signInBtnTapped(_ sender: Any) {
        
        guard
            let username = self.username.text,
            let password = self.password.text else {
            return;
        }
        
        self.password.resignFirstResponder()
        self.username.resignFirstResponder()
        self.vin.resignFirstResponder()
        
        Task {
            do {
                let account = try await CustomerAccount.load(using: username, password: password)
                
                if account.vehicleIds.isEmpty {
                    throw ServiceError.noVehiclesFound
                }
                
                if account.vehicleIds.count > 1 {
                    throw ServiceError.VINMultipleVehicles(vehicleIds: account.vehicleIds)
                }
                
                self.vin.text = account.vehicleIds.first!
                self.completeOnboarding()
                return
                
            } catch ServiceError.VINMultipleVehicles(let vehicleIds) {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: LoginViewController.vehicleIdSelectionSegue, sender: vehicleIds)
                    return;
                }
            } catch {
                DispatchQueue.main.async {
                    Toast.popError(message: error.localizedDescription, controller: self)
                    return;
                }
            }
        }
        
    }

    private static let vehicleIdSelectionSegue: String = "vehicleIdSelection"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.layout(textfield: vin)
        self.layout(textfield: password)
        self.layout(textfield: username)
        
        self.username.text = User.shared.credentials?.username
        self.password.text = User.shared.credentials?.password
        self.vin.text = User.shared.credentials?.vin
    }
    
    private func layout(textfield: UITextField) {
        textfield.layer.cornerRadius = 5.0
        textfield.layer.masksToBounds = true
        textfield.layer.borderColor = UIColor.systemGray.cgColor
        textfield.layer.borderWidth = 1.0
    }
    
    func completeOnboarding() {
        VOC.shared.set(volvoid: self.username.text ?? "", password: self.password.text ?? "", vin: self.vin.text ?? "")
        User.shared.set(username: self.username.text ?? "", password: self.password.text ?? "", vin: self.vin.text ?? "")
        User.shared.isOnboarded = true

        let destination = UIStoryboard.init(name: StoryboardIdentifiers.main.rawValue, bundle: nil).instantiateViewController(identifier: MainMapViewController.storyboardIdentifier)
        DispatchQueue.main.async {
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(destination)
        }
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
        guard
            let vc = segue.destination as? VehicleSelectionTableViewController,
            let vehicleIds = sender as? [String] else {
            return
        }
        
        vc.vehicleIds = vehicleIds
        vc.username = self.username.text
        vc.password = self.password.text

     }
    
    @IBAction func unwindFromVehicleSelection(unwindSegue: UIStoryboardSegue) {
        // unwind to login
        if
            let source =  unwindSegue.source as? VehicleSelectionTableViewController,
            let destination = unwindSegue.destination as? LoginViewController {
            destination.vin.text = source.selectedVehicleId
            destination.completeOnboarding()
        }
    }
    
}
