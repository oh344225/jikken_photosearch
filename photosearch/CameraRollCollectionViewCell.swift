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
		                     contentMode: .aspectFill,
		                     options: nil,
		                     resultHandler: { [weak self] (image, info) in
								guard let wself = self, let outImage = image else {
									print("photo no dataaaaaaaaaa")
									return
								}
								wself.photoImageView.image = outImage
								//print(outImage)
								
								/*
								var url = assets.localIdentifier as URL
								var ciimage = CIImage(contentsOf: url)!
								var metadata = ciimage.properities["Exif"] as? Dictionary<String, Any>
								*/
							
								//var url = assets.localIdentifier
								
								//空かどうか調べる
								print(outImage)
								
								
								//exif comment読み込み
								let editOptions = PHContentEditingInputRequestOptions()
								editOptions.isNetworkAccessAllowed = true
								
								assets.requestContentEditingInput(with: editOptions, completionHandler: { (contentEditingInput, _) -> Void in
									
									let url = contentEditingInput?.fullSizeImageURL
									let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!)!
									//print(inputImage)
									//self.meta = inputImage.properties["{Exif}"] as? NSDictionary
									
									let meta = inputImage.properties as NSDictionary?
									
									
									
									//print(meta)
									/*
									//ここで、エラーがでてる、nullのエラー
									if((meta!["{Exif}"] as! NSDictionary) == nil){
										wself.pulsetext.text = "no pulse"
										print("no data")
									}
									*/
									
									//let exif:NSDictionary = meta!["{Exif}"] as! NSDictionary
									//print(exif)
									/*
									//print(exif.object(forKey: kCGImagePropertyExifUserComment))
									
									//print(inputImage.properties)
									print(exif.object(forKey: kCGImagePropertyExifUserComment))
									
									//wself.pulsetext.text = exif.object(forKey: kCGImagePropertyExifUserComment) as! String?
									*/
									
								})
								//print(url)
								//print(assets)
								//wself.pulsetext.text = "pulse"
		})
		
		

		
	}
	
		
	
	
}
