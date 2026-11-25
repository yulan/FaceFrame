//
//  TestVideo.swift
//  DataLayerTests
//
//  Created by Lan YU on 21/11/2026.
//

import AVFoundation
import Foundation

/// Writes a small H.264 clip to a temporary file, so no video is committed.
enum TestVideo {
    struct WriteError: Error {}

    /// `transform`: the playback transform stored in the file.
    static func make(
        frameCount: Int,
        width: Int = 64,
        height: Int = 48,
        framesPerSecond: Int32 = 10,
        transform: CGAffineTransform = .identity
    ) async throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FaceFrame-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
        ])
        input.expectsMediaDataInRealTime = false
        input.transform = transform
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ])
        guard writer.canAdd(input) else { throw WriteError() }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? WriteError() }
        writer.startSession(atSourceTime: .zero)

        for index in 0..<frameCount {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(5))
            }
            guard let pool = adaptor.pixelBufferPool else { throw WriteError() }
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            guard let buffer else { throw WriteError() }
            let time = CMTime(value: CMTimeValue(index), timescale: framesPerSecond)
            guard adaptor.append(buffer, withPresentationTime: time) else { throw writer.error ?? WriteError() }
        }
        input.markAsFinished()
        // The last frame gets its full duration.
        writer.endSession(atSourceTime: CMTime(value: CMTimeValue(frameCount), timescale: framesPerSecond))
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? WriteError() }
        return url
    }
}
