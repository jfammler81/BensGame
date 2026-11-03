import UIKit

extension UIImage {
    /// Verkleinert das Bild (falls nötig) und normalisiert dabei die Ausrichtung.
    func resized(maxDimension: CGFloat) -> UIImage {
        let largest = max(size.width, size.height)
        let scale = largest > maxDimension ? maxDimension / largest : 1
        let newSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
