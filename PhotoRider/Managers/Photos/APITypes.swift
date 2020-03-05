//
//  APITypes.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation

/*
 The following structs represent the responses of the Flickr API.

 Example of a response of the API flickr.photos.search:
 {
    "stat":"ok",
    "photos":{
        "page":1,
        "pages":4803,
        "perpage":5,
        "total":"24011",
        "photo":[{
            "id":"49583092977",
            "owner":"59514628@N00",
            "secret":"cc348e9fac",
            "server":"65535",
            "farm":66,
            "title":"All Around",
            "ispublic":1,
            "isfriend":0,
            "isfamily":0
 
        },{
            "id":"49571742413",
            "owner":"89509320@N05",
            "secret":"000cce2141",
            "server":"65535",
            "farm":66,
            "title":"20190213_181341",
            "ispublic":1,
            "isfriend":0,
            "isfamily":0
        }]
    }
 }
 
 Example of a response of the API flickr.photos.getSizes:
 {
    "sizes": {
        "canblog": 0,
        "canprint": 0,
        "candownload": 1,
        "size": [{
            "label": "Square",
            "width": 75,
            "height": 75,
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_s.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/sq\/",
            "media": "photo"
        },{
            "label": "Large Square",
            "width": "150",
            "height": "150",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_q.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/q\/",
            "media": "photo"
        },{
            "label": "Thumbnail",
            "width": 100,
            "height": 67,
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_t.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/t\/",
            "media": "photo"
        },{
            "label": "Small",
            "width": "240",
            "height": "160",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_m.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/s\/",
            "media": "photo"
        },{
            "label": "Small 320",
            "width": "320",
            "height": "213",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_n.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/n\/",
            "media": "photo"
        },{
            "label": "Small 400",
            "width": "400",
            "height": "267",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_w.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/w\/",
            "media": "photo"
        },{
            "label": "Medium",
            "width": "500",
            "height": "333",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/m\/",
            "media": "photo"
        },{
            "label": "Medium 640",
            "width": "640",
            "height": "427",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_z.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/z\/",
            "media": "photo"
        },{
            "label": "Medium 800",
            "width": "800",
            "height": "533",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_c.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/c\/",
            "media": "photo"
        },{
            "label": "Large",
            "width": "1024",
            "height": "683",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_993ea388c8_b.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/l\/",
            "media": "photo"
        },{
            "label": "Large 1600",
            "width": "1600",
            "height": "1067",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_acf4952506_h.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/h\/",
            "media": "photo"
        },{
            "label": "Large 2048",
            "width": "2048",
            "height": "1365",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_7e9349dd89_k.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/k\/",
            "media": "photo"
        },{
            "label": "X-Large 3K",
            "width": "3072",
            "height": "2048",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_45de9d536d_3k.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/3k\/",
            "media": "photo"
        },{
            "label": "X-Large 4K",
            "width": "4096",
            "height": "2731",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_7779054cee_4k.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/4k\/",
            "media": "photo"
        },{
            "label": "X-Large 5K",
            "width": "5120",
            "height": "3413",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_9cb0102084_5k.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/5k\/",
            "media": "photo"
        },{
            "label": "Original",
            "width": "5472",
            "height": "3648",
            "source": "https:\/\/live.staticflickr.com\/65535\/49581109756_005cd4051d_o.jpg",
            "url": "https:\/\/www.flickr.com\/photos\/nagarazoku\/49581109756\/sizes\/o\/",
            "media": "photo"
        }]
    },
    "stat": "ok"
}
 */

struct PhotosAPIResponse: Codable {
    let photos: PhotosAPI
}

struct PhotosAPI: Codable {
    let photo: [PhotoAPI]
}

struct PhotoAPI: Codable {
    let id: String
}

struct SizesAPIResponse: Codable {
    let sizes: SizesAPI
}

struct SizesAPI: Codable {
    let size: [SizeAPI]
}

struct SizeAPI: Codable {
    let width: Int
    let height: Int
    let source: String
}
