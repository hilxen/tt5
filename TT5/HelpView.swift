//
//  HelpView.swift
//  TT5
//
//  Copyright (c) Hilxen. MIT License.
//

import SwiftUI
import SwiftData
import WebKit
import StoreKit

func getAppVersion() -> String {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    return appVersion ?? ""
}

struct FirstLaunchHelpView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Binding var firstLaunch: Bool
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            HelpView(confirmButtonAction: {
                firstLaunch.toggle()
                settings.first!.version = getAppVersion()
                try! modelContext.save()
            })
        }
    }
}

// Simple observable store manager
@Observable
final class TipStore {
    var products: [Product] = []
    var purchasedProductIDs = Set<String>()     // Optional: track if you want to show "thank you" after tip
    
    init() {
        Task { await loadProducts() }
        // Optional: listen for purchases (in case purchase happens outside this view)
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }
    
    func loadProducts() async {
        do {
            let productIDs = ["tip_1", "tip_5", "tip_10"]
            let prods = try await Product.products(for: productIDs)
            self.products = prods.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    // Optional: show thank you alert / confetti
                    print("Thank you for the tip!")
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}



struct HelpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentation
    @Query private var settings: [Settings]
    @State private var tipStore = TipStore()
    @State private var showThanks = false
    let content : AttributedString
    let confirmButtonAction: (() -> Void)?
    // The App Store logo is kept out of the public repo; fall back to the bundled placeholder
    private static let logoName = UIImage(named: "LogoStore") != nil ? "LogoStore" : "logo"

    init(confirmButtonAction: (() -> Void)? = nil) {
        let path = Bundle.main.path(forResource: "help", ofType: "md")!
        let str = try! String(contentsOfFile: path, encoding: .utf8)
        self.content = try! AttributedString(
            markdown: str,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            ))
        self.confirmButtonAction = confirmButtonAction
    }
                          
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            if confirmButtonAction != nil {
                HStack(spacing: 10) {
                    Text("Scroll to read and confirm!").padding(.all, 10)
                }.overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(.orange), lineWidth: 5))
                .padding(.all, 10)
            }
            HStack {
                Image(Self.logoName).resizable().scaledToFit().frame(height: 50)
                Text("TT5 for Twitch \(getAppVersion())").bold().font(.title)
                Spacer()
            }.padding(.vertical, 5).padding(.horizontal, 10)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(content).padding(.vertical, 5).padding(.horizontal, 20)
                    if tipStore.products.isEmpty {
                        ProgressView("Loading tip options…").padding(.vertical, 5).padding(.horizontal, 20)
                    } else {
                        Section(header: Text("Tip the developer").font(.title).bold()) {
                            ForEach(tipStore.products) { product in
                                ProductView(product) {
                                    Label("", systemImage: "heart.fill")
                                        .foregroundStyle(.pink)
                                }
                                .productViewStyle(.compact)
                            }
                        }.padding(.vertical, 5).padding(.horizontal, 20)
                    }
                    if confirmButtonAction != nil {
                        Button() {
                            confirmButtonAction!()
                        } label: {
                            Text("Got it!")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.leading, 20)
                    }
                }.onInAppPurchaseCompletion { product, result in
                    if case .success(.success) = result {
                        showThanks = true
                    }
                }
                .alert("Thank You!", isPresented: $showThanks) {
                    Button("You're welcome") { }
                } message: {
                    Text("Your support means a lot and helps keep the app improving.")
                }
            }
        }
    }
}

