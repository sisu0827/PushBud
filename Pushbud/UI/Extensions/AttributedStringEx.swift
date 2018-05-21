//
//  AttributedStringEx.swift
//  Pushbud
//
//  Created by Daria.R on 08/15/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import Foundation

extension NSAttributedString {

    func height(considering width: CGFloat) -> CGFloat {
        let constraintBox = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = self.boundingRect(with: constraintBox, options: .usesLineFragmentOrigin, context: nil)
        return rect.height
    }

}
