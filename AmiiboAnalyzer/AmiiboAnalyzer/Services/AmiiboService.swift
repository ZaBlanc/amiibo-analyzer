//
//  AmiiboService.swift
//  AmiiboAnalyzer
//

import Foundation

final class AmiiboService {
    private let baseURL = URL(string: "https://amiiboapi.org/api/")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func findAmiibo(by id: String) async throws -> Amiibo {
        let url = baseURL.appending(path: "amiibo/").appending(queryItems: [URLQueryItem(name: "id", value: id)])
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AmiiboServiceError.invalidResponse
        }

        return try JSONDecoder().decode(AmiiboResponse.self, from: data).amiibo
    }
}

enum AmiiboServiceError: Error {
    case invalidResponse
}
