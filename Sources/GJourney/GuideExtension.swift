//
//  File.swift
//  
//
//  Created by Anubhav Singh on 07/08/23.
//

import Foundation
import SwiftUI

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension View {
    public func guide<Tags: GuideTags>(isActive: Bool, tags: Tags.Type, delegate: GuideDelegate? = nil) -> some View {
        GuidableView(isActive: isActive, tags: tags, delegate: delegate) {
            self
        }
    }

    public func guideTag<T: GuideTags>(_ tag: T) -> some View {
        anchorPreference(key: GuideTagPreferenceKey.self, value: .bounds, transform: { anchor in
            return [tag.key(): GuideTagInfo(anchor: anchor, callout: tag.makeCallout())]
        })
    }
    
    public func guideExtensionTag<T: GuideTags>(_ tag: T, edge: Edge, size: CGFloat = 100) -> some View {
        let width: CGFloat? = (edge == .leading || edge == .trailing) ? size : nil
        let height: CGFloat? = (edge == .top || edge == .bottom) ? size : nil
        
        let alignment: Alignment
        switch edge {
        case .top: alignment = .top
        case .leading: alignment = .leading
        case .trailing: alignment = .trailing
        case .bottom: alignment = .bottom
        }
        
        let overlayView = Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: width, height: height)
            .guideTag(tag)
            .padding(Edge.Set(edge), -size)
        return overlay(overlayView, alignment: alignment)
    }
    
    @available(macOS 11.0, *)
    public func stopGuide(_ guide: Guide, onLink navigationLink: Bool) -> some View {
        onChange(of: navigationLink, perform: { shown in
            if shown {
                guide.stop()
            }
        })
    }
    
    @available(macOS 11.0, *)
    public func stopGuide<V: Hashable>(_ guide: Guide, onTag navigationTag: V, selection: V) -> some View {
        onChange(of: selection, perform: { value in
            if navigationTag == value {
                guide.stop()
            }
        })
    }
}
