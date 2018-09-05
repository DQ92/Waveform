//
//  AudioFilesListViewController.swift
//  Waveform
//
//  Created by Robert Mietelski on 03.09.2018.
//  Copyright © 2018 Andrew L. Jaffee. All rights reserved.
//

import UIKit

class AudioFilesListViewController: UIViewController {

    // MARK: - Views
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Public attributes
    
    var directoryUrl: URL!
    var didSelectFileBlock: ((URL) -> Void)?
    
    // MARK: - Private attributes
    
    private var fileUrls: [URL] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            self.fileUrls = try FileManager.default.contentsOfDirectory(at: self.directoryUrl, includingPropertiesForKeys: nil)
        } catch {
            let alertController = UIAlertController(title: "Błąd",
                                                    message: "Nie udało się dczytać listy plików",
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true)
        }
    }
}

extension AudioFilesListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fileUrls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier") else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = fileUrls[indexPath.row].lastPathComponent
        return cell
    }
}

extension AudioFilesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didSelectFileBlock?(self.fileUrls[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
