//
//  TryOnView.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import DataLayer
import Domain
import SwiftUI
import UIKit

/// What is drawn behind the glasses.
enum TryOnBackdrop {
    /// The camera's own preview layer.
    case camera
    /// The frames of a replay.
    case frames(FramePreviewFeed)
    /// Nothing: the simulated pupils have no picture.
    case plain
}

struct TryOnView: View {
    @State var viewModel: TryOnViewModel
    let backdrop: TryOnBackdrop
    @Environment(\.openURL) private var openURL

    var body: some View {
        GeometryReader { proxy in
            let viewSize = Size2D(width: proxy.size.width, height: proxy.size.height)
            ZStack {
                backdropView
                if let placement = viewModel.glassesPlacement(in: viewSize) {
                    GlassesOverlayView(placement: placement)
                }
                if viewModel.showsLandmarks {
                    LandmarksOverlayView(points: viewModel.landmarkPoints(in: viewSize))
                }
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .top) { topBar }
        .overlay(alignment: .bottom) { bottomBar }
        .overlay { failureView }
        .task(id: viewModel.runID) {
            await viewModel.run()
        }
    }

    @ViewBuilder
    private var backdropView: some View {
        switch backdrop {
        case .camera:
            CameraPreviewView()
        case .frames(let feed):
            FramePreviewView(feed: feed)
        case .plain:
            Color(.previewBackground)
        }
    }

    private var topBar: some View {
        HStack {
            if let performance = viewModel.performanceText {
                PerformanceBadge(text: performance)
            }
            Spacer()
            if let source = viewModel.sourceLabel {
                PerformanceBadge(text: source)
            }
        }
        .padding()
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if let hint = viewModel.noFaceHint {
                Text(hint)
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
            }
            Button {
                viewModel.showsLandmarks.toggle()
            } label: {
                Image(systemName: AppSymbol.landmarks.rawValue)
                    .font(.title2)
                    .padding(12)
                    .background(.regularMaterial, in: Circle())
            }
            .accessibilityLabel(viewModel.showsLandmarks ? L10n.TryOn.hideLandmarks : L10n.TryOn.showLandmarks)
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var failureView: some View {
        if case .failed(let error) = viewModel.state {
            let content = FailureContent(error: error)
            ContentUnavailableView {
                Label {
                    Text(content.title)
                } icon: {
                    Image(systemName: content.symbol.rawValue)
                }
            } description: {
                Text(content.message)
            } actions: {
                if error == .cameraAccessDenied, let settings = URL(string: UIApplication.openSettingsURLString) {
                    Button(L10n.TryOn.openSettings) { openURL(settings) }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button(L10n.TryOn.retry) { viewModel.retry() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .background(.regularMaterial)
        }
    }
}

/// Wording and symbol for each failure, out of the view body.
private struct FailureContent {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let symbol: AppSymbol

    init(error: TrackingError) {
        switch error {
        case .cameraAccessDenied:
            title = L10n.TryOn.Failure.deniedTitle
            message = L10n.TryOn.Failure.deniedMessage
            symbol = .cameraDenied
        case .cameraUnavailable:
            title = L10n.TryOn.Failure.unavailableTitle
            message = L10n.TryOn.Failure.unavailableMessage
            symbol = .warning
        case .sourceFailed:
            title = L10n.TryOn.Failure.failedTitle
            message = L10n.TryOn.Failure.failedMessage
            symbol = .warning
        }
    }
}

#Preview("Simulated") {
    TryOnView(viewModel: TryOnViewModel(session: SimulatedTrackingSession(), mode: .simulated), backdrop: .plain)
}
