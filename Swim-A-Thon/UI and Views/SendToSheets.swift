//
//  SendToSheets.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 5/16/26.
//

import Foundation
import SwiftUI
import GSheetsSwift
import GSheetsSwiftAPI
import GSheetsSwiftTypes
import GoogleSignIn
import GoogleSignInSwift
import SwiftData

struct SendToSheets: View {
    @Environment(\.isSignedIn) private var isSignedIn: Binding<Bool>
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Swimmer.createdAt, order: .forward) private var swimmers: [Swimmer]
    
    @StateObject private var sheets = SheetsInterface()
    
    @State private var sheetURL: String = "https://docs.google.com/spreadsheets/d/1b5MSzYg6pZg1S8oGwya08jH5eCX8NhvunPMIIBdCDGw/edit?usp=sharing"
    @State private var statusMessage: String = ""
    @State private var isLoading: Bool = false
    
    @State private var swimmerNamesArray: [String] = []
    @State private var swimmerLapsArray: [Int] = []

    var body: some View {
        VStack(spacing: 16) {
            
            if !isSignedIn.wrappedValue {
                Spacer()
                GoogleSignInButton(action: handleSignInButton)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Cancel Sign In")
                }

            } else {
                HStack {
                    Button("Load") {
                        Task { await loadSheet() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sheetURL.isEmpty || isLoading)
                }
            
                Button("Send Data") {
                    Task {
                        if sheets.targetSheet == nil {
                            await loadSheet()
                        }
                        for swimmer in swimmers {
                            addSwimmerNameArray(swimmer.name, to: &swimmerNamesArray)
                            addSwimmerLapsArray(swimmer.laps, to: &swimmerLapsArray)
                        }
                        insertSwimmerArrayData(stringValues: swimmerNamesArray, numberValues: swimmerLapsArray)
                    }
                }
                .buttonStyle(.bordered)
                
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button("Sign Out") {
                    GIDSignIn.sharedInstance.signOut()
                    isSignedIn.wrappedValue = false
                }
                .buttonStyle(.borderedProminent)
            }
            
        }
        .animation(.snappy, value: isSignedIn.wrappedValue)
        .padding()
        .task(id: isSignedIn.wrappedValue) {
            if isSignedIn.wrappedValue, sheets.targetSheet == nil {
                await loadSheet()
            }
        }
        .navigationTitle("Send To Sheets")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
    
    func handleSignInButton() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let topVC = windowScene.keyWindow?.rootViewController else {
            statusMessage = "Unable to present Google Sign-In."
            return
        }

        let scopes = ["https://www.googleapis.com/auth/spreadsheets"]
        statusMessage = "Starting Google Sign-In…"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            GIDSignIn.sharedInstance.signIn(withPresenting: topVC, hint: nil, additionalScopes: scopes) { signInResult, error in
                DispatchQueue.main.async {
                    guard let result = signInResult else {
                        statusMessage = "Sign-in failed: \(error?.localizedDescription ?? "Unknown error")"
                        isSignedIn.wrappedValue = false
                        return
                    }

                    isSignedIn.wrappedValue = true
                    SheetsInterface.accessToken = result.user.accessToken.tokenString
                    APISecretManager.accessToken = result.user.accessToken.tokenString
                    statusMessage = "Signed in successfully."
                }
            }
        }
    }
    
    func addSwimmerNameArray(_ value: String, to array: inout [String]) {
        array.append(value)
    }

    func addSwimmerLapsArray(_ value: Int, to array: inout [Int]) {
        array.append(value)
    }

    private func loadSheet() async {
        guard let id = extractSheetID(from: sheetURL) else {
            statusMessage = "Could not parse a sheet ID from that URL."
            return
        }

        isLoading = true
        statusMessage = "Loading…"
        defer { isLoading = false }

        do {
            try await sheets.loadSpreadsheet(id: id)
            let names = sheets.namesOfSheets()
            guard let first = names.first else {
                statusMessage = "Spreadsheet has no sheets."
                return
            }
            sheets.focusSheet(name: first)
            statusMessage = "Loaded. Focused sheet: \(first)"
        } catch {
            statusMessage = "Load failed: \(error.localizedDescription)"
        }
    }
    
    func insertSwimmerArrayData(stringValues:[String],numberValues:[Int]) {
        guard let targetSheet = sheets.targetSheet else { return }


        let rows: [RowData] = zip(stringValues, numberValues).map { string, number in
            RowData(values: [
                CellData(userEnteredValue: ExtendedValue(stringValue: string)),
                CellData(userEnteredValue: ExtendedValue(numberValue: Double(number)))
            ])
        }

        let updateCells = UpdateCellsRequest(
            rows: rows,
            fields: "*",
            start: GridCoordinate(
                sheetId: targetSheet.properties.sheetId,
                rowIndex: 0,
                columnIndex: 0
            )
        )

        statusMessage = "Inserting data…"
        sheets.update(requests: [UpdateRequest(updateCells: updateCells)]) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    statusMessage = "Inserted \(rows.count) rows into A1:B\(rows.count)."
                case .failure(let error):
                    statusMessage = "Insert failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func insertSwimmerData(name: String, laps: Int) {
        guard let targetSheet = sheets.targetSheet else {
            statusMessage = "Sheet not ready."
            return
        }

        let stringValue = name
        let numberValue: Double = Double(laps)

        let rows: [RowData] = [
            RowData(values: [
                CellData(userEnteredValue: ExtendedValue(stringValue: stringValue)),
                CellData(userEnteredValue: ExtendedValue(numberValue: numberValue))
            ])
        ]

        let updateCells = UpdateCellsRequest(
            rows: rows,
            fields: "*",
            start: GridCoordinate(
                sheetId: targetSheet.properties.sheetId,
                rowIndex: 0,
                columnIndex: 0
            )
        )

        statusMessage = "Inserting data…"
        sheets.update(requests: [UpdateRequest(updateCells: updateCells)]) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    statusMessage = "Inserted name and laps into A1:B1."
                case .failure(let error):
                    statusMessage = "Insert failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func extractSheetID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = trimmed.range(of: "/d/") else { return nil }
        let afterPrefix = trimmed[range.upperBound...]
        let id = afterPrefix.split(separator: "/").first.map(String.init)
        return id?.isEmpty == false ? id : nil
    }
}

#Preview {
    SendToSheets()
}
