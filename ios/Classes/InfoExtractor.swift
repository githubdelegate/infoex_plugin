//
//  InfoExtractor.swift
//  IE
//
//  Created by wz on 2023/2/3.
//

import Foundation
import Regex

/// common ie
///  """Information Extractor class.
///     Information extractors are the classes that, given a URL, extract
//information about the video (or videos) the URL refers to. This
//information includes the real video URL, the video title, author and
//others. The information is stored in a dictionary which is then
//passed to the YoutubeDL. The YoutubeDL processes this
//information possibly downloading the video to the file system, among
//other possible outcomes.
class InfoExtractor {
    
    func suitable(url: String) -> Bool {
        return false
    }
    
    func _match_id(url: String) -> String? {
        return nil
    }
    
    /// """Extracts URL information and returns it in list of dicts."""
    /// - Parameter url:
    func extract(url: String) {
        
    }
    
    @available(iOS 16.0, *)
    func _real_extract(url: String)  async -> [String: Any]? {
        return nil
    }
    
    /// Return the response handle.
    func _request_webpage(url_or_request: String, video_id: String) async -> (String?, HTTPURLResponse?) {
        return await YBDL.default.urlopen(url_or_request: url_or_request)
    }
    
    func _download_xml_handle(url_or_request: String, video_id: String) async {
        
    }
    
    ///   Return a tuple (page content as string, URL handle).
    /// - Parameters:
    ///   - url_or_request: url_or_request description
    ///   - video_id: video_id description
    func _download_webpage_handle(url_or_request: String, video_id: String) async -> (String?, HTTPURLResponse?) {
        return await self._request_webpage(url_or_request: url_or_request, video_id: video_id)
    }
    
    /// Return the data of the page as a string.
    /// - Parameters:
    ///   - url_or_request: url_or_request description
    ///   - video_id: video_id description
    func _download_webpage(url_or_request: String, video_id: String) async -> (String?, HTTPURLResponse?) {
        return await self._download_webpage_handle(url_or_request: url_or_request, video_id: video_id) 
    }
    
    
    func _download_json_handle(url_or_request: String, video_id: String) async -> (Any?, HTTPURLResponse?)? {
        let res = await self._download_webpage_handle(url_or_request: url_or_request, video_id: video_id)
        if let json_string = res.0 {
            return (self._parse_json(json_string: json_string, video_id: video_id), res.1)
        } else {
            return nil
        }
    }
    
    /// Return the JSON object as a dict ,可能是dict 或 array
    func _download_json(url_or_request: String, video_id: String) async -> Any?  {
        let res = await _download_webpage_handle(url_or_request: url_or_request, video_id: video_id)
        if res.0 == nil {
            return nil
        }
        return res.0
    }
    
    func _webpage_read_content( urlh: String, url_or_request: String, video_id: String) {
        
    }
    
    func _html_search_meta(name: [String], html: String, display_name: String?, fatal: Bool = false) -> String? {
        let p = name.map { n in
            return InfoExtractor._meta_regex(prop: n)
        }
        return self._html_search_regex(pattern: p, string: html, name: display_name ?? "", group: "content", fatal:fatal)
    }
    
    static func _meta_regex(prop: String) -> String {
        let p = #"(?isx)<meta(?=[^>]+(?:itemprop|name|property|id|http-equiv)=(["\']?)"# + prop + #"\1)[^>]+?content=(["\'])(?P<content>.*?)\2"#
        return p
    }
    
    ///  Like _search_regex, but strips HTML tags and unescapes entities.
    func _html_search_regex(pattern: [String], string: String, name: String, group: String?, fatal: Bool = false) -> String? {
        guard let res = _search_regex(pattern: pattern, string: string, name: name, group: group) else {
            return nil
        }
        return clean_html(html: res)
    }
    /// Perform a regex search on the given string, using a single or a list of patterns returning the first matching group.
    func _search_regex(pattern: [String], string: String, name: String, group: String?, default: String? = nil) -> String? {
        var mobj: Match?
        if pattern.count > 1 {
            for p in pattern {
                mobj = p.r?.findFirst(in: string)
                if mobj != nil {
                    break
                }
            }
        }
        
        if pattern.count == 1 {
            mobj = pattern.first!.r?.findFirst(in: string)
        }
        
        if group != nil {
            let res =  mobj?.groupWith(name: group!)
            return res
        } else {
            // 返回第一个
            return mobj?.group(at: 0)
        }
        return nil
    }
    
    
    #warning("m3u8 没有完成")
    func _extract_m3u8_formats(m3u8_url: String, video_id: String, ext: String, entry_protocol: String = "m3u8", preference: Float?,
                               m3u8_id: String?, note: String?, errnote: String?,fatal: Bool = true, live: Bool = false, data: String?, headers: Dictionary<String, Any>?,
                               query: Dictionary<String, Any>?) async -> [[String: Any]] {
        
        let (m3u8_doc, urlh) = await self._download_webpage_handle(url_or_request: m3u8_url, video_id: video_id)
        guard m3u8_doc != nil , urlh != nil else {
            return []
        }
        
       let m3u8_url =  urlh!.url?.absoluteString
       return self._parse_m3u8_formats(m3u8_doc: m3u8_doc!, m3u8_url: m3u8_url!, ext: ext, entry_protocol: entry_protocol, preference: preference, m3u8_id: m3u8_id, live: live)
    }
    
    func _parse_m3u8_formats(m3u8_doc: String, m3u8_url: String, ext: String, entry_protocol: String = "m3u8",preference: Float?, m3u8_id: String?, live: Bool = false) -> [[String: Any]] {
        
        if m3u8_doc.contains("#EXT-X-FAXS-CM:") {
            return []
        }
        if #"#EXT-X-SESSION-KEY:.*?URI="skd://"#.r?.findFirst(in: m3u8_doc) != nil {
            return []
        }
        
        var formats: [[String : Any]] = []
    
        func format_url(u: String) -> String {
            if #"^https?://"#.r?.matches(u) == true {
                return u
            } else {
                // 融合url
                
                var url = URL(string: m3u8_url)
                return URL(string: u, relativeTo: url)?.absoluteString ?? u
//                print("url-1 =\(url)")
//                url?.deleteLastPathComponent()
//                print("url-2 =\(url)")
//                url?.append(component: u)
//                print("url-3=\(url)")
//                return url?.absoluteString ?? u
            }
        }
        
        
        if m3u8_doc.contains("#EXT-X-TARGETDURATION") {
            return [
                [
                "url" : m3u8_url,
                "format_id" : m3u8_id ?? "",
                "ext" : ext,
                "protocol" : entry_protocol,
                "preference" : preference,
            ]]
        }
        
        var groups: [String: Any] = [:]
        var last_stream_inf:  [String: String] = [:]
        
        func extract_media(x_media_line: String) {
            let media =  parse_m3u8_attributes(attrib: x_media_line)
            guard let media_type = media["TYPE"], let group_id = media["GROUP-ID"], let name = media["NAME"] else {
                return
            }
            groups[group_id] = [media]
            if ["VIDEO", "AUDIO"].contains(media_type) == false {
                return
            }
            guard let media_url = media["URI"] else {
                return
            }
            
            var format_id: [String] = []
            if m3u8_id != nil {
                format_id.append(m3u8_id!)
            }
            
            if group_id != nil {
                format_id.append(group_id)
            }
            
            if name != nil {
                format_id.append(name)
            }
            
            var f: [String: Any] = [:]
            f["format_id"] = format_id.joined(separator: "-")
            f["url"] = format_url(u: media_url)
            f["manifest_url"] = m3u8_url
            f["language"] = media["LANGUAGE"]
            f["ext"] = ext
            f["protocol"] = entry_protocol
            f["preference"] = preference
            if media_type == "AUDIO" {
                f["vcodec"] = "none"
            }
            formats.append(f)
        }
        
        
        func build_stream_name() -> String? {
            let stream_name = last_stream_inf["NAME"]
            if stream_name != nil {
                return stream_name!
            }
            
            let stream_group_id = last_stream_inf["VIDEO"]
            if stream_group_id == nil {
                return nil
            }
            
            guard let stream_group = groups[stream_group_id!] as? Array<String> else {
                return stream_group_id
            }
            
            guard let rendition = stream_group.first as? Dictionary<String, String> else {
                return stream_group_id
            }
            return rendition["NAME"]
        }
        
        for (_,line) in m3u8_doc.split(whereSeparator: \.isNewline).enumerated() {
            if line.starts(with: "#EXT-X-MEDIA:") {
                extract_media(x_media_line: String(line))
            }
        }
        
        for  (_,line)  in m3u8_doc.split(whereSeparator: \.isNewline).enumerated() {
            print("line = \(line)")
            if line.starts(with: "#EXT-X-STREAM-INF:") {
                last_stream_inf = parse_m3u8_attributes(attrib: String(line))
            } else if line.starts(with: "#") || String(line).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
                continue
            } else {
               let ava = last_stream_inf["AVERAGE-BANDWIDTH"]
               let band = last_stream_inf["BANDWIDTH"]
                
                var tbr: Float? = nil
                if ava != nil {
                    tbr = float_or_none(v: ava!, scale: 1000)
                } else if band != nil {
                    tbr = float_or_none(v: band!, scale: 1000)
                }
                print("tbr = \(tbr)")
                var format_id: [String] = []
                if m3u8_id != nil {
                    format_id.append(m3u8_id!)
                }
                
                var stream_name = build_stream_name()
                if  live == false {
                    if stream_name != nil {
                        format_id.append(stream_name!)
                    } else {
                        if tbr != nil {
                            format_id.append(String(tbr!))
                        }else {
                            format_id.append("\(formats.count)")
                        }
                    }
                }
                
               var manifest_url = format_url(u: line.trimmingCharacters(in: .whitespacesAndNewlines))
                var f: [String: Any] = [:]
                f["format_id"] = format_id.joined(separator: "-")
                f["url"] = manifest_url
                f["manifest_url"] = m3u8_url
                f["tbr"] = tbr
                f["fps"] = float_or_none(v: last_stream_inf["FRAME-RATE"]) ?? ""
                f["ext"] = ext
                f["protocol"] = entry_protocol
                f["preference"] = preference 
                print("f = \(f)")
                var resolution = last_stream_inf["RESOLUTION"]
                if resolution != nil {
                    if let match =  #"(?<width>\d+)[xX](?<height>\d+)"#.r?.findFirst(in: resolution!) {
                        f["width"] = match.groupWith(name: "width")
                        f["height"] = match.groupWith(name: "height")
                    }
                }
                print("f= \(f)")
                
                if let match = #"audio.*?(?:%3D|=)(\d+)(?:-video.*?(?:%3D|=)(\d+))?"#.r?.findFirst(in: manifest_url) {
                    if match.allGroupElement().count == 3 {
                        var abr = match.group(at: 1)
                        var vbr = match.group(at: 2)
                        abr = String(float_or_none(v: abr, scale: 1000) ?? 0)
                        vbr = String(float_or_none(v: vbr, scale: 1000) ?? 0)
                        f["vbr"] = vbr
                        f["abr"] = abr
                    }
                }
                
               var codecs = parse_codecs(codecs_str: last_stream_inf["CODECS"])
                f.update(other: codecs)
                
                var audio_group_id = last_stream_inf["AUDIO"]
                
                if audio_group_id != nil, f["vcodec"] as? String != "none" {
                    var audio_group = groups[audio_group_id!] as? [String]
                    if audio_group != nil, let dict = audio_group?.first as? Dictionary<String, String>, dict["URI"] != nil {
                        f["acodec"] = "none"
                    }
                }
                formats.append(f)
                
                var progressive_uri = last_stream_inf["PROGRESSIVE-URI"]
                if progressive_uri != nil {
                    var http_f = f
                    http_f.removeValue(forKey: "manifest_url")
                    
                    let fid = f["format_id"] as? String
                    let newfid = fid?.replacingOccurrences(of: "hls-", with: "http-")
                    http_f.update(other: [
                        "format_id": newfid,
                        "protocol": "http",
                        "url": progressive_uri,
                    ])
                    formats.append(http_f)
                }
                last_stream_inf = [:]
            }
        }
        print("formats = \(formats)")
        return formats
    }
    
    
    func _sort_formats(formats: [[String: Any]], field_preference: String?) -> [[String: Any]] {
        if formats.count == 0 {
            return []
        }

        let newformts = formats.map { f in
            var newf = f
            if f["tbr"] == nil ,let abr = f["abr"] as? Float ,let vbr =  f["vbr"] as? Float {
                newf["tbr"] = abr + vbr
            }
            
            if f["ext"] == nil , let u = f["url"]  {
                newf["ext"] = determine_ext(url: u as! String)
            }
            return newf
        }
        
        func _formats_key(f: [String: Any]) {
//            var newf = f
//            if f["ext"] == nil , let u = f["url"]  {
//                newf["ext"] = determine_ext(url: u as! String)
//            }
//
//            var preference = newf["preference"] as? Float
//            if  preference != nil {
//                preference = 0
//                if let ext = newf["ext"] as? String , ["f4f", "f4m"].contains(ext) {
//                    preference = preference! - 0.5
//                }
//            }
            
//            var `protocol`: String = ""
//            if newf["protocol"] != nil {
//                `protocol` = newf["protocol"] as! String
//            } else {
//                `protocol` = determine_protocol(info_dict: newf)
//            }
//
//            var proto_preference: Float?
//            if ["http", "https"].contains(`protocol`) {
//                proto_preference = 0
//            } else {
//                if `protocol` == "rtsp" {
//                    proto_preference = -0.5
//                } else {
//                    proto_preference = -0.1
//                }
//            }
//
//            if newf["vcodec"] == nil {
//                preference = -50
//            }
//
        }
        return newformts
    }
    
    func _parse_json(json_string: String, video_id: String, transform_source: String? = nil, fatal: Bool = true) -> Any {
        if let data = json_string.data(using: .utf8) {
            if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return jsonDict
            }
            
            if  let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                return jsonDict
            }
        }
        return [:]
    }
    
//    func  _extract_mpd_formats(self, mpd_url, video_id, mpd_id=None, note=None, errnote=None, fatal=True, data=None, headers={}, query={}) {
//
//    }
    
    
    func _set_cookie(domain: String, name: String, value: String) {
        
        var props = Dictionary<HTTPCookiePropertyKey, Any>()
        props[HTTPCookiePropertyKey.name] = name
        props[HTTPCookiePropertyKey.value] = value
        props[HTTPCookiePropertyKey.path] = "/"
        props[HTTPCookiePropertyKey.domain] = domain
        if let cookie = HTTPCookie(properties: props) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }
    
    
    /// Returns a URL that points to a page that should be processed
    static func url_result(url: String, ie: String?, video_id: String?, video_title: String?) -> [String: String] {
        var vide_info = [
            "_type": "url",
            "url": url,
            "ie_key": ie ?? ""
        ]
        
        if video_id != nil {
            vide_info["id"] = video_id!
        }
        
        if video_title != nil {
            vide_info["title"] = video_title!
         }
        
        return vide_info
    }

}

