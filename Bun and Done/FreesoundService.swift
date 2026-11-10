//
//  FreesoundService.swift
//  Bun and Done
//
//  Created by Clare Ahn on 10/11/2026.
//

import Foundation

// These structs match the shape of the JSON returned by the Freesound search API,
// so JSONDecoder can turn the response into Swift objects

// Top level of the response: a list of matching sounds
struct FreesoundSearchResponse: Decodable {
    let results: [FreesoundSound]
}

// One sound from the search results
struct FreesoundSound: Decodable, Identifiable {
    let id: Int
    let name: String
    let username: String
    let previews: Previews

    // Links to audio files Freesound generates for each sound
    struct Previews: Decodable {
        let highQualityMP3: URL

        // The JSON key contains dashes, which Swift names can't have
        enum CodingKeys: String, CodingKey {
            case highQualityMP3 = "preview-hq-mp3"
        }
    }
}
// Errors this service can throw, with messages that are shown to the user
enum FreesoundError: LocalizedError {
    case badResponse
    case noResults

    var errorDescription: String? {
        switch self {
        case .badResponse: return "Couldn't load sounds right now. Please try again later."
        case .noResults:   return "No sounds found for this option."
        }
    }
}

// Handles calling the Freesound API
struct FreesoundService {
    private let searchURL = "https://freesound.org/apiv2/search/text/"

    // Searches Freesound and returns the decoded list of sounds
    func searchSounds(query: String) async throws -> [FreesoundSound] {
        guard var components = URLComponents(string: searchURL) else {
            throw FreesoundError.badResponse
        }
        
        // URLComponents builds the full URL and safely encodes spaces and symbols
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            // Sounds between 1 and 10 minutes long, free to use with no attribution required, cc0 = no need credit
            URLQueryItem(name: "filter", value: "duration:[60 TO 600] license:\"Creative Commons 0\""),
            // Only ask for the fields the app uses, to keep the response small
            URLQueryItem(name: "fields", value: "id,name,username,previews"),
            URLQueryItem(name: "page_size", value: "10"),
            URLQueryItem(name: "token", value: APIKeys.freesound)
        ]

        guard let url = components.url else { throw FreesoundError.badResponse }
        
        // Waits for the network request without freezing the app
        let (data, response) = try await URLSession.shared.data(from: url)

        // Anything other than 200 (e.g. 401 for a wrong API key) counts as a failure
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FreesoundError.badResponse
        }

        // Turn the JSON data into FreesoundSearchResponse
        let decoded = try JSONDecoder().decode(FreesoundSearchResponse.self, from: data)
        guard decoded.results.isEmpty == false else { throw FreesoundError.noResults }
        return decoded.results
    }
}
