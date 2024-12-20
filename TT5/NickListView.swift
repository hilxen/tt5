//
//  NickListView.swift
//  TT5
//
//  Created by Hilxen on 12/19/24.
//

import SwiftUI
import SwiftData

struct FoundNicks: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var nicks: [Nick]
    @State private var multiSelection = Set<String>()

    init(search: String) {
        if search.isEmpty {
            self._nicks = Query(sort: \.name)
        } else {
            self._nicks = Query(filter: #Predicate<Nick> { $0.name.localizedStandardContains(search) }, sort: \.name)
        }
    }

    var body: some View {
        List(nicks, selection: $multiSelection) { nick in
            HStack {
                NavigationLink(destination: NickView(nick: nick)) {
                    Text(nick.name)
                }
            }.swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    modelContext.delete(nick)
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
                    for nickName in multiSelection {
                        modelContext.delete(nicks.first(where: { $0.name == nickName })!)
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

struct NickListView: View {
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
            FoundNicks(search: search)
            Spacer()
        }.navigationTitle("Nicks")
    }
}
