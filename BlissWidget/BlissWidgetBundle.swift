//
//  BlissWidgetBundle.swift
//  BlissWidget
//
//  Created by Bu on 13/4/26.
//

import WidgetKit
import SwiftUI

@main
struct BlissWidgetBundle: WidgetBundle {
    var body: some Widget {
        BlissWidget()
        BlissWidgetControl()
        BlissWidgetLiveActivity()
    }
}
