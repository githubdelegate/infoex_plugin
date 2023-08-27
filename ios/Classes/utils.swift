//
//  utils.swift
//  IE
//
//  Created by wz on 2023/2/6.
//

import Foundation
import Regex


func sanitize_url(url: String) {
    
}


func clean_html(html: String) -> String {
    var res: String = html.replacingOccurrences(of: "\n", with: " ")
     res = #"(?u)\s*<\s*br\s*/?\s*>\s*"#.r?.replaceAll(in: res, with: "\n") ?? res
     res = #"(?u)<\s*/\s*p\s*>\s*<\s*p[^>]*>"#.r?.replaceAll(in: res, with: "\n") ?? res
    
    res = #"<.*?>"#.r?.replaceAll(in: res, with: "") ?? res
    return res.trimmingCharacters(in: .whitespacesAndNewlines)
}


#warning("这个太麻烦先不搞了")
func unescapeHTML(s: String) -> String {
    return s
}

func determine_ext(url: String, default_ext: String = "unknown_video") -> String {
    if url.contains(".") == false {
        return default_ext
    }
    
    let guess = url.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first?.split(separator: ".").last?.lowercased() ?? ""
    
    let guessTrim = guess.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    if #"^[A-Za-z0-9]+$"#.r?.matches(guess) == true {
        return guess
    } else if KNOWN_EXTENSIONS.contains(guessTrim) {
       return guessTrim
    } else {
        return default_ext
    }
}


let KNOWN_EXTENSIONS = [
    "mp4", "m4a", "m4p", "m4b", "m4r", "m4v", "aac",
    "flv", "f4v", "f4a", "f4b",
    "webm", "ogg", "ogv", "oga", "ogx", "spx", "opus",
    "mkv", "mka", "mk3d",
    "avi", "divx",
    "mov",
    "asf", "wmv", "wma",
    "3gp", "3g2",
    "mp3",
    "flac",
    "ape",
    "wav",
    "f4f", "f4m", "m3u8", "smil"]


func parse_m3u8_attributes(attrib: String) -> [String: String] {
    var info: [String: String] = [:]
    guard let all =  #"(?<key>[A-Z0-9-]+)=(?<val>"[^"]+"|[^",]+)(?:,|$)"#.r?.findAll(in: attrib) else {
        return [:]
    }
    
    for (idx, match) in all.enumerated() {
        let key = match.groupWith(name: "key")
        var val = match.groupWith(name: "val")
        if val != nil, val!.starts(with: "\"") {
            let startIdx = val!.index(val!.startIndex, offsetBy: 1)
            let endIdx = val!.index(val!.endIndex, offsetBy: -1)
            val = String(val![startIdx..<endIdx])
        }
        if key != nil {
            info[key!] = val
        }
    }
    print("attributes info= \(info)")
    return info
}


func parse_codecs(codecs_str: String?) -> [String : String] {
    if codecs_str == nil {
        return [:]
    }
    
    let set = CharacterSet(charactersIn: ",")
    let split_codecs = codecs_str?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: set).split(separator: ",").map({ str in
        return String(str)
    }) ?? []
    
    var vcodec: String? = nil
    var acodec: String? = nil
  
    for full_codec in split_codecs {
        let codec = full_codec.split(separator: ".").first.map { s in
            String(s)
        }
        
        if ["avc1", "avc2", "avc3", "avc4", "vp9", "vp8", "hev1", "hev2", "h263", "h264", "mp4v", "hvc1", "av01", "theora"].contains(codec) {
            if vcodec == nil {
                vcodec = full_codec
            }
        } else if ["mp4a", "opus", "vorbis", "mp3", "aac", "ac-3", "ec-3", "eac3", "dtsc", "dtse", "dtsh", "dtsl"].contains(codec) {
            if acodec == nil {
                acodec = full_codec
            }
        } else {
            print("错误 codec")
        }
    }
     
    if vcodec == nil, acodec == nil {
        if split_codecs.count == 2 {
            return ["vcodec": split_codecs[0] , "acodec": split_codecs[1]]
        }
    } else {
        return ["vcodec": vcodec ?? "none", "acodec": acodec ?? "none"]
    }
    return [:]
}


func float_or_none(v: String?, scale: Float = 1, invscale: Float = 1, defaultV: String? = nil) -> Float? {
    if v == nil {
        return nil
    }
    if let floatValue = Float(v!) {
        return (floatValue * invscale / scale)
    }
    return nil
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}


func determine_protocol(info_dict: [String: Any]) -> String {
    if let proto = info_dict["protocol"] as? String {
        return proto
    }
    
    if let url =  info_dict["url"] as? String {
        if url.starts(with: "rtmp") {
            return "rtmp"
        }else if url.starts(with: "mms") {
            return "mms"
        }else if url.starts(with: "rtsp") {
            return "rtsp"
        }
        
        var ext = determine_ext(url: url)
        if ext == "m3u8" {
            return "m3u8"
        } else if ext == "f4m" {
            return "f4m"
        }
        return URL(string: url)?.scheme ?? ""
    }
    return ""
}



func url_or_none(url: String?) -> String? {
    if url == nil {
        return nil
    }
    
    let newurl = url!.trimmingCharacters(in: .whitespacesAndNewlines)
    if #"^(?:(?:https?|rt(?:m(?:pt?[es]?|fp)|sp[su]?)|mms|ftps?):)?//"#.r?.matches(newurl) == true {
        return newurl
    }
    return nil
}

func remove_quotes(s: String?) -> String? {
    if s == nil {
        return s
    }
    
    if s!.count < 2 {
        return s
    }
    
    for quote in ["\"", "'"] {
        if s!.hasPrefix(quote), s!.hasSuffix(quote) {
            let start = s!.index(s!.startIndex, offsetBy: 1)
            let end = s!.index(s!.endIndex, offsetBy: -1)
            let rang = start..<end
            return String(s![rang])
        }
    }
    return s
}

//
//func int_or_none(v: Any, scale:Int = 1, default=None, get_attr:None, invscale=1) -> Int? {
//    if
//}
//    if get_attr:
//        if v is not None:
//            v = getattr(v, get_attr, None)
//    if v in (None, ''):
//        return default
//    try:
//        return int(v) * invscale // scale
//    except (ValueError, TypeError, OverflowError):
//        return default
