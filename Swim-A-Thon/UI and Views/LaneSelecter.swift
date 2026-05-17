//
//  LaneSelecter.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 5/17/26.
//

import SwiftUI

struct LaneSelecter: View {
    
    @AppStorage("selectedLane") var selectedLane: Int = 0
    
    var body: some View {
        HStack {
            Spacer()
            Text("Lane Number").padding().bold().font(.title)
            Spacer()
            Button {
                selectedLane -= 1
            } label: {
                Text("-")
            }.disabled(selectedLane == 1 || selectedLane == 0)
            
            Text(String(selectedLane)).bold().font(.title).padding()
            Spacer()
            
            Button {
                selectedLane += 1
            } label: {
                Text("+")
            }.disabled(selectedLane == 13)
            Spacer()
        }
    }
}

#Preview {
    LaneSelecter()
}
