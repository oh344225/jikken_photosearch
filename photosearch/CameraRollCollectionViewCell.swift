//
//  CameraRollCollectionViewCell.swift
//  photosearch
//
//  Created by oshitahayato on 2017/07/03.
//  Copyright © 2017年 oshitahayato. All rights reserved.
//

import UIKit
import Photos

class CameraRollCollectionViewCell: UICollectionViewCell {
	
	@IBOutlet weak var photoImageView: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	// 画像を表示する
	func setConfigure(assets: PHAsset) {
		let manager = PHImageManager()
		
		manager.requestImage(for: assets,
		                     targetSize: frame.size,
		                     contentMode: .aspectFill,
		                     options: nil,
		                     resultHandler: { [weak self] (image, info) in
								guard let wself = self, let outImage = image else {
									return
								}
								wself.photoImageView.image = image
		})
	}
	
	
	
}
