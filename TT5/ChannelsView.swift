//
//  ChannelsView.swift
//  TT5
//
//  Created by Hilxen on 12/23/24.
//

import SwiftUI
import SwiftData

struct FoundChannels: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentation
    @Query private var channels: [Channel]
    @Query private var settings: [Settings]
    @State private var multiSelection = Set<String>()

    init(search: String) {
        if search.isEmpty {
            self._channels = Query(sort: \.name)
        } else {
            self._channels = Query(filter: #Predicate<Channel> { $0.name.localizedStandardContains(search) }, sort: \.name)
        }
    }
    
    func selectChannel(channel: Channel) {
        settings.first!.channel = channel.name
        try! modelContext.save()
        presentation.wrappedValue.dismiss()
    }

    var body: some View {
        List(channels, selection: $multiSelection) { channel in
            HStack {
                Text(channel.name)
            }.swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    modelContext.delete(channel)
                    try! modelContext.save()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }.swipeActions(edge: .leading) {
                Button() {
                    selectChannel(channel: channel)
                } label: {
                    Label("Select", systemImage: "checkmark.circle.fill")
                }.tint(.blue)
            }
        }
        .toolbar {
            EditButton()
        }
        if !multiSelection.isEmpty {
            HStack {
                if multiSelection.count == 1 {
                    Button() {
                        selectChannel(channel: Channel(name: multiSelection.first!))
                    } label: {
                        Label("Select", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
                Button(role: .destructive) {
                    for channelName in multiSelection {
                        modelContext.delete(channels.first(where: { $0.name == channelName })!)
                    }
                    try! modelContext.save()
                    multiSelection.removeAll()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                
            }.padding(.horizontal, 20)
        }
    }
}

struct ChannelsListView: View {
    @State private var search: String = ""

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $search)
                    .padding(5)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.black)
                    .padding(.trailing, 20)
            }.padding(.vertical, 5).padding(.leading, 20)
            FoundChannels(search: search)
            Spacer()
        }.navigationTitle("Saved channels")
    }
}
