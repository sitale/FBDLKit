//
//  VideoDownloader.swift
//  FBDLKit
//
//  Created by jyck on 2023/8/2.
//

import Foundation

public enum Status {
    case started
    case paused
    case canceled
    case finished
}

protocol VideoDownloaderDelegate {
    func videoDownloadSucceeded(by downloader: VideoDownloader)
    func videoDownloadFailed(by downloader: VideoDownloader)
    
    func update(_ progress: Float)
}

open class VideoDownloader : NSObject, URLSessionDelegate {
    public var downloadStatus: Status = .paused
    
    var m3u8Data: String = ""
    var tsPlaylist = M3u8Playlist()
    var segmentDownloaders = [SegmentDownloader]()
    var tsFilesIndex = 0
    var neededDownloadTsFilesCount = 0
    var downloadURLs = [String]()
    
    var directoryPath: URL!
    
    var maxThreadCount  = 5
    
    var downloadingProgress: Float {
        let finishedDownloadFilesCount = segmentDownloaders.filter({ $0.status == .success }).count
        let fraction = Float(finishedDownloadFilesCount) / Float(neededDownloadTsFilesCount)
        let roundedValue = round(fraction * 100) / 100
        
        return roundedValue
    }
    
    fileprivate var startDownloadIndex = 2
    
    var delegate: VideoDownloaderDelegate?
    
    
    
    lazy var downloadSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "dl_session")
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    
    open func startDownload() {
        checkOrCreatedM3u8Directory()
        
        var newSegmentArray = [M3u8TsSegmentModel]()
        
        let notInDownloadList = tsPlaylist.tsSegmentArray.filter { !downloadURLs.contains($0.locationURL) }
        neededDownloadTsFilesCount = tsPlaylist.length
        
        for i in 0 ..< notInDownloadList.count {
//            let fileName = "\(tsFilesIndex).ts"
            let fileName = (notInDownloadList[i].locationURL as NSString).lastPathComponent

            let segmentDownloader = SegmentDownloader(with: URL(string: notInDownloadList[i].locationURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!,
                                                      directoryPath: directoryPath,
                                                      fileName: fileName,
                                                      duration: notInDownloadList[i].duration,
                                                      index: tsFilesIndex)
            segmentDownloader.delegate = self
            
            segmentDownloaders.append(segmentDownloader)
            downloadURLs.append(notInDownloadList[i].locationURL)
            
            var segmentModel = M3u8TsSegmentModel()
            segmentModel.duration = segmentDownloaders[i].duration
            segmentModel.locationURL = segmentDownloaders[i].fileName
            segmentModel.index = segmentDownloaders[i].index
            newSegmentArray.append(segmentModel)
            
            tsPlaylist.tsSegmentArray = newSegmentArray
            
            tsFilesIndex += 1
        }
        
        segmentDownloaders.prefix(maxThreadCount).forEach {
            $0.startDownload()
        }
        
        downloadStatus = .started
    }
    
    func checkDownloadQueue() {
        
    }
    
    func updateLocalM3U8file() {
        checkOrCreatedM3u8Directory()
        
        let filePath = getDocumentsDirectory().appendingPathComponent("Downloads").appendingPathComponent(tsPlaylist.identifier).appendingPathComponent("\(tsPlaylist.identifier).m3u8")
        
        var header = "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:15\n"
        var content = ""
        for i in 0 ..< tsPlaylist.tsSegmentArray.count {
            let segmentModel = segmentDownloaders[i]
            let length = "#EXTINF:\(segmentModel.duration),\n"
            let fileName = "\(segmentModel.fileName)\n"
            content += (length + fileName)
        }
//        for i in 0 ..< tsPlaylist.tsSegmentArray.count {
//            let segmentModel = tsPlaylist.tsSegmentArray[i]
//
//            let length = "#EXTINF:\(segmentModel.duration),\n"
//            let fileName = "http://127.0.0.1:8080/\(segmentModel.index).ts\n"
//            content += (length + fileName)
//        }
        
        header.append(content)
        header.append("#EXT-X-ENDLIST\n")
        
        let writeData: Data = header.data(using: .utf8)!
        try! writeData.write(to: filePath)
    }
    
    private func checkOrCreatedM3u8Directory() {
        let filePath = getDocumentsDirectory().appendingPathComponent("Downloads").appendingPathComponent(tsPlaylist.identifier)
        
        if !FileManager.default.fileExists(atPath: filePath.path) {
            try! FileManager.default.createDirectory(at: filePath, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    open func deleteAllDownloadedContents() {
        let filePath = getDocumentsDirectory().appendingPathComponent("Downloads").path
        
        if FileManager.default.fileExists(atPath: filePath) {
            try! FileManager.default.removeItem(atPath: filePath)
        } else {
            print("File has already been deleted.")
        }
    }
    
    open func deleteDownloadedContents(with name: String) {
        let filePath = getDocumentsDirectory().appendingPathComponent("Downloads").appendingPathComponent(name).path
        
        if FileManager.default.fileExists(atPath: filePath) {
            try! FileManager.default.removeItem(atPath: filePath)
        } else {
            print("Could not find directory with name: \(name)")
        }
    }
    
    open func pauseDownloadSegment() {
        segmentDownloaders.forEach { $0.pauseDownload() }
        
        downloadStatus = .paused
    }
    
    open func cancelDownloadSegment() {
        segmentDownloaders.forEach { $0.cancelDownload() }
        
        downloadStatus = .canceled
    }
    
    open func resumeDownloadSegment() {
        segmentDownloaders.forEach { $0.resumeDownload() }
        
        downloadStatus = .started
    }
}

extension VideoDownloader: SegmentDownloaderDelegate {
    func segmentDownloadSucceeded(with downloader: SegmentDownloader) {
        let finishedDownloadFilesCount = segmentDownloaders.filter({ $0.status == .success }).count
        
        DispatchQueue.main.async {
            self.delegate?.update(self.downloadingProgress)
        }
        
//        updateLocalM3U8file()
        
        if finishedDownloadFilesCount == neededDownloadTsFilesCount {
            if  downloadStatus != .finished {
                print("✅ 全部完成 ")
                downloadStatus = .finished
                delegate?.videoDownloadSucceeded(by: self)
            }

     
            
            // 写入m3u8
            
            
        } else {
            print("🌸 开始下一个")
            segmentDownloaders.filter({ $0.status == .none }).first?.startDownload()
        }
    }
    
    func segmentDownloadFailed(with downloader: SegmentDownloader) {
        delegate?.videoDownloadFailed(by: self)
    }
}
