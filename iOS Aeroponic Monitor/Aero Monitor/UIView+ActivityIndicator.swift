//
//  UIView+ActivityIndicator.swift
//  Aero Monitor
//
//  Created by DoodleBytes Development on 6/28/17.
//  Copyright © 2017 DoodleBytes Development. All rights reserved.
//

import UIKit

fileprivate let ActivityIndicatorViewAssociativeKey = "ActivityIndicatorViewAssociativeKey"

public extension UIView {
    var activityIndicatorView: UIActivityIndicatorView {
        get {
            if let activityIndicatorView: UIActivityIndicatorView = objc_getAssociatedObject(self, ActivityIndicatorViewAssociativeKey) as? UIActivityIndicatorView {
                return activityIndicatorView
            } else {
                let activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
                activityIndicatorView.activityIndicatorViewStyle = .whiteLarge
                activityIndicatorView.color = .gray
                activityIndicatorView.center = self.center
                activityIndicatorView.hidesWhenStopped = true
                activityIndicatorView.isHidden = true 
                self.addSubview(activityIndicatorView)
                objc_setAssociatedObject(self, ActivityIndicatorViewAssociativeKey, activityIndicatorView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return activityIndicatorView
            }
        }
    }
}
























