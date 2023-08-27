//
//  YBDL.swift
//  IE
//
//  Created by wz on 2023/2/6.
//

import Foundation
//import Alamofire

class YBDL {

    static let `default` = YBDL()
    
    // 请求具体网页
    func urlopen(url_or_request: String, pornhun: Bool = false) async -> (String?,HTTPURLResponse?) {
        let url = URL(string: url_or_request)!
        var req = URLRequest(url: url)
        if  pornhun == true {
            req.setValue("pc", forHTTPHeaderField: "platform")
            req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.109 Safari/537.36", forHTTPHeaderField: "User-Agent")
        }
        print("req = \(req.allHTTPHeaderFields)")
        guard let result = try? await URLSession.shared.data(for: req) else {
            return (nil, nil)
        }
        
        let data = result.0
        let html = String(data: data, encoding: .utf8)
        let httpres = result.1 as? HTTPURLResponse
        print("\n - res = \(httpres)")
        return (html,httpres)
    }
}
