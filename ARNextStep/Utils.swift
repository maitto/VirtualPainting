//
//  Utils.swift
//  ARNextStep
//
//  Created by Mortti Aittokoski on 23/09/2018.
//  Copyright © 2018 Mortti Aittokoski. All rights reserved.
//

import SceneKit

class Utils {
    static func distanceFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> Float {
        let x0 = vector1.x
        let x1 = vector2.x
        let y0 = vector1.y
        let y1 = vector2.y
        let z0 = vector1.z
        let z1 = vector2.z
        
        return sqrtf(powf(x1-x0, 2) + powf(y1-y0, 2) + powf(z1-z0, 2))
    }
}
