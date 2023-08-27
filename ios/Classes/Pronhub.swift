//
//  Pronhub.swift
//  VideoDownloader
//
//  Created by wz on 2023/2/9.
//

import Foundation

class PornHubBaseIE: InfoExtractor {
    static let _NETRC_MACHINE = "pornhub"
    static let _PORNHUB_HOST_RE = #"(?:(?<host>pornhub(?:premium)?\.(?:com|net|org))|pornhubthbh7ap3u\.onion)"#
}

class  PornHubIE : PornHubBaseIE {
    static let FORMAT_PREFIXES = ["media", "quality", "qualityItems"]
    
    var _VALID_URL = #"https?://(?:(?:[^/]+\.)?"# + PornHubBaseIE._PORNHUB_HOST_RE + #"/(?:(?:view_video\.php|video/show)\?viewkey=|embed/)|(?:www\.)?thumbzilla\.com/video/)(?<id>[\da-z]+)"#
    
    @available(iOS 16.0, *)
    override func _real_extract(url: String) async -> [String: Any]? {
        let mobj = self._VALID_URL.r?.findFirst(in: url)
        print("mobj=\(mobj?.allGroupElement())")
        var host = mobj?.groupWith(name: "host")
        if host == nil {
            host = "pornhub.com"
        }
        guard let video_id = mobj?.groupWith(name: "id") else {
            return nil
        }
        let ho = host ?? ""
        
        //        Task(operation: {
        self._set_cookie(domain: ho, name: "age_verified", value: "1")
        
        func dl_webpage(platform: String) async -> String? {
            self._set_cookie(domain: ho, name: "platform", value: platform)
            let url = "https://www." + "\(ho)" + "/view_video.php?viewkey=" + "\(video_id)"
            return await self._download_webpage(url_or_request: url, video_id: url).0
        }
        
        
        guard var webpage = await dl_webpage(platform: "pc") else {
            print(" webpage = nil")
            return nil
        }
        
        let p = [
            #"(?s)<div[^>]+class=(["\'])(?:(?!\1).)*\b(?:removed|userMessageSection)\b(?:(?!\1).)*\1[^>]*>(?<error>.+?)</div>"#,
            #"(?s)<section[^>]+class=["\']noVideo["\'][^>]*>(?<error>.+?)</section>"#
        ]
        
        if let error_msg = self._html_search_regex(pattern: p, string: webpage, name: "error message", group: "error") {
            let err =  #"\s+"#.r?.replaceAll(in: error_msg, with: " ")
            print("err = \(err)")
            return nil
        }
        
        let p2 = [
            #"class=["\']geoBlocked["\']"#,
            #">\s*This content is unavailable in your country'"#
        ]
        
        var geoerr: Bool = false
        for p in p2 {
            if p.r?.findFirst(in: webpage) != nil {
                geoerr = true
            }
        }
        
        if geoerr == true {
            print("geo error")
            return nil
        }
        
        var title = self._html_search_regex(pattern: ["twitter:title"], string: webpage, name: "", group: nil)
        print(" title ==> = \(title)")
        if title == nil || title == "twitter:title" {
            let p3  = [
                #"(?s)<h1[^>]+class=["\']title["\'][^>]*>(?<title>.+?)</h1>"#,
                #"<div[^>]+data-video-title=(["\'])(?<title>(?:(?!\1).)+)\1"#,
                #"shareTitle["\']\s*[=:]\s*(["\'])(?<title>(?:(?!\1).)+)\1"#
            ]
            title = self._html_search_regex(pattern: p3, string: webpage, name: "title", group: "title")
            print(" title ==> = \(title)")
        }
        
        var video_urls: [(String, String)] = []
        var video_urls_set = Set<String>()
        var subtitles:[String: Any] = [:]
        
        var flashvarsRe = self._search_regex(pattern: [#"var\s+flashvars_\d+\s*=\s*(.?+)*;"#], string: webpage, name: "flashvars", group: nil) ?? "{}"
        
        
        let newflashvarsRe =  flashvarsRe.split(separator: "=", maxSplits: 1).last?.trimmingCharacters(in: .whitespacesAndNewlines)
        
     
        
        if flashvarsRe.hasPrefix("var flashvars_"), let r = flashvarsRe.firstRange(of: " =") {
            flashvarsRe =  String(flashvarsRe.substring(from: r.upperBound))
        }
        
        if flashvarsRe.hasSuffix(";") {
            flashvarsRe = String(flashvarsRe[..<flashvarsRe.index(flashvarsRe.endIndex, offsetBy: -1)])
        }
        
        print("\n flashvarsRe ==> = \(flashvarsRe)")
        guard let flashvars = self._parse_json(json_string: flashvarsRe, video_id: video_id) as? [String : Any] else {
            print("flashvars is not dict failed")
            return nil
        }
        print("\n flashvars ==> = \(flashvars)")
        
        if flashvars.count > 0 {
            var subtitle_url = url_or_none(url: flashvars["closedCaptionsFile"] as? String)
            if subtitle_url != nil {
                let tmpdict = [
                    "url" : subtitle_url,
                    "ext" : "srt"
                ]
                let temarr = [tmpdict]
                subtitles["en"] = temarr
                print("\n subtitles ==> = \(subtitles)")
            }
            
            var thumbnail = flashvars["image_url"]
            var duration = flashvars["video_duration"]
            var media_definitions = flashvars["mediaDefinitions"]
            
            
            if let media_definitionsarray = media_definitions as? Array<Any> {
                for definition in media_definitionsarray {
                    let definitiondict = definition as? Dictionary<String, Any>
                    if definitiondict == nil {
                        continue
                    }
                    print("\n definitiondict -> \(definitiondict)")
                    if let video_url = definitiondict!["videoUrl"] as? String, video_url.isEmpty == false {
                        if video_urls_set.contains(video_url) {
                            continue
                        }
                        video_urls_set.insert(video_url)
                        video_urls.append(
                            (video_url, definitiondict!["quality"] as! String )
                        )
                        print("\n video_urls_set ==> = \(video_urls_set)")
                        
                    } else {
                        continue
                    }
                }
            }
        } else {
        } // if
        
        func  extract_js_vars(webpage: String, pattern : [String], default: String?) -> [String: Any] {
            let assignments = self._search_regex(pattern: pattern, string: webpage, name: "encoded url", group: nil)
            print("\n  assignments = \(assignments)")
            guard assignments != nil else {
                return [:]
            }
            let assignmentsArr =  assignments?.split(separator: ";").map({ subs in
                return String(subs)
            }) ?? []
            
            var js_vars: [String : String] = [:]
            
            func  parse_js_value(inp: String) -> String? {
                if let newinp =  #"/\*(?:(?!\*/).)*?\*/"#.r?.replaceAll(in: inp, with: "") {
                    print("\n newinp--> = \(newinp)")
                    if newinp.contains("+") {
                        let inps = newinp.split(separator: "+").compactMap { s in
                            String(s)
                        }
                        
                        let res = inps.map { s in
                            return parse_js_value(inp: s)
                        }.reduce("") { partialResult, s in
                            partialResult + s!
                        }
                        return res
                    } // if
                    let newinp = inp.trimmingCharacters(in: .whitespacesAndNewlines)
                    if js_vars.keys.contains(newinp) {
                        return js_vars[newinp]
                    }
                    return remove_quotes(s: newinp)
                }
                return nil
            }
            
            for assn in assignmentsArr {
                var tmpassn = assn.trimmingCharacters(in: .whitespacesAndNewlines)
                if tmpassn.isEmpty {
                    continue
                }
                tmpassn = #"var\s+"#.r?.replaceAll(in: assn, with: "") ?? tmpassn
                let vname = String(tmpassn.split(separator: "=", maxSplits: 1).first ?? "")
                let value = String(tmpassn.split(separator: "=", maxSplits: 1).last ?? "")
                print("\n vnam --->\(vname)--va=\(value)")
                if vname.isEmpty == false, value.isEmpty == false {
                    js_vars[vname] = parse_js_value(inp: value)
                }
                print("js_va-->\(js_vars)")
            }
            
            print("js_va-->\(js_vars)")
            return js_vars
        }
        
        func add_video_url(video_url: String?) {
            print("\n video_url ==> = \(video_url)")
            let v_url = url_or_none(url: video_url)
            if v_url == nil {
                return
            }
            
            if video_urls_set.contains(v_url!) {
                return
            }
            video_urls.append((v_url!,""))
            video_urls_set.insert(v_url!)
        }
        
        func parse_quality_items(quality_items: String) {
            if let q_items = self._parse_json(json_string: quality_items, video_id: video_id, fatal: false) as? [Any] {
                for item in q_items {
                    if let dict = item as? [String : Any] ,let durl = dict["url"] as? String {
                        add_video_url(video_url: durl)
                    }
                }
            } else {
                return
            }
        }
        
        if video_urls.count == 0 {
            let p = #"(var\s+(?:"# + PornHubIE.FORMAT_PREFIXES.joined(separator: "|") + #")_.+)"#
            let js_vars = extract_js_vars(webpage: webpage, pattern: [p], default: nil)
            if js_vars.count > 0 {
                for (key, format_url) in js_vars {
                    if key.starts(with: PornHubIE.FORMAT_PREFIXES.last!) {
                        parse_quality_items(quality_items: format_url as! String)
                    } else {
                        for p in PornHubIE.FORMAT_PREFIXES[...2] {
                            if key.starts(with: p) {
                                add_video_url(video_url: format_url as? String)
                                break
                            }
                        } // for
                    }
                } // for
            } // if
            let tmpMatch = #"<[^>]+\bid=["\']lockedPlayer"#.r?.findFirst(in: webpage)
            if video_urls.count == 0, tmpMatch != nil {
                print("\n --->video is locked ")
            }
        }
        print(" \n --> video_urls = \(video_urls)")
        
        if video_urls.count == 0 {
            let content = await dl_webpage(platform: "tv") ?? ""
            if let js_vars = extract_js_vars(webpage: content, pattern: [#"(var.+?mediastring.+?)</script>"#], default: nil) as? [String : Any] {
                if  let tmpme = js_vars["mediastring"] as? String {
                    add_video_url(video_url: tmpme)
                }
            }
        }
        
        if let findres = #"<a[^>]+\bclass=["\']downloadBtn\b[^>]+\bhref=(["\'])(?<url>(?:(?!\1).)+)\1"#.r?.findAll(in: webpage) {
            for mobj in findres {
                if let video_url =  mobj.groupWith(name: "url"), video_urls_set.contains(video_url) == false {
                    video_urls.append((video_url, ""))
                    video_urls_set.insert(video_url)
                }
            }
        }
        
        var formats: [[String: Any]] = []
        var upload_date: String?
        
        func add_format(format_url: String, height: String?) async {
            print("\n -format_url = \(format_url) --> height = \(height)")
            let ext = determine_ext(url: format_url)
            if ext == "mpd" {
                
            }
            
            if ext == "m3u8" {
                let mats = await self._extract_m3u8_formats(m3u8_url: format_url, video_id: video_id, ext: "mp4", entry_protocol: "m3u8_native", preference: nil, m3u8_id: "hls", note: nil, errnote: nil, fatal: false, data: nil, headers: nil, query: nil)
                print("\n mats --> \(mats)")
                formats.append(contentsOf: mats)
            }
            
            if height == nil, let ht = self._search_regex(pattern: [#"?<height>\d+)[pP]?_\d+[kK]"#], string: format_url, name: "height", group: nil) {
                formats.append([
                    "url": format_url,
                    "format_id": "\(ht)p",
                    "height" : ht
                ])
            } else {
                formats.append([
                    "url": format_url,
                    "format_id": "\(height ?? "")p",
                    "height" : height ?? ""
                ])
            }
        } // func
        
        
        for (idx, (video_url, height)) in video_urls.enumerated() {
            if upload_date == nil {
                if let uploaddate = self._search_regex(pattern: [#"/(\d{6}/\d{2})/"#], string: video_url, name: "upload date", group:  nil) {
                    upload_date = uploaddate.replacingOccurrences(of: "/", with: "")
                }
            } // if
            print("\n idx=\(idx)-url=\(video_url)-->date=\(upload_date) ")
            if video_url.contains("/video/get_media") {
                let medias = await self._download_json(url_or_request: video_url, video_id: video_id)
                print("\n -medias = \(medias)")
                if let mearray = medias as? [Any] {
                    for media in mearray {
                        if let medict = media as? [String : Any] {
                            if let tmpu =  url_or_none(url: (medict["videoUrl"] as? String)) {
                                //                                    video_url = tmpu
                                video_urls[idx].0 = tmpu
                                video_urls[idx].1 = (medict["quality"] as? String) ?? ""
                                await add_format(format_url: video_urls[idx].0, height: video_urls[idx].1)
                            } else {
                                continue
                            }
                        } else {
                            continue
                        }
                    }
                }
            } // if
            
            
            await add_format(format_url: video_url, height: nil)
        } // for
        print("完成了 format = \(formats)")
        
        return [
            "formats": formats,
            "title": title
        ]
    }
    
    static func _extract_urls(webpage: String) {
        #"<iframe[^>]+?src=["\'](?P<url>(?:https?:)?//(?:www\.)?pornhub(?:premium)?\.(?:com|net|org)/embed/[\da-z]+)"#.r?.findAll(in: webpage)
    }
}

class PornHubPlaylistBaseIE: PornHubBaseIE {
    func _extract_page(url: String) -> String? {
        return self._search_regex(pattern: [#"\bpage=(\d+)"#], string: url, name: "page", group: nil)
    }
    
    func _extract_entries(webpage: String, host: String) {
       let container = self._search_regex(pattern: [#"(?s)(<div[^>]+class=["\']container.+)"#], string: webpage, name: "container", group: nil)
        
    }
}
