//
//  CustomRewardListView.swift
//  TT5
//
//  Copyright (c) Hilxen. MIT License.
//

import SwiftUI
import SwiftData

struct FoundCustomRewards: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var customRewards: [CustomReward]
    @State private var multiSelection = Set<String>()

    init(search: String) {
        if search.isEmpty {
            self._customRewards = Query(sort: \.name)
        } else {
            self._customRewards = Query(filter: #Predicate<CustomReward> { $0.name.localizedStandardContains(search) }, sort: \.name)
        }
    }

    var body: some View {
        List(customRewards, selection: $multiSelection) { customReward in
            HStack {
                NavigationLink(destination: CustomRewardView(customReward: customReward)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(customReward.name.isEmpty ? customReward.id : customReward.name)
                        }
                    }
                }
            }.swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    modelContext.delete(customReward)
                    try! modelContext.save()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .toolbar {
            EditButton()
        }
        if !multiSelection.isEmpty {
            HStack {
                Button(role: .destructive) {
                    for id in multiSelection {
                        modelContext.delete(customRewards.first(where: { $0.id == id })!)
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

struct CustomRewardListView: View {
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
                    .foregroundColor(.primary)
                    .padding(.trailing, 20)
            }.padding(.vertical, 5).padding(.leading, 20)
            FoundCustomRewards(search: search)
            Spacer()
        }.navigationTitle("Custom Rewards")
    }
}
