//
//  CoverView.swift
//  
//
//  Created by Anubhav Singh on 07/08/23.
// anubhavssingh177@gmail.com

import Foundation
import SwiftUI

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public struct GuideContainerView<Content: View>: View {
    @StateObject private var guide = Guide()
    
    let content: Content
    
    @State private var popoverSize: CGSize = .zero
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(guide)
            .overlayPreferenceValue(GuideTagPreferenceKey.self, { all in
                GuideOverlay(guide: guide, allRecordedItems: all, popoverSize: popoverSize, guideState: guide.statePublisher)
            })
            .onPreferenceChange(CalloutPreferenceKey.self, perform: { popoverSize = $0 })
    }
}


@available(macOS 10.15, *)
@available(iOS 13.0, *)
private struct GuideOverlay: View {
    let guide: Guide
    let allRecordedItems: GuideTagPreferenceKey.Value
    let popoverSize: CGSize

    @ObservedObject var guideState: GuideStatePublisher
    
    var body: some View {
        ZStack {
            if guideState.state == .transition {
                guide.delegate.overlay(guide: guide)
                    .edgesIgnoringSafeArea(.all)
                if let current = guide.current, let details = allRecordedItems[current] {
                    details.callout.createView(onTap: {}).opacity(0)
                }
            } else if guideState.state == .active {
                if let current = guide.current,  let tagInfo = allRecordedItems[current] {
                    ActiveGuideOverlay(tagInfo: tagInfo, guide: guide, popoverSize: popoverSize)
                }
            }
            if guideState.state != .hidden {
                guide.delegate.accessoryView(guide: guide).environmentObject(guide)
            }
        }
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
private struct ActiveGuideOverlay: View {
    let tagInfo: GuideTagInfo
    let guide: Guide
    let popoverSize: CGSize
    
    var body: some View {
        GeometryReader { proxy in
            cutoutTint(for: proxy[tagInfo.anchor], screenSize: proxy.size)
                .onTapGesture {
                    guide.delegate.onBackgroundTap(guide: guide)
                }

            touchModeView(for: proxy[tagInfo.anchor], mode: guide.delegate.cutoutTouchMode(guide: guide))

            tagInfo.callout.createView(onTap: { guide.delegate.onCalloutTap(guide: guide) })
                .offset(
                    x: cutoutOffsetX(cutout: proxy[tagInfo.anchor]),
                    y: cutoutOffsetY(cutout: proxy[tagInfo.anchor])
                )
        }.edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    private func cutoutTint(for cutoutFrame: CGRect, screenSize: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            if cutoutFrame.minX > 0 {
                guide.delegate.overlay(guide: guide)
                    .frame(width: cutoutFrame.minX, height: screenSize.height)
            }
            if cutoutFrame.maxX < screenSize.width {
                guide.delegate.overlay(guide: guide)
                    .frame(width: screenSize.width - cutoutFrame.maxX, height: screenSize.height)
                    .offset(x: cutoutFrame.maxX)
            }
            if cutoutFrame.minY > 0 {
                guide.delegate.overlay(guide: guide)
                    .frame(width: cutoutFrame.width, height: cutoutFrame.minY)
                    .offset(x: cutoutFrame.minX)
            }
            if cutoutFrame.maxY < screenSize.height {
                guide.delegate.overlay(guide: guide)
                    .frame(width: cutoutFrame.width, height: screenSize.height - cutoutFrame.maxY)
                    .offset(x: cutoutFrame.minX, y: cutoutFrame.maxY)
            }
        }
    }
    
    @ViewBuilder
    private func touchModeView(for cutout: CGRect, mode: CutoutTouchMode) -> some View {
        switch mode {
        case .passthrough: EmptyView()
        case .advance:
            Color.black.opacity(0.05)
                .frame(width: cutout.width, height: cutout.height)
                .offset(x: cutout.minX, y: cutout.minY)
                .onTapGesture {
                    guide.advance()
                }
        case .custom(let action):
            Color.black.opacity(0.05)
                .frame(width: cutout.width, height: cutout.height)
                .offset(x: cutout.minX, y: cutout.minY)
                .onTapGesture {
                    action()
                }
        }
    }
    
    private func cutoutOffsetX(cutout: CGRect) -> CGFloat {
        switch tagInfo.callout.edge {
        case .top, .bottom:
            return cutout.midX - popoverSize.width / 2
        case .leading:
            return cutout.minX - popoverSize.width
        case .trailing:
            return cutout.maxX
        }
    }
    
    private func cutoutOffsetY(cutout: CGRect) -> CGFloat {
        switch tagInfo.callout.edge {
        case .leading, .trailing:
            return cutout.midY - popoverSize.height / 2
        case .top:
            return cutout.minY - popoverSize.height
        case .bottom:
            return cutout.maxY
        }
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public struct GuidableView<Content: View, Tags: GuideTags>: View {
    let isActive: Bool
    let delegate: GuideDelegate?
    let startDelay: TimeInterval
    let content: Content

    @EnvironmentObject private var guide: Guide
    
    init(isActive: Bool, tags: Tags.Type, delegate: GuideDelegate?, startDelay: TimeInterval = 0.5, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.delegate = delegate
        self.startDelay = startDelay
        self.content = content()
    }
    
    @available(macOS 10.15, *)
    @available(iOS 13.0, *)
    public var body: some View {
            if #available(macOS 11.0, *) {
                content
                    .onAppear {
                        if isActive {
                            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                                guide.start(tags: Tags.self, delegate: delegate)
                            }
                        }
                    }
                    .onDisappear {
                        guide.stop()
                    }
                    .onChange(of: isActive) { active in
                        if active {
                            guide.start(tags: Tags.self, delegate: delegate)
                        }
                    }
            } else {
                // Fallback on earlier versions
            }
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
struct GuideTagInfo {
    let anchor: Anchor<CGRect>
    let callout: Callout
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
struct GuideTagPreferenceKey: PreferenceKey {
    typealias Value = [String: GuideTagInfo]
    
    static var defaultValue: Value = [:]
    
    static func reduce(value acc: inout Value, nextValue: () -> Value) {
        let newValue = nextValue()
        for (key, value) in newValue {
            acc[key] = value
        }
    }
}
