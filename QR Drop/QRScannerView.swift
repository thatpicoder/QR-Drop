//
//  QRScannerView.swift
//  QR Drop
//
//  Created by dylan on 5/24/26.
//

import SwiftUI
import AVFoundation
import UIKit

struct QRScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    let onScanSuccess: () -> Void

    func makeUIViewController(
        context: Context
    ) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(
        _ uiViewController: ScannerViewController,
        context: Context
    ) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRScannerView

        init(_ parent: QRScannerView) {
            self.parent = parent
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                let object = metadataObjects.first
                    as? AVMetadataMachineReadableCodeObject,
                let string = object.stringValue
            else {
                return
            }

            if parent.scannedCode != string {
                parent.scannedCode = string
                parent.onScanSuccess()
            }
        }
    }
}

class ScannerViewController: UIViewController {
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    private let session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        output.setMetadataObjectsDelegate(
            delegate,
            queue: DispatchQueue.main
        )

        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill

        view.layer.addSublayer(preview)

        session.startRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let preview = view.layer.sublayers?.first
            as? AVCaptureVideoPreviewLayer {
            preview.frame = view.bounds
        }
    }
}
