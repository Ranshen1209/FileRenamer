//
//  SettingsView.swift
//  FileRenamer
//
//  Created by Ariel on 2025/4/27.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("imageCounter") private var imageCounter: Int = 1
    @AppStorage("videoCounter") private var videoCounter: Int = 1

    private func formatCounter(_ value: Int) -> String {
        String(format: "%05d", value)
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(alignment: .leading) {
                Text("当前计数器值")
                    .font(.title2)
                    .padding(.bottom, 5)

                HStack {
                    Text("下一个图片编号: \(formatCounter(imageCounter))")
                        .font(.system(.body, design: .monospaced))
                        .padding(5)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                    Spacer()
                    Text("下一个视频编号: \(formatCounter(videoCounter))")
                        .font(.system(.body, design: .monospaced))
                        .padding(5)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                .padding(.bottom)

                Divider()

                Text("修改起始编号")
                    .font(.title2)
                    .padding(.top)
                    .padding(.bottom, 5)

                Stepper("图片起始编号: \(imageCounter)", value: $imageCounter, in: 1...99999)
                Stepper("视频起始编号: \(videoCounter)", value: $videoCounter, in: 1...99999)

                Spacer()
            }
            .padding()
            .frame(minWidth: 350, idealWidth: 400, minHeight: 200)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
