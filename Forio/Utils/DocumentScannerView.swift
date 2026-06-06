import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    var completion: (Result<VNDocumentCameraScan, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController,
                                context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var completion: (Result<VNDocumentCameraScan, Error>) -> Void

        init(completion: @escaping (Result<VNDocumentCameraScan, Error>) -> Void) {
            self.completion = completion
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan) {
            completion(.success(scan))
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error) {
            completion(.failure(error))
            controller.dismiss(animated: true)
        }

        func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
    }
}
