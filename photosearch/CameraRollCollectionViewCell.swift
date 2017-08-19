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
	
	@IBOutlet weak var pulsetext: UILabel!
	
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	// 画像を表示する
	func setConfigure(assets: PHAsset) {
		let manager = PHImageManager()
		
		manager.requestImage(for: assets,
		                     targetSize: frame.size,
		                     contentMode: .aspectFit,
		                     options: nil,
		                     resultHandler: { [weak self] (image, info) in
								guard let wself = self, let outImage = image else {
									//print("photo no dataaaaaaaaaa")
									return
								}
								wself.photoImageView.image = outImage
								//print(assets)
								//print(outImage)
								
		})
		//exif読み込み
		let editOptions = PHContentEditingInputRequestOptions()
		editOptions.isNetworkAccessAllowed = true
		
		assets.requestContentEditingInput(with: editOptions, completionHandler: { (contentEditingInput, _) -> Void in
			let url = contentEditingInput?.fullSizeImageURL
			let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!)!
			
			//self.meta = inputImage.properties["{Exif}"] as? NSDictionary
			let meta = inputImage.properties as NSDictionary?
			//print("exif:\(meta!["{Exif}"] as! NSDictionary)")
				//let exif:NSDictionary? = meta!["{Exif}"] as! NSDictionary
				//print(exif)
			
		})
		//ここまでその処理　exifでエラーが出る。
		

		
	}
	
	//未完成　つかっていない
	// 画像を再表示する
	func resetphoto(assets: PHAsset) {
		let manager = PHImageManager()
		
		manager.requestImage(for: assets,
		                     targetSize: frame.size,
		                     contentMode: .aspectFit,
		                     options: nil,
		                     resultHandler: { [weak self] (image, info) in
								guard let wself = self, let outImage = image else {
									//print("photo no dataaaaaaaaaa")
									return
								}
								wself.photoImageView.image = outImage
								print(outImage)
								
								//exif読み込み
								let editOptions = PHContentEditingInputRequestOptions()
								editOptions.isNetworkAccessAllowed = true
								
								assets.requestContentEditingInput(with: editOptions, completionHandler: { (contentEditingInput, _) -> Void in
									let url = contentEditingInput?.fullSizeImageURL
									let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!)!
									
									//self.meta = inputImage.properties["{Exif}"] as? NSDictionary
									let meta = inputImage.properties as NSDictionary?
									
									let exif:NSDictionary = meta!["{Exif}"] as! NSDictionary
									
									print(inputImage.properties)
								})
								//ここまでその処理　exifでエラーが出る。
		})
	}

		
	
	
}
