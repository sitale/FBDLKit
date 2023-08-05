//
//  LemonDeer.swift
//  FBDLKit
//
//  Created by jyck on 2023/8/2.
//

import Foundation

public typealias FBCallback = () -> Void

public protocol LemonDeerDelegate  {
    func videoDownloadSucceeded()
    func videoDownloadFailed()
    
    func update(_ progress: Float, with directoryName: String)
}

public struct LemonDeerCallback {
    public let onSuccess: FBCallback
    public let onFailed: FBCallback
    public let onUpdated: (_ progress: Float, _ directoryName: String) -> Void
}



public class  LemonDeer  : ObservableObject, Identifiable {
    
    @Published public var progress: Float = 0.0

    let directoryName: String
    let m3u8URL:String
    
    public let m3u8Parser = M3u8Parser()
    
    let downloader = VideoDownloader()
    
    /// 回调
    public var delegate: LemonDeerCallback?
    
    /// 缓存沙盒路径
    public var basePATH:URL = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
    /// 缓存路径
    var directoryPath: URL!
    
    public init(m3u8URL: String, directoryName: String, basePATH: URL? = nil) {
        self.m3u8URL = m3u8URL
        self.directoryName = directoryName
        
        if let basePATH {
            self.basePATH = basePATH
        }
        
        directoryPath = self.basePATH.appendingPathComponent(directoryName)
        
        print("directoryPath:\(directoryPath)")
        
        // 创建文件夹
        try? FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: false)
        
        m3u8Parser.identifier = directoryName
        downloader.delegate = self
        m3u8Parser.delegate = self
    }
    
    public func parse() {
        
        // 以域名 directoryName 创建
//        let documentURL = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!


        DispatchQueue.global().async {
            self.m3u8Parser.parse(with: self.m3u8URL, cache: self.directoryPath)
        }
    }
}

extension LemonDeer: M3u8ParserDelegate {
    func parseM3u8Succeeded(by parser: M3u8Parser) {
        downloader.tsPlaylist = parser.tsPlaylist
        downloader.m3u8Data = parser.m3u8Data
        downloader.directoryPath = directoryPath
        downloader.startDownload()
    }
    
    func parseM3u8Failed(by parser: M3u8Parser) {
        print("Parse m3u8 file failed.")
    }
}

extension LemonDeer: VideoDownloaderDelegate {
    func videoDownloadSucceeded(by downloader: VideoDownloader) {
//        m3u8Parser.m3u8Data
//        var m3u8 = (try? String(contentsOfFile: m3u8File)) ?? ""
        let texts = m3u8Parser.m3u8Data.components(separatedBy: "#EXTINF")
        if let prefix = texts.first {
            if prefix.contains("EXT-X-KEY") , let uri = prefix.components(separatedBy: ",").first(where: { $0.contains("URI") }),  let file: String =  uri.components(separatedBy: "=").last {
                let name = file.replacingOccurrences(of: "\"", with: "")
                var writeFilePath: URL = directoryPath
                writeFilePath.appendPathComponent((name as NSString).lastPathComponent)
                if name.hasPrefix("http"), let key = URL(string: name) {
                    let data = try? Data(contentsOf: key)
                    try? data?.write(to: writeFilePath, options: [])
                } else {
                    let url = URL(string: m3u8URL)!.deletingLastPathComponent().appendingPathComponent(name)
                    let data = try? Data(contentsOf: url)
                    
                    try? data?.write(to: writeFilePath, options: [])
                }
            }
        }
        print("🌸  生成 合成列表")
//        try? m3u8Parser.m3u8Data.write(to: URL(fileURLWithPath: m3u8File), atomically: true, encoding: .utf8)
        delegate?.onSuccess()
    }
    
    func videoDownloadFailed(by downloader: VideoDownloader) {
        delegate?.onFailed()
    }
    
    func update(_ progress: Float) {
        DispatchQueue.main.async {
            self.progress = progress
        }
        delegate?.onUpdated(progress, directoryName)
    }
}
