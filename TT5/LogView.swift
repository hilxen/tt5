//
//  LogView.swift
//  TT5
//
//  Created by Hilxen on 3/31/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var log: [LogItem]
    
    func getLogLevelColor(_ level: String) -> Color {
        switch level {
        case "DEBUG":
            return .gray
        case "INFO":
            return .green
        case "WARNING":
            return .orange
        case "ERROR":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(Array(log.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 2) {
                                Text(item.timestamp.ISO8601Format())
                                Text(item.level)
                                Spacer()
                            }.bold().foregroundStyle(getLogLevelColor(item.level))
                            Text(item.message.joined(separator: " "))
                        }.font(.system(size: 12))
                    }
                }
            }.padding(.horizontal, 5)
            .onChange(of: log, {_, _ in
                DispatchQueue.main.async {
                    if !log.isEmpty {
                        withAnimation {
                            scrollView.scrollTo(log.endIndex - 1, anchor: .bottom)
                        }
                    }
                }
            })
            .onAppear {
                if !log.isEmpty {
                    withAnimation {
                        scrollView.scrollTo(log.endIndex - 1, anchor: .bottom)
                    }
                }
            }
        }.toolbar {
            Button("Copy") {
                var buffer = ""
                for item in self.log {
                    buffer += "\(item.timestamp.ISO8601Format()) \(item.level) \(item.message.joined(separator: " "))\n"
                }
                UIPasteboard.general.setValue(buffer, forPasteboardType: UTType.plainText.identifier)
            }.buttonStyle(.borderedProminent)

            Button("Clear") {
                try! modelContext.delete(model: LogItem.self)
                try! modelContext.save()
            }.buttonStyle(.bordered)
        }
    }
}
