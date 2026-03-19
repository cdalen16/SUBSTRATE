import Foundation

struct PixelArtAsset: Codable {
    let name: String
    let width: Int
    let height: Int
    let pixels: [[String]]  // rows of hex color strings
}
