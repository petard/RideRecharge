//
//  SettingsAccountTableViewController.swift
//  CarRemote
//
//  Created by pluto on 27.11.20.
//

import UIKit

protocol SettingsAccountTableViewControllerDelegate :AnyObject {
    func didUpdateVOCAccount()
}

class SettingsAccountTableViewController: UITableViewController {
    
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var vin: UITextField!
    
    @IBAction func usernameDoneBtnTapped(_ sender: Any) {
        self.saveBtn.isEnabled = true
        self.username.resignFirstResponder()
    }
    
    @IBAction func passwordDoneBtnTapped(_ sender: Any) {
        self.saveBtn.isEnabled = true
        self.password.resignFirstResponder()
    }
    
    @IBAction func vinDoneBtnTapped(_ sender: Any) {
        self.saveBtn.isEnabled = true
        self.vin.resignFirstResponder()
    }
    
    @IBAction func cancelBtnTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    
    @IBAction func saveBtnTapped(_ sender: Any) {
        self.username.resignFirstResponder()
        self.password.resignFirstResponder()
        self.vin.resignFirstResponder()
        
        Task {
            do {
                try await self.updateVINIfNeeded()
                self.delegate?.didUpdateVOCAccount()
                User.shared.set(username: self.username.text!, password: self.password.text!, vin: self.vin.text!)
                VOC.shared.set(volvoid: self.username.text!, password: self.password.text!, vin: self.vin.text!)
                self.saveBtn.isEnabled = false
            } catch {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Volvo On Call Account", message: "Sign-in failed", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                    self.parent?.present(alertController, animated: true, completion: nil)
                }
            }
            self.updateVOCStatus()
        }
    }
    
    @IBOutlet weak var VOCSubscriptionEnds: UILabel!
    @IBOutlet weak var statusUpdateActivity: UIActivityIndicatorView!
    @IBOutlet weak var assistanceNumber: UITextView!
    @IBOutlet weak var loginStatus: UIImageView!
    
    weak var delegate: SettingsAccountTableViewControllerDelegate?
    
    private let defaultValue = "--"
    
    private static let vehicleSelectionSegue = "VehicleSelectionSegue"
    
    private enum LoginStatus: String {
        case successful = "checkmark.circle.fill"
        case error = "xmark.circle.fill"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.username.text = User.shared.credentials?.username
        self.password.text = User.shared.credentials?.password
        self.vin.text = User.shared.credentials?.vin
        self.updateVOCStatus(notification: false)
        
        // remove insets from textview
        self.assistanceNumber.textContainerInset = UIEdgeInsets.zero
        self.assistanceNumber.contentInset = UIEdgeInsets.zero
        self.assistanceNumber.textContainer.lineFragmentPadding = 0
    }
    
    private func updateVOCStatus(notification: Bool = true) {
        self.VOCSubscriptionEnds.text = nil
        self.statusUpdateActivity.isHidden = false
        self.statusUpdateActivity.startAnimating()
        self.username.text = User.shared.credentials?.username
        self.password.text = User.shared.credentials?.password
        self.vin.text = User.shared.credentials?.vin
        
        Task {
            do {
                let attributes = try await Vehicle.Attributes.load()
                self.statusUpdateActivity.stopAnimating()
                self.VOCSubscriptionEnds.text = attributes.VOCsubscriptionEnd
                self.assistanceNumber.text = attributes.bCallAssistanceNumber
                self.loginStatus.image = UIImage(systemName: LoginStatus.successful.rawValue)
                self.loginStatus.tintColor = .systemGreen
                self.saveBtn.isEnabled = false
            } catch {
                self.VOCSubscriptionEnds.text =  self.defaultValue
                self.assistanceNumber.text =  self.defaultValue
                self.saveBtn.isEnabled = true
                self.loginStatus.image = UIImage(systemName: LoginStatus.error.rawValue)
                self.loginStatus.tintColor = .systemRed
                //alert(title: "Volvo On Call Error", message: "Unable to sign-in. Please verify your Internet access, login username and password.")
                //Toast.popError(message: error.localizedDescription, controller: self.parent)
            }
            self.loginStatus.isHidden = false
            self.statusUpdateActivity.isHidden = true
            self.statusUpdateActivity.stopAnimating()
        }
    }
    
    private func alert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        DispatchQueue.main.async {
            if let vc = self.presentedViewController {
                vc.present(alertController, animated: true, completion: nil)
            } else {
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    
    private func vin() async throws -> String {
        let account = try await CustomerAccount.load(using: self.username.text, password: self.password.text)
        
        if account.vehicleIds.isEmpty {
            throw ServiceError.noVehiclesFound
        }

        if account.vehicleIds.count > 1 {
            throw ServiceError.VINMultipleVehicles(vehicleIds: account.vehicleIds)
        }
        
        return account.vehicleIds.first!
        
    }
    
    private func updateVINIfNeeded() async throws {

        if (self.vin.text ?? "").isEmpty {
            do {
                self.vin.text = try await self.vin()
            } catch ServiceError.VINMultipleVehicles(let vehicleIds) {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: SettingsAccountTableViewController.vehicleSelectionSegue, sender: vehicleIds)
                }
                return;
            }
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
        // unwind to settings
        
        if
            let source =  unwindSegue.source as? VehicleSelectionTableViewController,
            let destination = unwindSegue.destination as? SettingsAccountTableViewController {
            guard let _ = source.selectedVehicleId else {
                return;
            }
            
            destination.vin.text = source.selectedVehicleId!
        }
    }
}

extension SettingsAccountTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !self.saveBtn.isEnabled {
            self.saveBtn.isEnabled = true
        }
    }
    
}
