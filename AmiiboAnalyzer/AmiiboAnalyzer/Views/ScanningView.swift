//
//  ContentView.swift
//  AmiiboAnalyzer
//
//  Created by John Blanco on 6/3/26.
//

import SwiftUI

struct ScanningView: View {
    @State private var scanner = NFCScannerManager()
    @State private var service = AmiiboService()
    @State private var showingDetail = false
    @State private var detectedAmiiboId: String?
    @State private var detectedAmiibo: Amiibo?
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.1), Color(white: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if showingDetail {
                amiiboDetail()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                scanningDisplay()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showingDetail)
        .task {
            for await tag in scanner.detectedTags {
                if let id = try? await scanner.readAmiiboID(from: tag) {
                    scanner.stopScanning()
                    detectedAmiiboId = id
                    showingDetail = true
                }
            }
        }
    }

    func scanningDisplay() -> some View {
        VStack(spacing: 60) {
            Image("amiibo-circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140)
                .clipShape(Circle())
                .scaleEffect(scanner.isScanning ? 1.10 : 1.0)
                .shadow(color: .white, radius: 20)
                .opacity(scanner.isScanning ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scanner.isScanning)
                .padding(.top, 32)

            Button("Scan Amiibo") {
                scanner.isScanning ? scanner.stopScanning() : scanner.startScanning()
            }
            .buttonStyle(.borderedProminent)
            .opacity(scanner.isScanning ? 0 : 1)
            .animation(.linear, value: scanner.isScanning)
            
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    func amiiboDetail() -> some View {
        if let _ = detectedAmiibo {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        AsyncImage(url: detectedAmiibo!.image) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 200, height: 200)
                        
                        Text(detectedAmiibo!.name)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                            detailRow("Character", value: detectedAmiibo!.character)
                            detailRow("Game Series", value: detectedAmiibo!.gameSeries)
                            detailRow("Amiibo Series", value: detectedAmiibo!.amiiboSeries)
                            detailRow("Type", value: detectedAmiibo!.type.rawValue)
                            if let releaseDate = detectedAmiibo!.release.na {
                                detailRow("Released (NA)", value: releaseDate)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
                
                Spacer()
                
                Button {
                    showingDetail = false
                    detectedAmiibo = nil
                    detectedAmiiboId = nil
                    scanner.startScanning()
                } label: {
                    Text("Scan Another")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack {
                Text("Loading Amiibo Details...")
                ProgressView()
            }
            .task {
                guard let detectedAmiiboId else { return }
                detectedAmiibo = try? await service.findAmiibo(by: detectedAmiiboId)
            }
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .gridColumnAlignment(.leading)
        }
    }
}

#Preview {
    ScanningView()
}
