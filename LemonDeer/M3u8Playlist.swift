//
//  M3u8Playlist.swift
//  FBDLKit
//
//  Created by jyck on 2023/8/2.
//

import Foundation


public struct M3u8TsSegmentModel {
    public var duration: Float = 0.0
    public var locationURL = ""
    public var index: Int = 0
}


public class M3u8Playlist {
    public var tsSegmentArray = [M3u8TsSegmentModel]()
    public var length = 0
    public var identifier = ""
    
    public func initSegment(with array: [M3u8TsSegmentModel]) {
        tsSegmentArray = array
        length = array.count
    }
}
