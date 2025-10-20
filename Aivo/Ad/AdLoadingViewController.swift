//
//  AdLoadingViewController.swift
//  DreamHomeAI
//
//  Created by Huy on 14/10/25.
//


import UIKit

final class AdLoadingViewController: UIViewController {

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Loading Ad..."
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .gray
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        return spinner
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        isModalInPresentation = true                 // chặn vuốt để dismiss
        modalPresentationStyle = .fullScreen         // ép full screen
        modalTransitionStyle = .crossDissolve        // mượt hơn khi hiện/ẩn
        
        view.addSubview(label)
        view.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 20),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
