//
//  FaceFrameApp.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import SwiftUI

@main
struct FaceFrameApp: App {
    private let container = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            container.makeTryOnView()
        }
    }
}
