//
//  XVideoIE.swift
//  IE
//
//  Created by wz on 2023/2/3.
//

import Foundation
import Regex

class XVideoIE: InfoExtractor {
    
    let _VALID_URL: String = "c"
    
    let test_url = ["http://www.xvideos.com/video4588838/biker_takes_his_girl",
                    "https://flashservice.xvideos.com/embedframe/4588838",
                    "http://static-hw.xvideos.com/swf/xv-player.swf?id_video=4588838",
                    "http://xvideos.com/video4588838/biker_takes_his_girl",
                    "http://fr.xvideos.com/video4588838/biker_takes_his_girl"]
    
    override func suitable(url: String) -> Bool {
        return _VALID_URL.r?.matches(url) ?? false
    }
    
    
    override func _match_id(url: String) -> String? {
        let id = _VALID_URL.r?.findFirst(in: url)?.group(at: 1)
        return id
    }
    
    func tests() {
        for url in test_url {
            print("\(url) ->\(self.suitable(url: url))--id=\(self._match_id(url: url))")
        }
    }
    
    override func _real_extract(url: String) async -> [String: Any]? {
        guard let video_id = self._match_id(url: url) else {
            return nil
        }
        
        let (webpage,httpres) = await self._download_webpage(url_or_request: "https://www.xvideos.com/video\(video_id)/0", video_id: video_id)
        guard webpage != nil else {
            print("请求网页失败啦啦啦")
            return nil
        }
        
        if "<h1 class=\"inlineError\">(.+?)</h1>".r?.matches(webpage!) == true {
            return nil
        }
        
        let pat = [
            #"<title>(?<title>.+?)\s+-\s+XVID"#,
            #"setVideoTitle\s*\(\s*(["\'])(?<title>(?:(?!\1).)+)\1"#
        ]
        
        let title = self._html_search_regex(pattern: pat, string: webpage!, name: "title", group: "title")
        
//        let thumbnails = []
        
        var formats: [[String: Any]] = []
        let video_url = self._search_regex(pattern: [#"flv_url=(.+?)&"#], string: webpage!, name: "video URL", group: nil)
        if video_url != nil {
            var formatdict = [
                "format_id": "flv",
                "url": video_url!,
            ]
            formats.append(formatdict)
        }
        
        let all = #"setVideo([^(]+)\((["\'])(http.+?)\2\)"#.r?.findAll(in: webpage!)
        for (idx,match) in all!.enumerated() {
            if match.allGroupElement().count < 4 {
                continue
            }
            
            let format_id = match.group(at: 1)?.lowercased()
            let format_url = match.group(at: 3)
            
            if format_id == nil || format_url == nil {
                continue
            }

            print("all = \(match.allGroupElement())")
            print("formatid=\(format_id) - format-url=\(format_url)")
            
            if format_id == "hls" {
                let extfotmats =  await _extract_m3u8_formats(m3u8_url: format_url!, video_id: video_id, ext: "mp4", entry_protocol: "m3u8_native" ,preference: nil, m3u8_id: "hls", note: nil, errnote: nil, fatal: false, data: nil, headers: nil, query: nil)
                print("extfotmats= \(extfotmats)")
                formats.append(contentsOf: extfotmats)
            } else if ["urllow", "urlhigh"].contains(format_id) {
                let beginIndex =  format_id!.index(format_id!.startIndex, offsetBy: 3)
                let newId =  format_id?.substring(from: beginIndex) ?? ""
                //                    let newId = String(format_id![beginIndex])
                let ext = determine_ext(url: format_url!, default_ext: "mp4")
                print("newdid = \(newId)- ext=\(ext)")
                
                var formatdict = [
                    "format_id": "\(ext)" + "-" + "\(newId)",
                    "url": format_url!,
                ]
                
                if format_id!.hasSuffix("low") {
                    formatdict["quality"] = "-2"
                }
                formats.append(formatdict)
                print("formats=\(formats)")
            }
            print("last formats = \(formats)")
        }
        
        let newformats =  _sort_formats(formats: formats, field_preference: nil)
        print("newformats = \(newformats)")
        return [
            "formats": newformats,
            "title" : title
        ]
    }
}
