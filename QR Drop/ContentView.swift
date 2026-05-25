//
//  ContentView.swift
//  QR Drop
//
//  Created by dylan on 5/24/26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

struct ContentView: View {
    @State private var mode: String? = nil
    @State private var inputText = ""
    @State private var qrImage: UIImage?
    @State private var showShareSheet = false
    @State private var scannedCode = ""

    let haptic = UINotificationFeedbackGenerator()

    var isScannedURL: Bool {
        scannedCode.lowercased().hasPrefix("http")
    }

    var body: some View {
        NavigationView {
            VStack {
                if mode != nil {
                    HStack {
                        Button(action: {
                            resetToHome()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }

                if mode == nil {
                    homeView
                }

                else if mode == "generate" {
                    generateView
                }

                else if mode == "scan" {
                    scanView
                }
            }
            .navigationBarHidden(true)
            .navigationViewStyle(StackNavigationViewStyle())
            .sheet(isPresented: $showShareSheet) {
                if let qr = qrImage {
                    ShareSheet(activityItems: [qr])
                }
            }
        }
    }

    var homeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "qrcode")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("QR Drop")
                .font(.largeTitle)
                .fontWeight(.bold)

            Button(action: {
                mode = "scan"
            }) {
                Text("Scan QR")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }

            Button(action: {
                mode = "generate"
            }) {
                Text("Generate QR")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
            }

            Spacer()
        }
        .padding()
    }

    var generateView: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField(
                    "Enter text or URL",
                    text: $inputText
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                Button(action: {
                    qrImage = generateQR(from: inputText)
                }) {
                    Text("Generate")
                        .font(.headline)
                }

                if let qr = qrImage {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)

                    HStack(spacing: 20) {
                        Button("Save") {
                            UIImageWriteToSavedPhotosAlbum(
                                qr,
                                nil,
                                nil,
                                nil
                            )
                        }

                        Button("Share") {
                            showShareSheet = true
                        }
                    }
                }
            }
            .padding()
        }
    }

    var scanView: some View {
        VStack {
            QRScannerView(
                scannedCode: $scannedCode,
                onScanSuccess: {
                    haptic.notificationOccurred(.success)
                }
            )
            .frame(height: 400)
            .cornerRadius(20)
            .padding()

            if !scannedCode.isEmpty {
                VStack(spacing: 16) {
                    Text(scannedCode)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button("Copy") {
                            UIPasteboard.general.string = scannedCode
                        }

                        if isScannedURL,
                           let url = URL(string: scannedCode) {
                            Link("Open URL", destination: url)
                        }
                    }
                }
            }

            Spacer()
        }
    }

    func resetToHome() {
        mode = nil
        inputText = ""
        qrImage = nil
        scannedCode = ""
    }

    func generateQR(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.setValue(Data(string.utf8), forKey: "inputMessage")

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scaled = outputImage.transformed(
            by: CGAffineTransform(scaleX: 10, y: 10)
        )

        guard let cgImage = context.createCGImage(
            scaled,
            from: scaled.extent
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
