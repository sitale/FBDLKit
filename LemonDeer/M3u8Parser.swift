//
//  M3u8Parser.swift
//  FBDLKit
//
//  Created by jyck on 2023/8/2.
//

import Foundation

protocol M3u8ParserDelegate {
    func parseM3u8Succeeded(by parser: M3u8Parser)
    func parseM3u8Failed(by parser: M3u8Parser)
}

open class M3u8Parser {
    var delegate: M3u8ParserDelegate?
    
    var m3u8Data: String = ""
    var tsSegmentArray = [M3u8TsSegmentModel]()
    var tsPlaylist = M3u8Playlist()
    var identifier = ""
    
    /**
     To parse m3u8 file with a provided URL.
     
     - parameter url: A string of URL you want to parse.
     */
    open func parse(with url: String, cache directory: URL) {
        guard let m3u8ParserDelegate = delegate, let href = URL(string: url) else {
            print("M3u8ParserDelegate not set.")
            return
        }
        
        if !(url.hasPrefix("http://") || url.hasPrefix("https://")) {
            print("Invalid URL.")
            m3u8ParserDelegate.parseM3u8Failed(by: self)
            return
        }
        
        do {
            var m3u8Content: String = ""
            var isRemote = false
            
            let file = directory.appendingPathComponent(href.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: file.path) {
                m3u8Content = try String(contentsOf: file, encoding: .utf8)
                print("🌸 加载 本地 文件", m3u8Content)
                if m3u8Content == "" {
                    print("🌸 加载 本地 文件 失败 ====  加载远程")
                    m3u8Content = try String(contentsOf: href, encoding: .utf8)
                    isRemote = true
                }
            } else {
                m3u8Content = try String(contentsOf: href, encoding: .utf8)
                isRemote = true
            }
            
            if m3u8Content == "" {
                print("Empty m3u8 content.")
                m3u8ParserDelegate.parseM3u8Failed(by: self)
                return
            } else {
                guard (m3u8Content.range(of: "#EXTINF:") != nil) else {
                    print("No EXTINF info.")
                    m3u8ParserDelegate.parseM3u8Failed(by: self)
                    return
                }
                if isRemote {
                    print("🌸 缓存到本地")
                    try? m3u8Content.write(to: file, atomically: true, encoding: .utf8)
                }
                
                self.m3u8Data = m3u8Content
                if self.tsSegmentArray.count > 0 { self.tsSegmentArray.removeAll() }
                
                let segmentRange = m3u8Content.range(of: "#EXTINF:")!
                let segmentsString = String(m3u8Content.suffix(from: segmentRange.lowerBound)).components(separatedBy: "#EXT-X-ENDLIST")
                var segmentArray = segmentsString[0].components(separatedBy: "\n")
                segmentArray = segmentArray.filter { !$0.contains("#EXT-X-DISCONTINUITY") }
                
                var link = href
                link = link.deletingLastPathComponent()
                while (segmentArray.count > 2) {
                    var segmentModel = M3u8TsSegmentModel()
                    
                    let segmentDurationPart = segmentArray[0].components(separatedBy: ":")[1]
                    var segmentDuration: Float = 0.0
                    
                    if segmentDurationPart.contains(",") {
                        segmentDuration = Float(segmentDurationPart.components(separatedBy: ",")[0])!
                    } else {
                        segmentDuration = Float(segmentDurationPart)!
                    }
                    
                    let segmentURL = segmentArray[1]
                    segmentModel.duration = segmentDuration
                    
                    var uri = segmentURL
                    if !uri.hasPrefix("http") {
                        uri = link.appendingPathComponent(uri).absoluteString
                    }
                    
                    segmentModel.locationURL = uri
                    
                    
                    
                    self.tsSegmentArray.append(segmentModel)
                    
                    segmentArray.remove(at: 0)
                    segmentArray.remove(at: 0)
                }
                
                self.tsPlaylist.initSegment(with: self.tsSegmentArray)
                self.tsPlaylist.identifier = self.identifier
                
                m3u8ParserDelegate.parseM3u8Succeeded(by: self)
            }
        } catch let error {
            print(error.localizedDescription)
            print("Read m3u8 file content error.")
        }
    }
}
