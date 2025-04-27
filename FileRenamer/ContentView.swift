//
//  ContentView.swift
//  FileRenamer
//
//  Created by Ariel on 2025/4/27.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("imageCounter") private var imageCounter: Int = 1
    @AppStorage("videoCounter") private var videoCounter: Int = 1
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var imageCounterInput: String = ""
    @State private var videoCounterInput: String = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "webp", "heic", "heif", "svg", "ico", "raw", "arw", "cr2", "nef", "orf", "rw2", "dng"]
    private static let videoExtensions: Set<String> = ["mp4", "m4v", "mov", "avi", "mkv", "wmv", "flv", "webm", "mpeg", "mpg", "m2ts", "mts", "ts", "vob", "3gp", "3g2", "rm", "rmvb", "ogv"]

    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("将图片或视频文件拖到此处以重命名")
                    .font(.headline)
                    .padding(.horizontal)
                
                Divider()
                Text("当前计数器值")
                    .font(.title2)
                
                HStack {
                    Text("下一个图片编号: \(formatCounter(imageCounter))")
                        .font(.system(.body, design: .monospaced))
                        .padding(5)
                        .background(
                            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        )
                    Spacer()
                    Text("下一个视频编号: \(formatCounter(videoCounter))")
                        .font(.system(.body, design: .monospaced))
                        .padding(5)
                        .background(
                            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        )
                }
                
                Divider()

                Text("修改起始编号")
                    .font(.title2)
                
                HStack {
                    Text("图片起始编号:")
                    TextField("", text: $imageCounterInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(5)
                        .background(
                            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        )
                        .frame(width: 100)
                        .onChange(of: imageCounterInput) { oldValue, newValue in
                            validateAndUpdateCounter(input: newValue, forImage: true)
                        }
                        .onSubmit {
                            validateAndUpdateCounter(input: imageCounterInput, forImage: true, forceUpdate: true)
                        }
                        .onAppear {
                            imageCounterInput = String(imageCounter)
                        }
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack {
                    Text("视频起始编号:")
                    TextField("", text: $videoCounterInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(5)
                        .background(
                            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        )
                        .frame(width: 100)
                        .onChange(of: videoCounterInput) { oldValue, newValue in
                            validateAndUpdateCounter(input: newValue, forImage: false)
                        }
                        .onSubmit {
                            validateAndUpdateCounter(input: videoCounterInput, forImage: false, forceUpdate: true)
                        }
                        .onAppear {
                            videoCounterInput = String(videoCounter)
                        }
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 400, minHeight: 350)
            .fixedSize()
        }
        .dropDestination(for: URL.self) { urls, _ in
            DispatchQueue.main.async {
                processDroppedFiles(urls: urls)
            }
            return true
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    private func formatCounter(_ value: Int) -> String {
        String(format: "%05d", value)
    }

    private func validateAndUpdateCounter(input: String, forImage: Bool, forceUpdate: Bool = false) {
        if input.isEmpty && !forceUpdate {
            return
        }

        if input.isEmpty || Int(input) == nil || Int(input)! < 1 || Int(input)! > 99999 {
            if forImage {
                imageCounterInput = String(imageCounter)
            } else {
                videoCounterInput = String(videoCounter)
            }
            return
        }

        if let newValue = Int(input) {
            if forImage {
                imageCounter = newValue
            } else {
                videoCounter = newValue
            }
        }
    }

    @MainActor
    private func processDroppedFiles(urls: [URL]) {
        var successCount = 0
        for url in urls {
            if renameDroppedFile(url: url) {
                successCount += 1
            }
        }
        alertMessage = "成功重命名 \(successCount) 个文件，失败 \(urls.count - successCount) 个。"
        showingAlert = true
    }

    @MainActor
    private func renameDroppedFile(url: URL) -> Bool {
        guard let fileInfo = extractFileInfo(from: url) else {
            print("Could not extract file info from \(url.path)")
            return false
        }

        var currentCounter = getCurrentCounter(for: fileInfo.ext)
        guard currentCounter != -1 else {
            print("Unsupported file type: \(fileInfo.ext)")
            return false
        }

        var newFilename: String?
        var destinationURL: URL?
        var attempts = 0
        let maxAttempts = 10

        repeat {
            newFilename = generateNewFilename(for: fileInfo.ext, counter: currentCounter)
            guard newFilename != nil else {
                print("Could not generate new filename for \(url.path)")
                return false
            }

            destinationURL = constructDestinationURL(from: url, newFilename: newFilename!)
            if !FileManager.default.fileExists(atPath: destinationURL!.path) {
                break
            }

            currentCounter += 1
            attempts += 1
        } while attempts < maxAttempts

        guard let destinationURL = destinationURL, attempts < maxAttempts else {
            print("Error: Could not find available filename after \(maxAttempts) attempts")
            return false
        }

        if performRename(sourceURL: url, destinationURL: destinationURL) {
            incrementAndSaveCounter(for: fileInfo.ext, currentCounter: currentCounter)
            return true
        }
        return false
    }

    private func extractFileInfo(from url: URL) -> (path: String, name: String, ext: String)? {
        let path = url.path
        let ext = url.pathExtension.lowercased()
        let name = url.deletingPathExtension().lastPathComponent
        return ext.isEmpty ? nil : (path, name, ext)
    }

    private func getCurrentCounter(for fileExtension: String) -> Int {
        if ContentView.imageExtensions.contains(fileExtension) {
            return imageCounter
        } else if ContentView.videoExtensions.contains(fileExtension) {
            return videoCounter
        }
        return -1
    }

    private func generateNewFilename(for fileExtension: String, counter: Int) -> String? {
        let prefix = ContentView.imageExtensions.contains(fileExtension) ? "IMG_" : ContentView.videoExtensions.contains(fileExtension) ? "VID_" : nil
        guard let prefix else { return nil }
        let formattedCounter = String(format: "%05d", counter)
        return "\(prefix)\(formattedCounter).\(fileExtension)"
    }

    private func constructDestinationURL(from originalURL: URL, newFilename: String) -> URL {
        let directoryURL = originalURL.deletingLastPathComponent()
        let destinationURL = directoryURL.appendingPathComponent(newFilename)
        print("Source directory: \(directoryURL.path)")
        print("Destination path: \(destinationURL.path)")
        let isWritable = FileManager.default.isWritableFile(atPath: directoryURL.path)
        print("Is directory writable? \(isWritable)")
        return destinationURL
    }
    
    private func performRename(sourceURL: URL, destinationURL: URL) -> Bool {
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            print("Renamed \(sourceURL.lastPathComponent) to \(destinationURL.lastPathComponent)")
            return true
        } catch {
            _ = error as NSError
            alertMessage = "重命名失败：\(error.localizedDescription)"
            showingAlert = true
            return false
        }
    }

    private func incrementAndSaveCounter(for fileExtension: String, currentCounter: Int) {
        if ContentView.imageExtensions.contains(fileExtension) {
            imageCounter = currentCounter + 1
            imageCounterInput = String(imageCounter)
        } else if ContentView.videoExtensions.contains(fileExtension) {
            videoCounter = currentCounter + 1
            videoCounterInput = String(videoCounter)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
