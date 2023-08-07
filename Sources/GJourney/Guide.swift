//
//  Guide.swift
//
//
//  Created by Anubhav Singh on 07/08/23.
//

import Foundation
import SwiftUI

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public protocol GuideDelegate {
    func accessoryView(guide: Guide) -> AnyView?
    func overlay(guide: Guide) -> AnyView?
    func cutoutTouchMode(guide: Guide) -> CutoutTouchMode
    func onBackgroundTap(guide: Guide)
    func onCalloutTap(guide: Guide)
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension GuideDelegate {
    public func overlay(guide: Guide) -> AnyView? {
        AnyView(Color(white: 0.8, opacity: 0.5))
    }
    
    public func cutoutTouchMode(guide: Guide) -> CutoutTouchMode {
        .advance
    }
    
    public func onBackgroundTap(guide: Guide) {
        guide.advance()
    }
    
    public func onCalloutTap(guide: Guide) {
        guide.advance()
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
struct DefaultGuideDelegate: GuideDelegate {
    func accessoryView(guide: Guide) -> AnyView? {
        AnyView(Text(""))
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public final class Guide: ObservableObject {
    let statePublisher = GuideStatePublisher()
    public private(set) var current: String? = nil

    private var currentPlan: [String]?
    
    var delegate: GuideDelegate = DefaultGuideDelegate()
    
    public func start<Tags: GuideTags>(tags: Tags.Type, delegate: GuideDelegate?) {
        let plan = tags.allCases.map { $0.key() }
        currentPlan = plan
        self.delegate = delegate ?? DefaultGuideDelegate()
        
        if plan.count > 0 {
            moveTo(item: plan[0])
            current = plan[0]
        }
    }
    
    public func matchCurrent<T: GuideTags>(_ tags: T.Type) -> T? {
        T.allCases.first(where: { $0.key() == current })
    }
    
    public func advance() {
        guard let current = current, let currentPlan = currentPlan else {
            return
        }
        guard let index = currentPlan.firstIndex(of: current) else {
            return
        }
        
        guard index + 1 < currentPlan.count else {
            stop()
            return
        }
        
        moveTo(item: currentPlan[index + 1])
    }
    
    public func jump<T: GuideTags>(to tag: T) {
        guard let currentPlan = currentPlan, let index = currentPlan.firstIndex(of: tag.key()) else {
            return
        }
        moveTo(item: currentPlan[index])
    }

    public func stop(animated: Bool = true) {
        if animated {
            withAnimation {
                stopImpl()
            }
        } else {
            stopImpl()
        }
    }
    
    private func moveTo(item: String) {
        withAnimation {
            if statePublisher.state == .active {
                statePublisher.state = .transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.current = item
                    self.statePublisher.state = .transition
                    DispatchQueue.main.async {
                        withAnimation {
                            self.statePublisher.state = .active
                        }
                    }
                }
            } else {
                current = item
                statePublisher.state = .active
            }
        }
    }
    
    private func stopImpl() {
        statePublisher.state = .hidden
        currentPlan = nil
        current = nil
    }
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
class GuideStatePublisher: ObservableObject {
    enum State {
        case hidden
        case transition
        case active
    }
    
    @Published var state: State = .hidden
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public protocol GuideTags: CaseIterable {
    func makeCallout() -> Callout
}

@available(macOS 10.15, *)
@available(iOS 13.0, *)
extension GuideTags {
    func key() -> String {
        String(reflecting: Self.self) + "." + String(describing: self)
    }
}

