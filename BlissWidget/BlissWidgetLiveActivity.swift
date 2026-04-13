//
//  BlissWidgetLiveActivity.swift
//  BlissWidget
//
//  Created by Bu on 13/4/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BlissWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BlissWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BlissWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension BlissWidgetAttributes {
    fileprivate static var preview: BlissWidgetAttributes {
        BlissWidgetAttributes(name: "World")
    }
}

extension BlissWidgetAttributes.ContentState {
    fileprivate static var smiley: BlissWidgetAttributes.ContentState {
        BlissWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BlissWidgetAttributes.ContentState {
         BlissWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BlissWidgetAttributes.preview) {
   BlissWidgetLiveActivity()
} contentStates: {
    BlissWidgetAttributes.ContentState.smiley
    BlissWidgetAttributes.ContentState.starEyes
}
