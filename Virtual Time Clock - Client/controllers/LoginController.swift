//
//  ViewController.swift
//  Virtual Time Clock - Client
//
//  Created by Emmanuel Nativel on 10/21/19.
//  Copyright © 2019 Emmanuel Nativel. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import AVFoundation
import Toast_Swift

class LoginController: UIViewController, AVAudioPlayerDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: Attributs
    var player: AVAudioPlayer!
    
    // MARK: Cycle de vie
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtons()
        setupTextField()
        setupToasts()
        
        // On va tester si un utilisateur est déjà connecté. Si c'est le cas, on le redirige vers la liste des missions.
        if let user = Auth.auth().currentUser {
            print("✅ Un utilisateur est déjà connecté : \(user.email ?? "")")
            perform(#selector(presentMissionManagerController), with: nil, afterDelay: 0)
            // Ici, on utilise un sélector pour s'assurer que la vue vers laquelle on veut rediriger l'utilisateur soit belle et bien chargée.
        } else {
            print("ℹ️ Aucun utilisateur n'est connecté.")
        }
    }
    
    
    // MARK: Private functions
    
    //Méthode pour paramétrer les boutons
    private func setupButtons(){
        loginButton.layer.cornerRadius = 25 //Arrondir les bords du bouton login
        loginButton.setTitle(NSLocalizedString("loginButton", comment: "Login"), for: .normal)
    }
    
    //Méthode pour paramétrer les TextFiels
    private func setupTextField(){
        // Liaison avec les délégués
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // Texte des placeholders
        let emailPlaceholder = NSLocalizedString("emailPlaceholder", comment: "Login")
        let passwordPlaceholder = NSLocalizedString("passwordPlaceholder", comment: "Login")
        
        // Personnalisation des placeholders
        emailTextField.attributedPlaceholder = NSAttributedString(string:emailPlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        passwordTextField.attributedPlaceholder = NSAttributedString(string:passwordPlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        
        // Tap gesture pour fermer le clavier quand on clique dans le vide
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // Méthode permettant de pesonnaliser les Toasts de l'application
    private func setupToasts(){
        var toastStyle = ToastStyle()
        toastStyle.backgroundColor = .white
        toastStyle.messageColor = .orange
        toastStyle.messageAlignment = .center
        ToastManager.shared.style = toastStyle
    }
    
    // MARK: Actions
    
    //Fonction appelée par le TapGesture : permet de fermer le clavier
    @objc private func hideKeyboard(){
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    // Fonction appelée si un utilisateur est déjà connecté
    @objc private func presentMissionManagerController() {
        self.performSegue(withIdentifier: "loginToMissionManager", sender: self)
    }
    
    //Fonction appelée quand on appui sur le bouton de logIn
    @IBAction func onClickOnLoginButton(_ sender: UIButton) {
        
        // Connexion de l'utilisateur
        if emailTextField.text != "" && passwordTextField.text != "" {
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (AuthentificationResult, error) in
                if((error) != nil) { // Erreur d'authentification
                    print("⛔️ Erreur lors de la connexion de l'utilisateur : " + error.debugDescription)
                    self.view.makeToast(NSLocalizedString("connectionFailed", comment: "Alert message"), duration: 3)
                }
                else { // Authentification réussie
                    print("✅ Connexion de l'utilisateur " + self.emailTextField.text!)
                    
                    // On va vérifier que c'est bien un employé
                    let db = Firestore.firestore()          // Instance de la base de données
                    let user = Auth.auth().currentUser      // Récupération de l'utilisateur courrant
                    let userId = user?.uid                  // Id de l'utilisateur courrant
                    
                    // Récupération des données de cet utilisateur dans la BD
                    let documentCurrentUser = db.collection("utilisateurs").document(userId!)
                    
                    documentCurrentUser.getDocument { (document, error) in
                        // On test si le document lié à cet utilisateur existe bien
                        if let document = document, document.exists {
                            let isLeader = document.get("isLeader") as! Bool    // Récupération du champ isLeader
                            if isLeader == false {                              // C'est un employé
                                print("✅ Ce n'est pas un leader, je le redirige vers la liste des missions")
                                
                                // On va jouer le son de connexion
                                if let soundFilePath = Bundle.main.path(forResource: "soundOn", ofType: "mp3") {
                                    let fileURL = URL(fileURLWithPath: soundFilePath)
                                    do {
                                        try self.player = AVAudioPlayer(contentsOf: fileURL)
                                        self.player.delegate = self
                                        self.player.play()
                                    }
                                    catch { print("⛔️ Erreur lors de la lecture du son") }
                                }
                                
                                // Redirection vers la liste des missions
                                self.performSegue(withIdentifier: "loginToMissionManager", sender: self)
                            }
                            else { // Ce n'est pas un employé, c'est un gérant !
                                print("⛔️ C'est un leader, je le déconnecte")
                                self.view.makeToast(NSLocalizedString("leaderError", comment: "Alert message"), duration: 3)
                                // Déconnexion de l'utilisateur
                                do {
                                    try Auth.auth().signOut()
                                } catch let signOutError as NSError {
                                  print ("⛔️ Erreur de déconnexion : \(signOutError)")
                                }
                            }
                        }
                        else {
                            print("⛔️ Erreur : Le document demandé pour cet utilisateur n'existe pas !")
                        }
                    }
                }
            }
        }
        else { // Les champs ne sont pas remplis
            print("⛔️ Les champs sont mal remplis !")
            self.view.makeToast(NSLocalizedString("formError", comment: "Alert message"), duration: 3)
        }
    }
    
    
}

// MARK: Extensions

//Délégué des TextField
extension LoginController:UITextFieldDelegate{
    
    //Gestion de l'appui sur le bouton return du clavier
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() //Permet de fermer le clavier
        return true
    }
}
