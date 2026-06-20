// GitHubRelease.swift — Decodable models for the GitHub Releases API response.
// Owner: Core/Models
// Depends on: Foundation
// Used by: Core/Services/AeroBarUpdateEngine

import Foundation

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String
}

struct GitHubRelease: Codable {
    let tagName: String?
    let body: String?
    let assets: [GitHubAsset]?
}
