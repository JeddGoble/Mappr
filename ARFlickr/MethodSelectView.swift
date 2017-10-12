//
//  MethodSelectView.swift
//  ARFlickr
//
//  Created by jgoble52 on 10/12/17.
//  Copyright © 2017 Jedd Goble. All rights reserved.
//

import UIKit

protocol MethodSelectDelegate {
    func tappedMethodButton(method: FilterMethod)
}

class MethodSelectView: UIView {

    var delegate: MethodSelectDelegate?
    
    static var nibName: String {
        return String(describing: MethodSelectView.self)
    }
    
    @IBAction func onDateTakenButtonTapped(_ sender: UIButton) {
        delegate?.tappedMethodButton(method: .dateTaken)
    }
    
    @IBAction func onRelevanceButtonTapped(_ sender: UIButton) {
        delegate?.tappedMethodButton(method: .relevance)
    }
    
    @IBAction func onInterestingnessButtonTapped(_ sender: UIButton) {
        delegate?.tappedMethodButton(method: .interestingness)
    }
    
    
}
