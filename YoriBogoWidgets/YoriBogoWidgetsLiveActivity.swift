//
//  YoriBogoWidgetsLiveActivity.swift
//  YoriBogoWidgets
//
//  Created by 박성훈 on 1/28/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct YoriBogoWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct YoriBogoWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: YoriBogoWidgetsAttributes.self) { context in
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

extension YoriBogoWidgetsAttributes {
    fileprivate static var preview: YoriBogoWidgetsAttributes {
        YoriBogoWidgetsAttributes(name: "World")
    }
}

extension YoriBogoWidgetsAttributes.ContentState {
    fileprivate static var smiley: YoriBogoWidgetsAttributes.ContentState {
        YoriBogoWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: YoriBogoWidgetsAttributes.ContentState {
         YoriBogoWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: YoriBogoWidgetsAttributes.preview) {
   YoriBogoWidgetsLiveActivity()
} contentStates: {
    YoriBogoWidgetsAttributes.ContentState.smiley
    YoriBogoWidgetsAttributes.ContentState.starEyes
}
