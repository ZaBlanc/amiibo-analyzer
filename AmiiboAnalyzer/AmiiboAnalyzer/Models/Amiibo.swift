//
//  Amiibo.swift
//  AmiiboAnalyzer
//

import Foundation

struct AmiiboResponse: Decodable {
    let amiibo: Amiibo
}

struct Amiibo: Decodable, Sendable {
    let amiiboSeries: String
    let character: String
    let gameSeries: String
    let head: String
    let tail: String
    let name: String
    let type: AmiiboType
    let image: URL
    let imageWebP: URL
    let release: Release

    var id: String { head + tail }

    enum CodingKeys: String, CodingKey {
        case amiiboSeries, character, gameSeries, head, tail, name, type, image, release
        case imageWebP = "imgwebp"
    }

    enum AmiiboType: String, Decodable, Sendable {
        case figure = "Figure"
        case card = "Card"
        case yarn = "Yarn"
    }

    struct Release: Decodable, Sendable {
        let na: String?
        let jp: String?
        let eu: String?
        let au: String?
    }
}
