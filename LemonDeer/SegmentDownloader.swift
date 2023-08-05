//
//  SegmentDownloader.swift
//  FBDLKit
//
//  Created by jyck on 2023/8/2.
//

import Foundation


protocol SegmentDownloaderDelegate {
    func segmentDownloadSucceeded(with downloader: SegmentDownloader)
    func segmentDownloadFailed(with downloader: SegmentDownloader)
}



class SegmentDownloader: NSObject {
    
    enum Status {
        case none , success , failed , loading, pause
        
    }
    
    
    var directoryPath: URL
    
    var fileName: String
//    var filePath: String
    var downloadURL: URL
    var duration: Float
    var index: Int
    
    
    
    lazy var downloadSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "dl_session")
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    var downloadTask: URLSessionDownloadTask?
//    var isDownloading = false
//    var finishedDownload = false
    
    var status: Status = .none
    
    var delegate: SegmentDownloaderDelegate?
    
    init(with url: URL, directoryPath: URL, fileName: String, duration: Float, index: Int) {
        downloadURL = url
        self.directoryPath = directoryPath
        self.fileName = fileName
        self.duration = duration
        self.index = index
    }
    
    func startDownload() {
        if checkIfIsDownloaded() {
            status = .success
            delegate?.segmentDownloadSucceeded(with: self)
        } else {
            status = .loading
            self.downloadTask = URLSession.shared.downloadTask(with: URLRequest(url: downloadURL), completionHandler: { [weak self] location, _, _ in
                
                if let location , let self {
                    self.status = .success
                    let destinationURL = self.generateFilePath()
                    print("🌸 完成 ", self.fileName, location)
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        return
                    } else {
                        do {
                            try FileManager.default.moveItem(at: location, to: destinationURL)
                            self.delegate?.segmentDownloadSucceeded(with: self)
                        } catch let error as NSError {
                            print(error.localizedDescription)
                        }
                    }
                }
            })
            self.downloadTask?.resume()
            print("🌸 下载 ", downloadURL)
        }
    }
    
    func downlaodFial() {
        status = .failed
        delegate?.segmentDownloadFailed(with: self)
    }
    
    func cancelDownload() {
        if status == .loading {
            downloadTask?.cancel()
            status = .failed
        }
    }
    
    func pauseDownload() {
        if status == .loading {
            downloadTask?.suspend()
            status = .pause
        }
    }
    
    func resumeDownload() {
        if status == .pause {
            downloadTask?.resume()
            status = .loading
        }
 
    }
    
    func checkIfIsDownloaded() -> Bool {
        let filePath = generateFilePath().path
        
        if FileManager.default.fileExists(atPath: filePath) {
            status = .success
            return true
        } else {
            return false
        }
    }
    
    func generateFilePath() -> URL {
        return directoryPath.appendingPathComponent(fileName)
    }
}

extension SegmentDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destinationURL = generateFilePath()
        
        status = .success
        print("🌸 完成 ", fileName, location)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return
        } else {
            do {
                try FileManager.default.moveItem(at: location, to: destinationURL)
                delegate?.segmentDownloadSucceeded(with: self)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            status = .failed
            
            delegate?.segmentDownloadFailed(with: self)
        }
    }
    
}
